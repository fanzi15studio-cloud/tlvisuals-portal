import Foundation
import Network

struct HTTPRequest {
    let method: String
    let path: String
    let query: [String: String]
    let headers: [String: String]
    let body: Data

    var bodyJSON: Any? {
        guard !body.isEmpty else { return nil }
        return try? JSONSerialization.jsonObject(with: body)
    }
}

/// Une connexion cliente : soit des requêtes HTTP classiques (keep-alive),
/// soit un flux MJPEG maintenu ouvert jusqu'à la déconnexion.
final class ClientConnection {
    static let boundary = "teslaframe"

    private let connection: NWConnection
    private let queue: DispatchQueue
    private let router: (HTTPRequest, ClientConnection) -> Void

    private let stateLock = NSLock()
    private var buffer = Data()
    private var isStreaming = false
    private var isClosed = false
    private var sendInFlight = false
    private var closeHandlers: [() -> Void] = []

    let remoteDescription: String

    init(connection: NWConnection, router: @escaping (HTTPRequest, ClientConnection) -> Void) {
        self.connection = connection
        self.router = router
        self.queue = DispatchQueue(label: "com.tlv.tesla-display.conn.\(UUID().uuidString)")
        if case let .hostPort(host, _) = connection.endpoint {
            self.remoteDescription = "\(host)"
        } else {
            self.remoteDescription = "client"
        }
    }

    /// Appelé à la fermeture, quelle qu'en soit la cause. Si la connexion est déjà
    /// fermée, le handler est exécuté immédiatement : sinon un abonnement pris juste
    /// avant une déconnexion resterait orphelin.
    func onDisconnect(_ handler: @escaping () -> Void) {
        stateLock.lock()
        let alreadyClosed = isClosed
        if !alreadyClosed { closeHandlers.append(handler) }
        stateLock.unlock()
        if alreadyClosed { handler() }
    }

    func start() {
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .failed, .cancelled:
                self?.close()
            default:
                break
            }
        }
        connection.start(queue: queue)
        receive()
    }

    private func receive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 32 * 1024) { [weak self] data, _, isComplete, error in
            guard let self else { return }

            if let data, !data.isEmpty {
                self.stateLock.lock()
                let streaming = self.isStreaming
                if !streaming { self.buffer.append(data) }
                self.stateLock.unlock()
                if !streaming { self.processBuffer() }
            }

            if isComplete || error != nil {
                self.close()
                return
            }

            self.stateLock.lock()
            let closed = self.isClosed
            self.stateLock.unlock()
            if !closed { self.receive() }
        }
    }

    private func processBuffer() {
        while true {
            stateLock.lock()
            let snapshot = buffer
            stateLock.unlock()

            guard let headerRange = snapshot.range(of: Data("\r\n\r\n".utf8)) else { return }
            guard let headerText = String(data: snapshot.subdata(in: 0..<headerRange.lowerBound), encoding: .utf8) else {
                close()
                return
            }

            var lines = headerText.components(separatedBy: "\r\n")
            guard let requestLine = lines.first else { close(); return }
            lines.removeFirst()

            let parts = requestLine.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 2 else { close(); return }

            var headers: [String: String] = [:]
            for line in lines {
                guard let separator = line.firstIndex(of: ":") else { continue }
                let name = String(line[line.startIndex..<separator]).trimmingCharacters(in: .whitespaces).lowercased()
                let value = String(line[line.index(after: separator)...]).trimmingCharacters(in: .whitespaces)
                headers[name] = value
            }

            let contentLength = Int(headers["content-length"] ?? "") ?? 0
            let bodyStart = headerRange.upperBound
            guard snapshot.count - bodyStart >= contentLength else { return } // Corps incomplet : on attend.

            let body = contentLength > 0 ? snapshot.subdata(in: bodyStart..<(bodyStart + contentLength)) : Data()
            let consumed = bodyStart + contentLength

            stateLock.lock()
            if buffer.count >= consumed {
                buffer.removeSubrange(0..<consumed)
            } else {
                buffer.removeAll()
            }
            stateLock.unlock()

            let target = String(parts[1])
            let (path, query) = ClientConnection.split(target: target)
            let request = HTTPRequest(
                method: String(parts[0]).uppercased(),
                path: path,
                query: query,
                headers: headers,
                body: body
            )

            router(request, self)

            stateLock.lock()
            let streaming = isStreaming
            if streaming { buffer.removeAll() }
            stateLock.unlock()
            if streaming { return }
        }
    }

    private static func split(target: String) -> (String, [String: String]) {
        guard let markIndex = target.firstIndex(of: "?") else {
            return (target.removingPercentEncoding ?? target, [:])
        }
        let path = String(target[target.startIndex..<markIndex])
        let queryString = String(target[target.index(after: markIndex)...])

        var query: [String: String] = [:]
        for pair in queryString.split(separator: "&") {
            let kv = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard let rawKey = kv.first else { continue }
            let key = String(rawKey).removingPercentEncoding ?? String(rawKey)
            let value = kv.count > 1 ? (String(kv[1]).removingPercentEncoding ?? String(kv[1])) : ""
            query[key] = value
        }
        return (path.removingPercentEncoding ?? path, query)
    }

    // MARK: - Réponses

    func respond(
        status: Int = 200,
        reason: String = "OK",
        contentType: String = "text/plain; charset=utf-8",
        body: Data = Data(),
        extraHeaders: [String: String] = [:]
    ) {
        var head = "HTTP/1.1 \(status) \(reason)\r\n"
        head += "Content-Type: \(contentType)\r\n"
        head += "Content-Length: \(body.count)\r\n"
        head += "Cache-Control: no-store\r\n"
        head += "Connection: keep-alive\r\n"
        for (name, value) in extraHeaders {
            head += "\(name): \(value)\r\n"
        }
        head += "\r\n"

        var payload = Data(head.utf8)
        payload.append(body)
        connection.send(content: payload, completion: .contentProcessed { [weak self] error in
            if error != nil { self?.close() }
        })
    }

    func respond(status: Int = 200, reason: String = "OK", text: String) {
        respond(status: status, reason: reason, contentType: "text/plain; charset=utf-8", body: Data(text.utf8))
    }

    func respondJSON(_ object: Any, status: Int = 200) {
        let data = (try? JSONSerialization.data(withJSONObject: object)) ?? Data("{}".utf8)
        respond(status: status, reason: status == 200 ? "OK" : "Error", contentType: "application/json", body: data)
    }

    func respondHTML(_ html: String) {
        respond(contentType: "text/html; charset=utf-8", body: Data(html.utf8))
    }

    // MARK: - Flux MJPEG

    func beginMJPEG() {
        stateLock.lock()
        isStreaming = true
        stateLock.unlock()

        var head = "HTTP/1.1 200 OK\r\n"
        head += "Content-Type: multipart/x-mixed-replace; boundary=\(ClientConnection.boundary)\r\n"
        head += "Cache-Control: no-store, no-cache, must-revalidate, max-age=0\r\n"
        head += "Pragma: no-cache\r\n"
        head += "Connection: close\r\n"
        head += "\r\n"

        connection.send(content: Data(head.utf8), completion: .contentProcessed { [weak self] error in
            if error != nil { self?.close() }
        })
    }

    /// Envoie une image. Si l'envoi précédent n'est pas terminé (lien Wi-Fi saturé),
    /// l'image est abandonnée : on privilégie la fraîcheur à l'exhaustivité.
    func sendFrame(_ jpeg: Data) {
        stateLock.lock()
        guard !isClosed, isStreaming, !sendInFlight else {
            stateLock.unlock()
            return
        }
        sendInFlight = true
        stateLock.unlock()

        var payload = Data("--\(ClientConnection.boundary)\r\nContent-Type: image/jpeg\r\nContent-Length: \(jpeg.count)\r\n\r\n".utf8)
        payload.append(jpeg)
        payload.append(Data("\r\n".utf8))

        connection.send(content: payload, completion: .contentProcessed { [weak self] error in
            guard let self else { return }
            self.stateLock.lock()
            self.sendInFlight = false
            self.stateLock.unlock()
            if error != nil { self.close() }
        })
    }

    func close() {
        stateLock.lock()
        if isClosed {
            stateLock.unlock()
            return
        }
        isClosed = true
        let handlers = closeHandlers
        closeHandlers = []
        stateLock.unlock()

        connection.cancel()
        for handler in handlers { handler() }
    }
}

final class HTTPServer {
    private let port: NWEndpoint.Port
    private let router: (HTTPRequest, ClientConnection) -> Void
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.tlv.tesla-display.listener")

    // Les connexions vivent tant qu'elles sont ouvertes : rien d'autre ne les retient,
    // et un flux MJPEG doit survivre bien après le retour du handler d'acceptation.
    private let registryLock = NSLock()
    private var connections: [ObjectIdentifier: ClientConnection] = [:]

    init(port: UInt16, router: @escaping (HTTPRequest, ClientConnection) -> Void) throws {
        guard let resolved = NWEndpoint.Port(rawValue: port) else {
            throw ServerError.invalidPort(port)
        }
        self.port = resolved
        self.router = router
    }

    func start() throws {
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        if let tcp = parameters.defaultProtocolStack.transportProtocol as? NWProtocolTCP.Options {
            tcp.noDelay = true
            tcp.connectionTimeout = 10
        }

        let listener = try NWListener(using: parameters, on: port)
        listener.newConnectionHandler = { [weak self] connection in
            guard let self else {
                connection.cancel()
                return
            }
            let client = ClientConnection(connection: connection, router: self.router)
            let key = ObjectIdentifier(client)

            self.registryLock.lock()
            self.connections[key] = client
            self.registryLock.unlock()

            client.onDisconnect { [weak self] in
                guard let self else { return }
                self.registryLock.lock()
                self.connections.removeValue(forKey: key)
                self.registryLock.unlock()
            }
            client.start()
        }
        listener.stateUpdateHandler = { state in
            if case let .failed(error) = state {
                FileHandle.standardError.write(Data("❌ Le serveur a échoué : \(error)\n".utf8))
                exit(1)
            }
        }
        listener.start(queue: queue)
        self.listener = listener
    }

    enum ServerError: LocalizedError {
        case invalidPort(UInt16)

        var errorDescription: String? {
            switch self {
            case let .invalidPort(port): return "Port invalide : \(port)"
            }
        }
    }
}

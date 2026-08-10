import CoreGraphics
import Foundation
import ScreenCaptureKit

@main
struct TeslaDisplayApp {
    static func main() async {
        do {
            try await run()
        } catch {
            FileHandle.standardError.write(Data("\n❌ \(error.localizedDescription)\n".utf8))
            exit(1)
        }
    }

    // MARK: - Options

    struct Options {
        var port: UInt16 = 8765
        var displaySelector: String?
        var settings = StreamSettings.normal
        var token = ""
        var inputEnabled = true
        var listOnly = false
    }

    static func parseOptions() -> Options {
        var options = Options()
        var arguments = Array(CommandLine.arguments.dropFirst())

        func nextValue(_ flag: String) -> String? {
            guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
            let value = arguments[index + 1]
            arguments.removeSubrange(index...(index + 1))
            return value
        }

        if arguments.contains("--help") || arguments.contains("-h") {
            print(usage)
            exit(0)
        }

        if let preset = nextValue("--preset") {
            switch preset.lowercased() {
            case "eco": options.settings = .eco
            case "normal": options.settings = .normal
            case "sharp", "net": options.settings = .sharp
            case "max": options.settings = .max
            default: break
            }
        }
        if let value = nextValue("--port"), let port = UInt16(value) { options.port = port }
        if let value = nextValue("--width"), let width = Int(value) { options.settings.width = width }
        if let value = nextValue("--fps"), let fps = Int(value) { options.settings.fps = fps }
        if let value = nextValue("--quality"), let quality = Double(value) { options.settings.quality = quality }
        if let value = nextValue("--token") { options.token = value }
        if let value = nextValue("--display") { options.displaySelector = value }

        options.inputEnabled = !arguments.contains("--no-input")
        options.listOnly = arguments.contains("--list")
        options.settings = options.settings.clamped()

        return options
    }

    static let usage = """
    tesla-display — diffuse un écran du Mac vers le navigateur d'une Tesla.

    Usage : tesla-display [options]

      --list              Liste les écrans détectés puis quitte
      --display <n|id>    Écran à diffuser (index de --list, identifiant, ou "main")
      --port <n>          Port d'écoute (défaut : 8765)
      --preset <nom>      eco | normal | sharp | max (défaut : normal)
      --width <px>        Largeur d'encodage (défaut : 1280)
      --fps <n>           Images par seconde (défaut : 15)
      --quality <0.1-1>   Qualité JPEG (défaut : 0.55)
      --token <secret>    Exige ?t=<secret> pour accéder au flux
      --no-input          Diffusion en lecture seule (pas de contrôle souris/clavier)
      -h, --help          Affiche cette aide

    La qualité se règle aussi en direct depuis l'écran de la Tesla (bouton ☰).
    """

    // MARK: - Programme

    static func run() async throws {
        let options = parseOptions()

        let displays: [SCDisplay]
        do {
            displays = try await ScreenStreamer.availableDisplays()
        } catch {
            throw AppError.screenRecordingDenied(underlying: error)
        }

        guard !displays.isEmpty else { throw AppError.noDisplays }

        if options.listOnly {
            printDisplays(displays)
            exit(0)
        }

        let display = try select(from: displays, selector: options.displaySelector)
        // NSScreen n'est sûr que depuis le thread principal : on résout le nom une fois pour toutes.
        let displayName = ScreenStreamer.name(for: display.displayID)

        let broadcaster = FrameBroadcaster()
        let streamer = ScreenStreamer(broadcaster: broadcaster, settings: options.settings)
        let injector = InputInjector(displayID: display.displayID)
        let inputQueue = DispatchQueue(label: "com.tlv.tesla-display.input")

        if options.inputEnabled, !InputInjector.hasAccessibilityPermission(prompting: true) {
            print("""

            ⚠️  Autorisation « Accessibilité » manquante.
               Le flux vidéo fonctionnera, mais le tactile de la Tesla ne pilotera pas le Mac.
               Réglages système ▸ Confidentialité et sécurité ▸ Accessibilité :
               cochez l'application depuis laquelle vous lancez cette commande (Terminal, iTerm…),
               puis relancez tesla-display.
            """)
        }

        let server = try HTTPServer(port: options.port) { request, client in
            handle(
                request: request,
                client: client,
                options: options,
                display: display,
                displayName: displayName,
                broadcaster: broadcaster,
                streamer: streamer,
                injector: injector,
                inputQueue: inputQueue
            )
        }

        try await streamer.start(display: display)
        try server.start()

        printBanner(display: display, displayName: displayName, options: options, streamer: streamer)

        // Le serveur vit sur ses propres files : on maintient simplement le processus.
        while true {
            try await Task.sleep(nanoseconds: 60 * 1_000_000_000)
        }
    }

    // MARK: - Routage HTTP

    private static func handle(
        request: HTTPRequest,
        client: ClientConnection,
        options: Options,
        display: SCDisplay,
        displayName: String,
        broadcaster: FrameBroadcaster,
        streamer: ScreenStreamer,
        injector: InputInjector,
        inputQueue: DispatchQueue
    ) {
        func authorized() -> Bool {
            guard !options.token.isEmpty else { return true }
            if request.query["t"] == options.token { return true }
            if request.headers["x-token"] == options.token { return true }
            return false
        }

        guard authorized() else {
            client.respond(status: 401, reason: "Unauthorized", text: "Jeton manquant ou invalide.")
            return
        }

        switch (request.method, request.path) {
        case ("GET", "/"), ("GET", "/index.html"):
            client.respondHTML(ClientHTML.page(token: options.token))

        case ("GET", "/stream"):
            client.beginMJPEG()
            let subscription = broadcaster.subscribe { [weak client] frame in
                client?.sendFrame(frame)
            }
            client.onDisconnect { broadcaster.unsubscribe(subscription) }
            if let frame = broadcaster.latestFrame {
                client.sendFrame(frame)
            }

        case ("GET", "/info"):
            let settings = streamer.currentSettings
            let displayInfo: [String: Any] = [
                "id": Int(display.displayID),
                "name": displayName,
                "width": display.width,
                "height": display.height
            ]
            let encodingInfo: [String: Any] = [
                "width": streamer.outputWidth,
                "height": streamer.outputHeight,
                "fps": settings.fps,
                "quality": settings.quality
            ]
            let info: [String: Any] = [
                "display": displayInfo,
                "encoding": encodingInfo,
                "input": options.inputEnabled,
                "viewers": broadcaster.subscriberCount
            ]
            client.respondJSON(info)

        case ("POST", "/config"):
            guard let payload = request.bodyJSON as? [String: Any] else {
                client.respondJSON(["error": "corps JSON invalide"], status: 400)
                return
            }

            var settings = streamer.currentSettings
            if let preset = payload["preset"] as? String {
                switch preset.lowercased() {
                case "eco": settings = .eco
                case "normal": settings = .normal
                case "sharp", "net": settings = .sharp
                case "max": settings = .max
                default: break
                }
            }
            if let width = payload["width"] as? Int { settings.width = width }
            if let fps = payload["fps"] as? Int { settings.fps = fps }
            if let quality = payload["quality"] as? Double { settings.quality = quality }

            let applied = settings.clamped()
            Task { await streamer.apply(settings: applied) }
            let echo: [String: Any] = ["width": applied.width, "fps": applied.fps, "quality": applied.quality]
            client.respondJSON(echo)

        case ("POST", "/input"):
            guard options.inputEnabled else {
                client.respondJSON(["error": "contrôle désactivé (--no-input)"], status: 403)
                return
            }
            guard let payload = request.bodyJSON as? [String: Any],
                  let events = payload["events"] as? [[String: Any]] else {
                client.respondJSON(["error": "corps JSON invalide"], status: 400)
                return
            }
            inputQueue.async {
                for event in events {
                    injector.handle(event)
                }
            }
            client.respondJSON(["ok": true])

        case ("GET", "/health"):
            client.respond(text: "ok")

        case ("GET", "/favicon.ico"):
            client.respond(status: 204, reason: "No Content", body: Data())

        default:
            client.respond(status: 404, reason: "Not Found", text: "Introuvable")
        }
    }

    // MARK: - Sélection de l'écran

    private static func select(from displays: [SCDisplay], selector: String?) throws -> SCDisplay {
        if let selector {
            if selector.lowercased() == "main" {
                if let main = displays.first(where: { $0.displayID == CGMainDisplayID() }) { return main }
            }
            if let index = Int(selector), index >= 1, index <= displays.count {
                return displays[index - 1]
            }
            if let id = UInt32(selector), let match = displays.first(where: { $0.displayID == id }) {
                return match
            }
            throw AppError.unknownDisplay(selector)
        }

        // Sans indication, un écran virtuel est presque toujours un écran secondaire.
        let secondary = displays.filter { $0.displayID != CGMainDisplayID() }
        let named = secondary.first { display in
            let name = ScreenStreamer.name(for: display.displayID).lowercased()
            return name.contains("virtual") || name.contains("dummy") || name.contains("better")
        }
        if let named { return named }
        if let first = secondary.first { return first }

        print("""

        ⚠️  Un seul écran détecté : c'est l'écran principal du Mac qui sera diffusé
           (recopie, pas d'extension du bureau). Pour un vrai second écran, créez d'abord
           un écran virtuel — voir tools/tesla-display/README.md.
        """)
        return displays[0]
    }

    // MARK: - Affichage console

    private static func printDisplays(_ displays: [SCDisplay]) {
        print("\nÉcrans détectés :\n")
        for (index, display) in displays.enumerated() {
            let isMain = display.displayID == CGMainDisplayID()
            let name = ScreenStreamer.name(for: display.displayID)
            print("  [\(index + 1)] \(name) — \(display.width)×\(display.height) — id \(display.displayID)\(isMain ? " (principal)" : "")")
        }
        print("\nDiffuser le second : tesla-display --display 2\n")
    }

    private static func printBanner(display: SCDisplay, displayName: String, options: Options, streamer: ScreenStreamer) {
        let settings = streamer.currentSettings
        let suffix = options.token.isEmpty ? "" : "/?t=\(options.token)"

        print("""

        ┌──────────────────────────────────────────────────────────────┐
        │  tesla-display — écran Mac déporté vers la Tesla             │
        └──────────────────────────────────────────────────────────────┘

        Écran diffusé : \(displayName) (\(display.width)×\(display.height))
        Encodage      : \(streamer.outputWidth)×\(streamer.outputHeight) · \(settings.fps) i/s · qualité \(String(format: "%.2f", settings.quality))
        Contrôle      : \(options.inputEnabled ? "tactile + clavier actifs" : "lecture seule (--no-input)")
        """)

        let interfaces = NetworkInfo.localIPv4Addresses()
        if interfaces.isEmpty {
            print("\n⚠️  Aucune adresse réseau trouvée. Connectez le Mac au partage de connexion.\n")
        } else {
            print("\nÀ saisir dans le navigateur de la Tesla :\n")
            for interface in interfaces {
                print("   http://\(interface.address):\(options.port)\(suffix)   ← \(interface.label)")
            }
            print("""

            (Tesla et Mac doivent être sur le même réseau : partage de connexion du téléphone,
             ou Wi-Fi du domicile. Le Wi-Fi de la Tesla se règle dans Commandes ▸ Wi-Fi.)
            """)
        }

        print("\nCtrl-C pour arrêter.\n")
    }

    // MARK: - Erreurs

    enum AppError: LocalizedError {
        case screenRecordingDenied(underlying: Error)
        case noDisplays
        case unknownDisplay(String)

        var errorDescription: String? {
            switch self {
            case let .screenRecordingDenied(underlying):
                return """
                Impossible d'accéder aux écrans (\(underlying.localizedDescription)).

                C'est presque toujours l'autorisation « Enregistrement de l'écran » :
                Réglages système ▸ Confidentialité et sécurité ▸ Enregistrement de l'écran,
                cochez l'application depuis laquelle vous lancez la commande (Terminal, iTerm…),
                puis quittez-la complètement et relancez tesla-display.
                """
            case .noDisplays:
                return "Aucun écran détecté."
            case let .unknownDisplay(selector):
                return "Écran « \(selector) » introuvable. Listez-les avec : tesla-display --list"
            }
        }
    }
}

import Foundation

/// Distribue les images JPEG capturées vers tous les clients MJPEG connectés.
/// Conserve la dernière image pour qu'un nouveau client ait quelque chose à afficher
/// immédiatement, même si l'écran est statique.
final class FrameBroadcaster {
    typealias Subscriber = (Data) -> Void

    private let lock = NSLock()
    private var subscribers: [UUID: Subscriber] = [:]
    private var latest: Data?

    var latestFrame: Data? {
        lock.lock()
        defer { lock.unlock() }
        return latest
    }

    var subscriberCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return subscribers.count
    }

    func publish(_ data: Data) {
        lock.lock()
        latest = data
        let handlers = Array(subscribers.values)
        lock.unlock()

        for handler in handlers {
            handler(data)
        }
    }

    @discardableResult
    func subscribe(_ handler: @escaping Subscriber) -> UUID {
        let id = UUID()
        lock.lock()
        subscribers[id] = handler
        lock.unlock()
        return id
    }

    func unsubscribe(_ id: UUID) {
        lock.lock()
        subscribers.removeValue(forKey: id)
        lock.unlock()
    }
}

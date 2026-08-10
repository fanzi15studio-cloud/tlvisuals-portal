import AppKit
import CoreGraphics
import CoreImage
import CoreMedia
import Foundation
import ImageIO
import ScreenCaptureKit

struct StreamSettings {
    var width: Int
    var fps: Int
    var quality: Double

    static let eco = StreamSettings(width: 960, fps: 10, quality: 0.40)
    static let normal = StreamSettings(width: 1280, fps: 15, quality: 0.55)
    static let sharp = StreamSettings(width: 1600, fps: 20, quality: 0.70)
    static let max = StreamSettings(width: 1920, fps: 24, quality: 0.80)

    func clamped() -> StreamSettings {
        StreamSettings(
            width: Swift.max(320, Swift.min(3840, width)),
            fps: Swift.max(1, Swift.min(60, fps)),
            quality: Swift.max(0.1, Swift.min(1.0, quality))
        )
    }
}

/// Capture un écran (physique ou virtuel) via ScreenCaptureKit et publie
/// chaque image en JPEG vers le `FrameBroadcaster`.
final class ScreenStreamer: NSObject, SCStreamOutput, SCStreamDelegate {
    private let broadcaster: FrameBroadcaster
    private let outputQueue = DispatchQueue(label: "com.tlv.tesla-display.capture", qos: .userInteractive)
    private let ciContext = CIContext(options: [.cacheIntermediates: false])
    private let lock = NSLock()

    private var stream: SCStream?
    private var display: SCDisplay?
    private var settings: StreamSettings
    private var lastPublish = Date.distantPast
    private var heartbeat: DispatchSourceTimer?

    private(set) var outputWidth = 0
    private(set) var outputHeight = 0

    init(broadcaster: FrameBroadcaster, settings: StreamSettings) {
        self.broadcaster = broadcaster
        self.settings = settings.clamped()
        super.init()
    }

    // MARK: - Découverte des écrans

    static func availableDisplays() async throws -> [SCDisplay] {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
        return content.displays
    }

    static func name(for displayID: CGDirectDisplayID) -> String {
        for screen in NSScreen.screens {
            let key = NSDeviceDescriptionKey("NSScreenNumber")
            if let number = screen.deviceDescription[key] as? NSNumber, number.uint32Value == displayID {
                return screen.localizedName
            }
        }
        return "Écran \(displayID)"
    }

    // MARK: - Cycle de vie

    func start(display: SCDisplay) async throws {
        self.display = display

        let filter = SCContentFilter(display: display, excludingWindows: [])
        let configuration = makeConfiguration(for: display, settings: currentSettings)

        let stream = SCStream(filter: filter, configuration: configuration, delegate: self)
        try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: outputQueue)
        try await stream.startCapture()

        self.stream = stream
        startHeartbeat()
    }

    func stop() async {
        heartbeat?.cancel()
        heartbeat = nil
        if let stream {
            try? await stream.stopCapture()
        }
        stream = nil
    }

    var currentSettings: StreamSettings {
        lock.lock()
        defer { lock.unlock() }
        return settings
    }

    func apply(settings newSettings: StreamSettings) async {
        let clamped = newSettings.clamped()
        lock.lock()
        settings = clamped
        lock.unlock()

        guard let stream, let display else { return }
        let configuration = makeConfiguration(for: display, settings: clamped)
        do {
            try await stream.updateConfiguration(configuration)
        } catch {
            FileHandle.standardError.write(Data("⚠️  Impossible d'appliquer la nouvelle configuration : \(error)\n".utf8))
        }
    }

    // MARK: - Configuration

    private func makeConfiguration(for display: SCDisplay, settings: StreamSettings) -> SCStreamConfiguration {
        let configuration = SCStreamConfiguration()

        let sourceWidth = Swift.max(display.width, 1)
        let sourceHeight = Swift.max(display.height, 1)
        let aspect = Double(sourceHeight) / Double(sourceWidth)

        // On ne suréchantillonne jamais au-delà de la résolution native de l'écran.
        var width = Swift.min(settings.width, sourceWidth)
        var height = Int((Double(width) * aspect).rounded())
        width -= width % 2
        height -= height % 2

        configuration.width = Swift.max(2, width)
        configuration.height = Swift.max(2, height)
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(settings.fps))
        configuration.queueDepth = 5
        configuration.showsCursor = true
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        configuration.colorSpaceName = CGColorSpace.sRGB
        configuration.scalesToFit = true

        outputWidth = configuration.width
        outputHeight = configuration.height

        return configuration
    }

    /// Renvoie périodiquement la dernière image quand l'écran ne bouge pas.
    /// ScreenCaptureKit n'émet rien sur un écran statique, et certaines box Wi-Fi
    /// (ou le navigateur Tesla) coupent une connexion inactive.
    private func startHeartbeat() {
        let timer = DispatchSource.makeTimerSource(queue: outputQueue)
        timer.schedule(deadline: .now() + 1.0, repeating: 1.0)
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            self.lock.lock()
            let elapsed = Date().timeIntervalSince(self.lastPublish)
            self.lock.unlock()

            guard elapsed >= 1.0, let frame = self.broadcaster.latestFrame else { return }
            self.broadcaster.publish(frame)
        }
        timer.resume()
        heartbeat = timer
    }

    // MARK: - SCStreamOutput

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, CMSampleBufferIsValid(sampleBuffer) else { return }

        guard
            let attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false)
                as? [[SCStreamFrameInfo: Any]],
            let attachments = attachmentsArray.first,
            let statusRawValue = attachments[.status] as? Int,
            let status = SCFrameStatus(rawValue: statusRawValue),
            status == .complete
        else { return }

        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        lock.lock()
        let quality = settings.quality
        lock.unlock()

        let image = CIImage(cvImageBuffer: imageBuffer)
        let options: [CIImageRepresentationOption: Any] = [
            CIImageRepresentationOption(rawValue: kCGImageDestinationLossyCompressionQuality as String): quality
        ]

        guard let jpeg = ciContext.jpegRepresentation(
            of: image,
            colorSpace: CGColorSpaceCreateDeviceRGB(),
            options: options
        ) else { return }

        lock.lock()
        lastPublish = Date()
        lock.unlock()

        broadcaster.publish(jpeg)
    }

    // MARK: - SCStreamDelegate

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        FileHandle.standardError.write(Data("⚠️  La capture s'est arrêtée : \(error.localizedDescription)\n".utf8))
    }
}

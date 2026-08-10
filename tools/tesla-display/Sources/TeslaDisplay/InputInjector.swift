import ApplicationServices
import CoreGraphics
import Foundation

/// Traduit les gestes reçus depuis l'écran de la Tesla en événements souris/clavier macOS.
final class InputInjector {
    private let displayID: CGDirectDisplayID
    private let source = CGEventSource(stateID: .combinedSessionState)
    private var isButtonDown = false

    init(displayID: CGDirectDisplayID) {
        self.displayID = displayID
    }

    // MARK: - Permission

    /// L'injection d'événements nécessite l'autorisation « Accessibilité ».
    @discardableResult
    static func hasAccessibilityPermission(prompting: Bool) -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
        let options = [key: prompting] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    // MARK: - Routage des événements

    /// `event` provient du JSON envoyé par le client (`{"t": "...", ...}`).
    func handle(_ event: [String: Any]) {
        guard let kind = event["t"] as? String else { return }

        switch kind {
        case "move":
            guard let location = mapPoint(from: event) else { return }
            postMouse(.mouseMoved, at: location, button: .left)

        case "moverel":
            let dx = double(event["dx"])
            let dy = double(event["dy"])
            let location = clamp(offsetFromCurrentLocation(dx: dx, dy: dy))
            postMouse(isButtonDown ? .leftMouseDragged : .mouseMoved, at: location, button: .left)

        case "click":
            // Sans coordonnées (mode Souris), on clique là où est déjà le curseur.
            let location = mapPoint(from: event) ?? currentLocation()
            // `n` porte l'état du clic : 2 sur un appui rapproché du précédent,
            // ce qui reproduit un vrai double-clic macOS.
            let clickState = Int64(max(1, min(3, Int(double(event["n"], fallback: 1)))))
            postMouse(.mouseMoved, at: location, button: .left)
            postMouse(.leftMouseDown, at: location, button: .left, clickState: clickState)
            postMouse(.leftMouseUp, at: location, button: .left, clickState: clickState)

        case "rclick":
            guard let location = mapPoint(from: event) else { return }
            postMouse(.mouseMoved, at: location, button: .right)
            postMouse(.rightMouseDown, at: location, button: .right)
            postMouse(.rightMouseUp, at: location, button: .right)

        case "down":
            // Sans coordonnées (mode Souris), on appuie là où se trouve déjà le curseur.
            let location = mapPoint(from: event) ?? currentLocation()
            isButtonDown = true
            postMouse(.mouseMoved, at: location, button: .left)
            postMouse(.leftMouseDown, at: location, button: .left)

        case "drag":
            guard let location = mapPoint(from: event) else { return }
            postMouse(.leftMouseDragged, at: location, button: .left)

        case "up":
            let location = mapPoint(from: event) ?? currentLocation()
            postMouse(.leftMouseUp, at: location, button: .left)
            isButtonDown = false

        case "scroll":
            scroll(dx: double(event["dx"]), dy: double(event["dy"]))

        case "text":
            guard let text = event["s"] as? String, !text.isEmpty else { return }
            typeText(text)

        case "key":
            guard let name = event["k"] as? String, let keyCode = InputInjector.keyCodes[name] else { return }
            let mods = (event["mods"] as? [String]) ?? []
            pressKey(code: keyCode, flags: InputInjector.flags(from: mods))

        default:
            break
        }
    }

    // MARK: - Souris

    private func postMouse(
        _ type: CGEventType,
        at point: CGPoint,
        button: CGMouseButton,
        clickState: Int64 = 1
    ) {
        guard let event = CGEvent(
            mouseEventSource: source,
            mouseType: type,
            mouseCursorPosition: point,
            mouseButton: button
        ) else { return }
        event.setIntegerValueField(.mouseEventClickState, value: clickState)
        event.post(tap: .cghidEventTap)
    }

    private func scroll(dx: Double, dy: Double) {
        let vertical = Int32(clampToInt32(dy))
        let horizontal = Int32(clampToInt32(dx))
        guard vertical != 0 || horizontal != 0 else { return }
        guard let event = CGEvent(
            scrollWheelEvent2Source: source,
            units: .pixel,
            wheelCount: 2,
            wheel1: vertical,
            wheel2: horizontal,
            wheel3: 0
        ) else { return }
        event.post(tap: .cghidEventTap)
    }

    // MARK: - Clavier

    private func typeText(_ text: String) {
        // Découpé en petits blocs : `keyboardSetUnicodeString` sature au-delà d'une poignée de caractères.
        for chunk in Array(text).chunked(into: 8) {
            var utf16 = Array(String(chunk).utf16)
            guard let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
                  let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
            else { return }
            down.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: &utf16)
            up.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: &utf16)
            down.post(tap: .cghidEventTap)
            up.post(tap: .cghidEventTap)
        }
    }

    private func pressKey(code: CGKeyCode, flags: CGEventFlags) {
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: false)
        else { return }
        down.flags = flags
        up.flags = flags
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }

    // MARK: - Géométrie

    private var bounds: CGRect { CGDisplayBounds(displayID) }

    /// Les coordonnées arrivent normalisées (0…1) : indépendantes de la résolution
    /// de capture comme de la taille d'affichage sur la Tesla.
    private func mapPoint(from event: [String: Any]) -> CGPoint? {
        guard let x = event["x"] as? Double, let y = event["y"] as? Double else { return nil }
        let frame = bounds
        return CGPoint(
            x: frame.origin.x + min(max(x, 0), 1) * frame.width,
            y: frame.origin.y + min(max(y, 0), 1) * frame.height
        )
    }

    private func currentLocation() -> CGPoint {
        CGEvent(source: nil)?.location ?? CGPoint(x: bounds.midX, y: bounds.midY)
    }

    private func offsetFromCurrentLocation(dx: Double, dy: Double) -> CGPoint {
        let current = currentLocation()
        return CGPoint(x: current.x + dx, y: current.y + dy)
    }

    private func clamp(_ point: CGPoint) -> CGPoint {
        let frame = bounds
        return CGPoint(
            x: min(max(point.x, frame.minX), frame.maxX - 1),
            y: min(max(point.y, frame.minY), frame.maxY - 1)
        )
    }

    // MARK: - Utilitaires

    private func double(_ value: Any?, fallback: Double = 0) -> Double {
        if let number = value as? Double { return number }
        if let number = value as? Int { return Double(number) }
        if let number = value as? NSNumber { return number.doubleValue }
        return fallback
    }

    private func clampToInt32(_ value: Double) -> Double {
        min(max(value.rounded(), -10_000), 10_000)
    }

    private static func flags(from mods: [String]) -> CGEventFlags {
        var flags: CGEventFlags = []
        for mod in mods {
            switch mod.lowercased() {
            case "cmd", "command", "meta": flags.insert(.maskCommand)
            case "shift": flags.insert(.maskShift)
            case "alt", "option": flags.insert(.maskAlternate)
            case "ctrl", "control": flags.insert(.maskControl)
            case "fn": flags.insert(.maskSecondaryFn)
            default: break
            }
        }
        return flags
    }

    /// Codes de touches virtuelles macOS (`Carbon HIToolbox`).
    private static let keyCodes: [String: CGKeyCode] = [
        "Enter": 36, "Return": 36,
        "Tab": 48,
        "Space": 49,
        "Backspace": 51, "Delete": 51,
        "Escape": 53, "Esc": 53,
        "ForwardDelete": 117,
        "ArrowLeft": 123, "ArrowRight": 124, "ArrowDown": 125, "ArrowUp": 126,
        "Home": 115, "End": 119, "PageUp": 116, "PageDown": 121,
        "A": 0, "S": 1, "D": 2, "F": 3, "H": 4, "G": 5, "Z": 6, "X": 7, "C": 8, "V": 9,
        "B": 11, "Q": 12, "W": 13, "E": 14, "R": 15, "Y": 16, "T": 17,
        "N": 45, "M": 46, "P": 35, "L": 37,
        "F1": 122, "F2": 120, "F3": 99, "F4": 118, "F5": 96, "F6": 97,
        "F11": 103, "F12": 111
    ]
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map { start in
            Array(self[start..<Swift.min(start + size, count)])
        }
    }
}

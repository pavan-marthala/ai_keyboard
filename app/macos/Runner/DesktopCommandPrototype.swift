import Cocoa
import ApplicationServices
import Carbon

/// Phase 13.2.5.7 — macOS @Command End-to-End Native Prototype
/// Clean, isolated native prototype observing keyboard input across foreground applications,
/// detecting trailing @fix commands, and replacing text with deterministic mock results.
final class DesktopCommandPrototype {
    static let shared = DesktopCommandPrototype()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private var typedBuffer: String = ""
    private let bufferLock = NSLock()
    private let maxBufferSize: Int = 500
    private var isTransforming: Bool = false

    private let mockDatabase: [String: String] = [
        "hello world": "Hello world.",
        "i has a apple": "I have an apple.",
        "i have a apple": "I have an apple.",
        "this sentence needs fixing": "This sentence has been fixed.",
        "i am going office tomorrow": "I am going to the office tomorrow."
    ]

    private init() {}

    func start() {
        print("[DesktopCommandPrototype] Prototype started.")

        let mask = (1 << CGEventType.keyDown.rawValue)
        let observerSelf = Unmanaged.passUnretained(self).toOpaque()

        let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let prototype = Unmanaged<DesktopCommandPrototype>.fromOpaque(refcon).takeUnretainedValue()
                return prototype.handleEventTap(proxy: proxy, type: type, event: event)
            },
            userInfo: observerSelf
        )

        if let tap = tap {
            self.eventTap = tap
            let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            self.runLoopSource = source
            if let source = source {
                CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
            }
            CGEvent.tapEnable(tap: tap, enable: true)
            print("[DesktopCommandPrototype] Keyboard observation active.")
        } else {
            print("[DesktopCommandPrototype] Keyboard observation unavailable (permissions not granted).")
        }
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            }
            eventTap = nil
            runLoopSource = nil
        }
        print("[DesktopCommandPrototype] Prototype stopped.")
    }

    // MARK: - Event Handling

    private func handleEventTap(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }

        guard type == .keyDown else {
            return Unmanaged.passRetained(event)
        }

        if isTransforming {
            return Unmanaged.passRetained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        processKeyCode(Int(keyCode), cgEvent: event)

        return Unmanaged.passRetained(event)
    }

    private func processKeyCode(_ keyCode: Int, cgEvent: CGEvent) {
        bufferLock.lock()
        defer { bufferLock.unlock() }

        // Key code 51 = Backspace / Delete
        if keyCode == 51 {
            if !typedBuffer.isEmpty {
                typedBuffer.removeLast()
            }
            return
        }

        // Key code 53 = Escape
        if keyCode == 53 {
            typedBuffer.removeAll()
            return
        }

        var actualLength: Int = 0
        var unicodeChars = [UniChar](repeating: 0, count: 4)
        cgEvent.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &actualLength, unicodeString: &unicodeChars)

        guard actualLength > 0 else { return }
        let typedChars = String(utf16CodeUnits: unicodeChars, count: actualLength)

        typedBuffer.append(typedChars)

        if typedBuffer.count > maxBufferSize {
            typedBuffer = String(typedBuffer.suffix(maxBufferSize))
        }

        checkForCommandTrigger()
    }

    // MARK: - Command Detection

    private func checkForCommandTrigger() {
        let bufferSnapshot = typedBuffer

        guard let match = parseTrailingCommand(in: bufferSnapshot) else {
            return
        }

        let transformed = transformMock(cleanText: match.cleanText)

        print("[DesktopCommandPrototype] Detected @fix")
        print("[DesktopCommandPrototype] Original text: '\(match.cleanText)'")
        print("[DesktopCommandPrototype] Mock transformed text: '\(transformed)'")

        // Re-entrancy guard
        isTransforming = true
        typedBuffer.removeAll()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }
            self.executeReplacement(cleanText: match.cleanText, rawTrigger: match.rawTrigger, transformedText: transformed)
            self.isTransforming = false
        }
    }

    struct CommandMatch {
        let cleanText: String
        let rawTrigger: String
        let totalTrailingLength: Int
    }

    private func parseTrailingCommand(in text: String) -> CommandMatch? {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return nil
        }

        let trimmed = text.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
        let tokens = trimmed.components(separatedBy: CharacterSet.whitespacesAndNewlines).filter { !$0.isEmpty }

        guard let lastToken = tokens.last else { return nil }

        let cleanLastToken = lastToken.lowercased()
        guard cleanLastToken == "@fix" else {
            return nil
        }

        // Prevent false positives on email-like strings (e.g. user@fix or test@example.com)
        if lastToken.contains("://") || (lastToken.contains(".") && !lastToken.hasSuffix(".")) {
            return nil
        }

        guard let tokenRange = trimmed.range(of: lastToken, options: .backwards) else {
            return nil
        }

        let rawPreceding = String(trimmed[..<tokenRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawPreceding.isEmpty else {
            return nil
        }

        var cleanText = rawPreceding
        let boundaries = [". ", "! ", "? ", "\n"]
        var highestIndex: String.Index? = nil

        for delim in boundaries {
            if let r = rawPreceding.range(of: delim, options: .backwards) {
                if highestIndex == nil || r.upperBound > highestIndex! {
                    highestIndex = r.upperBound
                }
            }
        }

        if let boundary = highestIndex {
            cleanText = String(rawPreceding[boundary...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard !cleanText.isEmpty else { return nil }

        let totalLength = text.count
        return CommandMatch(cleanText: cleanText, rawTrigger: lastToken, totalTrailingLength: totalLength)
    }

    private func transformMock(cleanText: String) -> String {
        let normalized = cleanText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let mapped = mockDatabase[normalized] {
            return mapped
        }

        var result = cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let first = result.first {
            result = first.uppercased() + result.dropFirst()
        }
        if !result.hasSuffix(".") && !result.hasSuffix("!") && !result.hasSuffix("?") {
            result += "."
        }
        return result
    }

    // MARK: - Text Replacement Execution

    private func executeReplacement(cleanText: String, rawTrigger: String, transformedText: String) {
        // Strategy 1: Accessibility API
        if replaceViaAccessibility(cleanText: cleanText, rawTrigger: rawTrigger, transformedText: transformedText) {
            print("[DesktopCommandPrototype] Replacement succeeded via Accessibility API.")
            return
        }

        // Strategy 2: Keystroke simulation fallback
        replaceViaKeystrokes(cleanText: cleanText, rawTrigger: rawTrigger, transformedText: transformedText)
        print("[DesktopCommandPrototype] Replacement succeeded via Keystroke fallback.")
    }

    private func replaceViaAccessibility(cleanText: String, rawTrigger: String, transformedText: String) -> Bool {
        let systemWide = AXUIElementCreateSystemWide()

        var focusedElementRef: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focusedElementRef)
        guard err == .success, let focusedRef = focusedElementRef else {
            return false
        }

        let element = focusedRef as! AXUIElement

        var selectedRangeValue: CFTypeRef?
        let rangeErr = AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &selectedRangeValue)
        guard rangeErr == .success, let rangeVal = selectedRangeValue else {
            return false
        }

        var cursorRange = CFRange()
        guard AXValueGetValue(rangeVal as! AXValue, .cfRange, &cursorRange) else {
            return false
        }

        var textValueRef: CFTypeRef?
        let textErr = AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &textValueRef)
        guard textErr == .success, let documentText = textValueRef as? String else {
            return false
        }

        let cursorLocation = cursorRange.location
        guard cursorLocation >= 0 && cursorLocation <= documentText.count else {
            return false
        }

        let prefixIndex = documentText.index(documentText.startIndex, offsetBy: cursorLocation)
        let textBeforeCursor = String(documentText[..<prefixIndex])

        // Verify command is trailing (no non-whitespace text following cursor on the same line)
        if cursorLocation < documentText.count {
            let textAfter = String(documentText[prefixIndex...])
            let firstLineAfter = textAfter.components(separatedBy: "\n").first ?? ""
            let trimmedAfter = firstLineAfter.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedAfter.isEmpty {
                return false
            }
        }

        guard textBeforeCursor.range(of: rawTrigger, options: .backwards) != nil,
              let cleanRange = textBeforeCursor.range(of: cleanText, options: .backwards) else {
            return false
        }

        let replaceStartOffset = documentText.distance(from: documentText.startIndex, to: cleanRange.lowerBound)
        let replaceEndOffset = documentText.distance(from: documentText.startIndex, to: prefixIndex)
        let replaceLength = replaceEndOffset - replaceStartOffset

        guard replaceLength > 0 else { return false }

        var targetRange = CFRange(location: replaceStartOffset, length: replaceLength)
        guard let newRangeValue = AXValueCreate(.cfRange, &targetRange) else { return false }

        let setRangeErr = AXUIElementSetAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, newRangeValue)
        if setRangeErr != .success {
            return false
        }

        let setStringErr = AXUIElementSetAttributeValue(element, kAXSelectedTextAttribute as CFString, transformedText as CFString)
        if setStringErr != .success {
            return false
        }

        return true
    }

    private func replaceViaKeystrokes(cleanText: String, rawTrigger: String, transformedText: String) {
        let deleteCount = cleanText.count + 1 + rawTrigger.count + 1
        let source = CGEventSource(stateID: .hidSystemState)

        for _ in 0..<deleteCount {
            let down = CGEvent(keyboardEventSource: source, virtualKey: 51, keyDown: true)
            let up = CGEvent(keyboardEventSource: source, virtualKey: 51, keyDown: false)
            down?.post(tap: .cghidEventTap)
            up?.post(tap: .cghidEventTap)
            usleep(2000)
        }

        usleep(10000)

        for char in transformedText.utf16 {
            var codeUnit = char
            let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true)
            down?.keyboardSetUnicodeString(stringLength: 1, unicodeString: &codeUnit)
            down?.post(tap: .cghidEventTap)

            let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
            up?.keyboardSetUnicodeString(stringLength: 1, unicodeString: &codeUnit)
            up?.post(tap: .cghidEventTap)

            usleep(2000)
        }
    }
}

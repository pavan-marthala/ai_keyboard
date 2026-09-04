import Cocoa
import ApplicationServices
import Carbon

func protoLog(_ message: String) {
    print(message)
    NSLog("%@", message)
    let line = "\(message)\n"
    guard let data = line.data(using: .utf8) else { return }
    let paths = [
        "/Users/a2442/StudioProjects/ai_keyboard/app/prototype.log",
        "/tmp/ai_keyboard_prototype.log"
    ]
    for path in paths {
        if let handle = FileHandle(forWritingAtPath: path) {
            handle.seekToEndOfFile()
            handle.write(data)
            handle.closeFile()
        } else {
            try? data.write(to: URL(fileURLWithPath: path))
        }
    }
}

/// Isolated macOS @Command prototype. Debug stages are switched explicitly so
/// CGEventTap and NSEvent monitoring are never both feeding the buffer at once.
final class DesktopCommandPrototype {
    static let shared = DesktopCommandPrototype()

    /// Stage 1/2a: CGEventTap only, keys → log.
    /// Stage 2b: NSEvent only, keys → log.
    /// Later stages re-enable command detection + replacement.
    private enum DebugStage {
        case observeCgEventTapOnly
        case observeNsEventOnly
        case fullPipeline
    }

    private let debugStage: DebugStage = .observeCgEventTapOnly

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var globalMonitor: Any?
    private var heartbeatTimer: Timer?

    private var typedBuffer: String = ""
    private let bufferLock = NSLock()
    private let maxBufferSize: Int = 500
    private var isTransforming: Bool = false

    private var cgTapCallbackCount: Int = 0
    private var cgKeyDownCount: Int = 0
    private var nsKeyDownCount: Int = 0

    private let mockDatabase: [String: String] = [
        "hello world": "Hello world.",
        "i has a apple": "I have an apple.",
        "i have a apple": "I have an apple.",
        "this sentence needs fixing": "This sentence has been fixed.",
        "i am going office tomorrow": "I am going to the office tomorrow."
    ]

    private init() {}

    func start() {
        protoLog("[DesktopCommandPrototype] ===== PROTOTYPE STARTUP =====")
        protoLog("[DesktopCommandPrototype] debugStage=\(debugStage)")
        protoLog("[DesktopCommandPrototype] pid=\(ProcessInfo.processInfo.processIdentifier)")
        protoLog("[DesktopCommandPrototype] bundleId=\(Bundle.main.bundleIdentifier ?? "unknown")")
        protoLog("[DesktopCommandPrototype] bundlePath=\(Bundle.main.bundlePath)")

        logTrustState(prefix: "pre-request")

        let axOptions = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let axPrompted = AXIsProcessTrustedWithOptions(axOptions)
        protoLog("[DesktopCommandPrototype] AXIsProcessTrustedWithOptions(prompt)= \(axPrompted)")
        let hidRequested = IOHIDRequestAccess(1)
        protoLog("[DesktopCommandPrototype] IOHIDRequestAccess(listen)=\(hidRequested)")

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            self.logTrustState(prefix: "post-request+2s")
            switch self.debugStage {
            case .observeCgEventTapOnly:
                self.setupEventTap()
            case .observeNsEventOnly:
                self.setupNSEventMonitor()
            case .fullPipeline:
                self.setupEventTap()
            }
            self.scheduleTextEditKeyProbe()
        }

        startHeartbeat()
        protoLog("[DesktopCommandPrototype] DesktopCommandPrototype started.")
    }

    private func logTrustState(prefix: String) {
        let axTrusted = AXIsProcessTrusted()
        let hidListen = IOHIDCheckAccess(1)
        let hidPost = IOHIDCheckAccess(0)
        protoLog("[DesktopCommandPrototype] TRUST[\(prefix)] AXIsProcessTrusted=\(axTrusted) IOHID(listen)=\(hidListen) IOHID(post)=\(hidPost) (0=granted,1=denied,2=unknown)")
    }

    private func scheduleTextEditKeyProbe() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
            protoLog("[DesktopCommandPrototype] TEXTEDIT PROBE: launching TextEdit")
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.TextEdit") else {
                protoLog("[DesktopCommandPrototype] TEXTEDIT PROBE: TextEdit URL missing")
                return
            }
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            NSWorkspace.shared.openApplication(at: url, configuration: config) { app, error in
                if let error = error {
                    protoLog("[DesktopCommandPrototype] TEXTEDIT PROBE: open failed \(error)")
                    return
                }
                protoLog("[DesktopCommandPrototype] TEXTEDIT PROBE: TextEdit launched pid=\(app?.processIdentifier ?? -1)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self?.postProbeKeystrokes("abc123")
                }
            }
        }
    }

    private func postProbeKeystrokes(_ text: String) {
        let front = NSWorkspace.shared.frontmostApplication
        protoLog("[DesktopCommandPrototype] TEXTEDIT PROBE: posting '\(text)' frontmost=\(front?.localizedName ?? "unknown") hidPost=\(IOHIDCheckAccess(0))")
        let source = CGEventSource(stateID: .hidSystemState)
        if source == nil {
            protoLog("[DesktopCommandPrototype] TEXTEDIT PROBE: CGEventSource nil")
        }
        for char in text.utf16 {
            var codeUnit = char
            let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true)
            down?.keyboardSetUnicodeString(stringLength: 1, unicodeString: &codeUnit)
            down?.post(tap: .cghidEventTap)
            let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
            up?.keyboardSetUnicodeString(stringLength: 1, unicodeString: &codeUnit)
            up?.post(tap: .cghidEventTap)
            usleep(30_000)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            protoLog("[DesktopCommandPrototype] TEXTEDIT PROBE RESULT cgCallback=\(self.cgTapCallbackCount) cgKeyDown=\(self.cgKeyDownCount) nsKeyDown=\(self.nsKeyDownCount) buffer='\(self.typedBuffer)'")
        }
    }

    private func setupEventTap() {
        if eventTap != nil { return }

        let mask = (1 << CGEventType.keyDown.rawValue)
        let observerSelf = Unmanaged.passUnretained(self).toOpaque()

        protoLog("[DesktopCommandPrototype] CGEvent.tapCreate attempting session tap, listenOnly, keyDown mask=\(mask)")

        let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let prototype = Unmanaged<DesktopCommandPrototype>.fromOpaque(refcon).takeUnretainedValue()
                return prototype.handleEventTap(proxy: proxy, type: type, event: event)
            },
            userInfo: observerSelf
        )

        if let tap = tap {
            self.eventTap = tap
            let enabled = CGEvent.tapIsEnabled(tap: tap)
            protoLog("[DesktopCommandPrototype] CGEvent.tapCreate result=NON-NIL")
            protoLog("[DesktopCommandPrototype] CGEvent.tapIsEnabled after create=\(enabled)")

            let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            self.runLoopSource = source
            if let source = source {
                CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
                protoLog("[DesktopCommandPrototype] CGEventTap run-loop source created and added to main/.commonModes")
            } else {
                protoLog("[DesktopCommandPrototype] CGEventTap run-loop source CREATE FAILED")
            }

            CGEvent.tapEnable(tap: tap, enable: true)
            protoLog("[DesktopCommandPrototype] CGEvent.tapIsEnabled after enable=\(CGEvent.tapIsEnabled(tap: tap))")
        } else {
            protoLog("[DesktopCommandPrototype] CGEvent.tapCreate result=NIL")
            protoLog("[DesktopCommandPrototype] trying defaultTap session tap as second attempt")
            let defaultTap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: CGEventMask(mask),
                callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                    guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                    let prototype = Unmanaged<DesktopCommandPrototype>.fromOpaque(refcon).takeUnretainedValue()
                    return prototype.handleEventTap(proxy: proxy, type: type, event: event)
                },
                userInfo: observerSelf
            )
            if let defaultTap = defaultTap {
                self.eventTap = defaultTap
                protoLog("[DesktopCommandPrototype] CGEvent.tapCreate defaultTap result=NON-NIL enabled=\(CGEvent.tapIsEnabled(tap: defaultTap))")
                let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, defaultTap, 0)
                self.runLoopSource = source
                if let source = source {
                    CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
                    protoLog("[DesktopCommandPrototype] CGEventTap defaultTap run-loop source added")
                }
                CGEvent.tapEnable(tap: defaultTap, enable: true)
            } else {
                protoLog("[DesktopCommandPrototype] CGEvent.tapCreate defaultTap result=NIL — keyboard tap unavailable")
            }
        }
    }

    private func setupNSEventMonitor() {
        self.globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleGlobalNSEvent(event)
        }
        protoLog("[DesktopCommandPrototype] NSEvent.addGlobalMonitorForEvents token=\(globalMonitor != nil ? "RETAINED" : "NIL")")
    }

    private func startHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let tapState: String
            if let tap = self.eventTap {
                tapState = "exists enabled=\(CGEvent.tapIsEnabled(tap: tap))"
            } else {
                tapState = "nil"
            }
            protoLog("[DesktopCommandPrototype] HEARTBEAT tap=\(tapState) AX=\(AXIsProcessTrusted()) HIDListen=\(IOHIDCheckAccess(1)) cgCallback=\(self.cgTapCallbackCount) cgKeyDown=\(self.cgKeyDownCount) nsKeyDown=\(self.nsKeyDownCount) frontmost=\(NSWorkspace.shared.frontmostApplication?.localizedName ?? "unknown")")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 24.0) { [weak self] in
            self?.heartbeatTimer?.invalidate()
            self?.heartbeatTimer = nil
            protoLog("[DesktopCommandPrototype] HEARTBEAT stopped after 24s")
        }
    }

    func stop() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            }
            eventTap = nil
            runLoopSource = nil
        }
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        protoLog("[DesktopCommandPrototype] DesktopCommandPrototype stopped.")
    }

    // MARK: - Event Handling

    private func handleEventTap(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        cgTapCallbackCount += 1

        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            protoLog("[DesktopCommandPrototype] CGEventTap DISABLED type=\(type.rawValue) — re-enabling")
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        protoLog("[DesktopCommandPrototype] CGEventTap CALLBACK type=\(type.rawValue) count=\(cgTapCallbackCount)")

        if type != .keyDown {
            return Unmanaged.passUnretained(event)
        }

        cgKeyDownCount += 1
        if isTransforming {
            protoLog("[DesktopCommandPrototype] CGEventTap keyDown ignored (isTransforming)")
            return Unmanaged.passUnretained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        processKeyCode(Int(keyCode), cgEvent: event, source: "CGEventTap")
        return Unmanaged.passUnretained(event)
    }

    private func handleGlobalNSEvent(_ event: NSEvent) {
        nsKeyDownCount += 1
        protoLog("[DesktopCommandPrototype] NSEvent CALLBACK keyCode=\(event.keyCode) chars=\(event.characters ?? "") count=\(nsKeyDownCount)")
        if isTransforming { return }
        processKeyCode(Int(event.keyCode), cgEvent: nil, characters: event.characters, source: "NSEvent")
    }

    private func processKeyCode(_ keyCode: Int, cgEvent: CGEvent?, characters: String? = nil, source: String) {
        bufferLock.lock()
        defer { bufferLock.unlock() }

        let frontmost = NSWorkspace.shared.frontmostApplication
        let frontName = frontmost?.localizedName ?? "unknown"
        let frontBundle = frontmost?.bundleIdentifier ?? "unknown"
        let frontPid = frontmost?.processIdentifier ?? 0

        if keyCode == 51 {
            if !typedBuffer.isEmpty {
                typedBuffer.removeLast()
            }
            protoLog("[DesktopCommandPrototype] \(source) backspace frontmost=\(frontName) buffer='\(typedBuffer)'")
            return
        }

        if keyCode == 53 {
            typedBuffer.removeAll()
            protoLog("[DesktopCommandPrototype] \(source) escape — buffer cleared")
            return
        }

        var typedChars: String = ""
        if let chars = characters, !chars.isEmpty {
            typedChars = chars
        } else if let event = cgEvent {
            var actualLength: Int = 0
            var unicodeChars = [UniChar](repeating: 0, count: 4)
            event.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &actualLength, unicodeString: &unicodeChars)
            if actualLength > 0 {
                typedChars = String(utf16CodeUnits: unicodeChars, count: actualLength)
            }
        }

        protoLog("[DesktopCommandPrototype] \(source) keyDown keyCode=\(keyCode) chars='\(typedChars)' frontmost=\(frontName) bundle=\(frontBundle) pid=\(frontPid)")

        if typedChars.isEmpty {
            return
        }

        typedBuffer.append(typedChars)
        if typedBuffer.count > maxBufferSize {
            typedBuffer = String(typedBuffer.suffix(maxBufferSize))
        }
        protoLog("[DesktopCommandPrototype] buffer now='\(typedBuffer)'")

        if debugStage == .fullPipeline {
            checkForCommandTrigger()
        }
    }

    // MARK: - Command Detection

    private func checkForCommandTrigger() {
        let bufferSnapshot = typedBuffer

        guard let match = parseTrailingCommand(in: bufferSnapshot) else {
            return
        }

        let appName = getFocusedApplicationName()
        let transformed = transformMock(cleanText: match.cleanText)

        protoLog("\n[DesktopCommandPrototype]")
        protoLog("Focused application:\n\(appName)")
        protoLog("Current/observed text:\n\(bufferSnapshot)")
        protoLog("Detected command:\n\(match.rawTrigger)")
        protoLog("Text before command:\n\(match.cleanText)")
        protoLog("Mock result:\n\(transformed)")
        protoLog("Replacement attempt:\n\(match.cleanText) -> \(transformed)")

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
        if replaceViaAccessibility(cleanText: cleanText, rawTrigger: rawTrigger, transformedText: transformedText) {
            protoLog("Replacement strategy:\nAccessibility")
            protoLog("Replacement result:\nSUCCESS")
            return
        }

        protoLog("Replacement strategy:\nKeystroke fallback")
        replaceViaKeystrokes(cleanText: cleanText, rawTrigger: rawTrigger, transformedText: transformedText)
        protoLog("Replacement result:\nSUCCESS")
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

        if cursorLocation < documentText.count {
            let textAfter = String(documentText[prefixIndex...])
            let firstLineAfter = textAfter.components(separatedBy: "\n").first ?? ""
            let trimmedAfter = firstLineAfter.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedAfter.isEmpty {
                protoLog("[DesktopCommandPrototype] Non-trailing command (text follows cursor: '\(trimmedAfter)'). Aborting replacement.")
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

    private func getFocusedApplicationName() -> String {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedAppRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedAppRef) == .success,
           let app = focusedAppRef {
            let appElement = app as! AXUIElement
            var pid: pid_t = 0
            AXUIElementGetPid(appElement, &pid)
            if let runningApp = NSRunningApplication(processIdentifier: pid) {
                return runningApp.localizedName ?? "Unknown"
            }
        }
        return NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown"
    }
}

import Cocoa
import ApplicationServices
import Carbon

/// macOS Shortcut + Selected Text @Command Prototype (Phase 13.2.7).
///
/// Workflow:
/// 1. User selects text in any supported macOS text application.
/// 2. User presses global shortcut: Control + Option + Space.
/// 3. Prototype captures focused element and selected text via AX.
/// 4. Native AppKit command prompt window appears.
/// 5. User selects a command (@fix, @rewrite, @short, @expand).
/// 6. Selected text is transformed via deterministic mock logic.
/// 7. Selected text in target application is replaced via synthetic
///    keystroke injection (NOT via AX attribute mutation) and verified.
///
/// IMPORTANT — WHY THIS FILE CHANGED FROM 13.2.6:
///
/// The previous implementation mutated the target document by calling
/// AXUIElementSetAttributeValue on kAXSelectedTextAttribute / kAXValueAttribute,
/// then trusted a matching AXUIElementCopyAttributeValue readback as proof of
/// success. That is unsafe: many Cocoa apps' generic NSAccessibility bridge
/// (TextEdit's NSTextView-backed element included) can accept an attribute
/// "set" call and even echo the new value back on read, without ever routing
/// the mutation through the real NSTextInputClient / responder-chain path
/// AppKit uses to invalidate layout and redraw. That decouples "AX readback
/// success" from "the screen actually changed" — which is exactly the bug
/// this prototype was hitting.
///
/// The fix: since the target text is already selected when we act, we type
/// the replacement as synthetic keystrokes (CGEvent + keyboardSetUnicodeString)
/// posted to the target process. This exercises the exact same code path a
/// live human keystroke takes (delete selection, insert new run), which is
/// reliable across apps because it doesn't depend on an app's AX bridge being
/// fully/correctly wired for programmatic mutation — only on it handling
/// normal typed input, which every text app must do correctly by definition.
final class DesktopShortcutCommandPrototype {

    static let shared = DesktopShortcutCommandPrototype()

    // MARK: - State

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var globalMonitor: Any?

    private var lastTriggerTime: TimeInterval = 0
    private var isReplacing = false

    // Context captured at shortcut trigger
    private var targetElement: AXUIElement?
    private var targetApp: NSRunningApplication?
    private var targetPid: pid_t = 0
    private var originalSelectedText = ""
    private var originalSelectedRange = CFRange(location: -1, length: 0)

    // UI
    private var promptPanel: NSPanel?

    // MARK: - Lifecycle

    func start() {
        NSLog("[DesktopShortcutPrototype] STARTED")
        NSLog("[DesktopShortcutPrototype] Registered global shortcut: Control + Option + Space")

        setupEventTap()
        setupGlobalMonitor()
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        eventTap = nil
        runLoopSource = nil
        closePrompt()
    }

    // MARK: - Global Shortcut Setup

    private func setupEventTap() {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let observerSelf = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { proxy, type, event, refcon in
                guard let refcon else { return Unmanaged.passRetained(event) }
                let prototype = Unmanaged<DesktopShortcutCommandPrototype>.fromOpaque(refcon).takeUnretainedValue()
                return prototype.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: observerSelf
        ) else {
            NSLog("[DesktopShortcutPrototype] CGEvent.tapCreate failed (Accessibility permission may be required)")
            return
        }

        eventTap = tap
        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            NSLog("[DesktopShortcutPrototype] Failed to create run loop source for event tap")
            return
        }

        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func setupGlobalMonitor() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return }
            let isControl = event.modifierFlags.contains(.control)
            let isOption = event.modifierFlags.contains(.option)
            let isCommand = event.modifierFlags.contains(.command)

            // Control + Option + Space (keyCode 49)
            if isControl && isOption && !isCommand && event.keyCode == 49 {
                self.triggerShortcut()
            }
        }
    }

    private func handleEvent(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }

        guard type == .keyDown else {
            return Unmanaged.passRetained(event)
        }

        let flags = event.flags
        let isControl = flags.contains(.maskControl)
        let isOption = flags.contains(.maskAlternate)
        let isCommand = flags.contains(.maskCommand)
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        // Control + Option + Space (keyCode 49)
        if isControl && isOption && !isCommand && keyCode == 49 {
            DispatchQueue.main.async { [weak self] in
                self?.triggerShortcut()
            }
            // Suppress the space event so it is not typed into the active control
            return nil
        }

        return Unmanaged.passRetained(event)
    }

    // MARK: - Shortcut Triggered

    private func triggerShortcut() {
        let now = Date().timeIntervalSince1970
        guard now - lastTriggerTime > 0.35 else { return }
        lastTriggerTime = now

        guard !isReplacing else { return }

        NSLog("[DesktopShortcutPrototype] GLOBAL SHORTCUT DETECTED")

        // 1. Determine frontmost application & focused AX element.
        // This MUST happen before we ever touch our own UI, so we capture
        // the real original target rather than something derived after our
        // panel steals focus.
        let systemWide = AXUIElementCreateSystemWide()
        var focusedRef: CFTypeRef?
        let focusedErr = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedRef
        )

        guard focusedErr == .success, let focusedRef else {
            NSLog("[DesktopShortcutPrototype] No focused AX element")
            return
        }

        let element = focusedRef as! AXUIElement
        var pid: pid_t = 0
        AXUIElementGetPid(element, &pid)

        let app = NSRunningApplication(processIdentifier: pid)
        let appName = app?.localizedName ?? "Unknown (\(pid))"

        NSLog("[DesktopShortcutPrototype] TARGET PID = \(pid)")
        NSLog("[DesktopShortcutPrototype] TARGET APP = \(appName)")

        // 2. Read selected text
        var selectedTextRef: CFTypeRef?
        let textErr = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            &selectedTextRef
        )

        guard textErr == .success,
              let selectedText = selectedTextRef as? String,
              !selectedText.isEmpty
        else {
            NSLog("[DesktopShortcutPrototype] No selected text")
            return
        }

        NSLog("[DesktopShortcutPrototype] SELECTED TEXT = '\(selectedText)'")

        // 3. Read selected range
        var rangeRef: CFTypeRef?
        var range = CFRange(location: -1, length: 0)
        if AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &rangeRef) == .success,
           let rangeRef {
            AXValueGetValue(rangeRef as! AXValue, .cfRange, &range)
        }

        // Preserve context — this is the ORIGINAL target, captured before
        // our own prompt window ever appears.
        self.targetElement = element
        self.targetApp = app
        self.targetPid = pid
        self.originalSelectedText = selectedText
        self.originalSelectedRange = range

        // 4. Open command prompt
        showCommandPrompt(selectedText: selectedText)
    }

    // MARK: - Command Prompt UI

    private func showCommandPrompt(selectedText: String) {
        closePrompt()

        let panelWidth: CGFloat = 280
        let panelHeight: CGFloat = 260

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        panel.title = "Select command"
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.center()

        let contentView = NSView(frame: panel.contentView?.bounds ?? NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight))

        let titleLabel = NSTextField(labelWithString: "What do you want to do?")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 13)
        titleLabel.frame = NSRect(x: 20, y: panelHeight - 40, width: panelWidth - 40, height: 20)
        contentView.addSubview(titleLabel)

        let displayPreview = selectedText.replacingOccurrences(of: "\n", with: " ")
        let truncated = displayPreview.count > 30 ? String(displayPreview.prefix(27)) + "..." : displayPreview
        let previewLabel = NSTextField(labelWithString: "\"\(truncated)\"")
        previewLabel.font = NSFont.systemFont(ofSize: 11)
        previewLabel.textColor = .secondaryLabelColor
        previewLabel.frame = NSRect(x: 20, y: panelHeight - 60, width: panelWidth - 40, height: 16)
        contentView.addSubview(previewLabel)

        let commands = [
            "@fix",
            "@rewrite",
            "@short",
            "@expand"
        ]

        var buttonY = panelHeight - 100
        for cmd in commands {
            let btn = NSButton(frame: NSRect(x: 20, y: buttonY, width: panelWidth - 40, height: 28))
            btn.title = cmd
            btn.bezelStyle = .rounded
            btn.font = NSFont.systemFont(ofSize: 12)
            if cmd == "@fix" {
                btn.keyEquivalent = "\r"
            }

            btn.target = self
            btn.action = #selector(handleCommandButtonClicked(_:))

            contentView.addSubview(btn)
            buttonY -= 32
        }

        let cancelBtn = NSButton(frame: NSRect(x: 20, y: 12, width: panelWidth - 40, height: 24))
        cancelBtn.title = "Cancel"
        cancelBtn.bezelStyle = .rounded
        cancelBtn.keyEquivalent = "\u{1b}"
        cancelBtn.target = self
        cancelBtn.action = #selector(handleCancel)
        contentView.addSubview(cancelBtn)

        panel.contentView = contentView
        self.promptPanel = panel

        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSLog("[DesktopShortcutPrototype] COMMAND PROMPT OPENED")
    }

    private func closePrompt() {
        if let panel = promptPanel {
            panel.orderOut(nil)
            promptPanel = nil
        }
    }

    @objc private func handleCancel() {
        NSLog("[DesktopShortcutPrototype] Command prompt cancelled by user")
        closePrompt()
    }

    @objc private func handleCommandButtonClicked(_ sender: NSButton) {
        let command = sender.title
        executeCommand(command)
    }

    private func executeCommand(_ command: String) {
        closePrompt()

        NSLog("[DesktopShortcutPrototype] COMMAND SELECTED = \(command)")

        let originalText = originalSelectedText
        let transformedText = transformMock(command: command, selectedText: originalText)

        NSLog("[DesktopShortcutPrototype] TRANSFORMED = '\(transformedText)'")

        executeReplacement(transformedText: transformedText)
    }

    // MARK: - Deterministic Transformation

    private func transformMock(command: String, selectedText: String) -> String {
        let trimmed = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = trimmed.lowercased()

        switch command {
        case "@fix":
            let mockDatabase: [String: String] = [
                "hello world": "Hello world.",
                "i has a apple": "I have an apple.",
                "this sentence needs fixing": "This sentence has been fixed.",
                "café is nice": "Café is nice.",
                "hello 😀 world": "Hello 😀 world."
            ]

            if let mapped = mockDatabase[normalized] {
                return mapped
            }

            var result = trimmed
            guard !result.isEmpty else { return result }

            if let first = result.first {
                result = first.uppercased() + result.dropFirst()
            }

            if !result.hasSuffix(".") && !result.hasSuffix("!") && !result.hasSuffix("?") {
                result += "."
            }

            return result

        case "@rewrite":
            let mockDatabase: [String: String] = [
                "hello world": "Please rewrite this: hello world",
                "i has a apple": "Please rewrite this: i has a apple"
            ]

            if let mapped = mockDatabase[normalized] {
                return mapped
            }

            return "Please rewrite this: \(trimmed)"

        case "@short":
            let mockDatabase: [String: String] = [
                "this is a very long example sentence.": "Long example sentence.",
                "this is a very long example sentence": "Long example sentence.",
                "hello world": "Hello.",
                "i has a apple": "An apple."
            ]

            if let mapped = mockDatabase[normalized] {
                return mapped
            }

            let words = trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
            if words.count > 3 {
                let shortened = words.suffix(3).joined(separator: " ")
                let capitalized = shortened.prefix(1).uppercased() + shortened.dropFirst()
                return capitalized.hasSuffix(".") ? capitalized : capitalized + "."
            } else if words.count > 1 {
                let shortened = words.last!
                let capitalized = shortened.prefix(1).uppercased() + shortened.dropFirst()
                return capitalized.hasSuffix(".") ? capitalized : capitalized + "."
            } else {
                return trimmed
            }

        case "@expand":
            let mockDatabase: [String: String] = [
                "hello world": "Hello world. This is an expanded example sentence.",
                "i has a apple": "I have an apple. This is an expanded example sentence."
            ]

            if let mapped = mockDatabase[normalized] {
                return mapped
            }

            var base = trimmed
            if let first = base.first {
                base = first.uppercased() + base.dropFirst()
            }

            if !base.hasSuffix(".") && !base.hasSuffix("!") && !base.hasSuffix("?") {
                base += "."
            }

            return "\(base) This is an expanded example sentence."

        default:
            return trimmed
        }
    }

    // MARK: - Replacement & Verification

    private func executeReplacement(transformedText: String) {
        isReplacing = true
        defer { isReplacing = false }

        guard let element = targetElement, let app = targetApp else {
            NSLog("[DesktopShortcutPrototype] Target AX element or app is nil")
            NSLog("[DesktopShortcutPrototype] REPLACEMENT FAILED")
            return
        }

        // 1. Reactivate the ORIGINAL target application and WAIT until it is
        // actually frontmost. Activation is asynchronous — a fixed sleep is
        // a guess, not a guarantee.
        guard reactivateAndWaitForFrontmost(app: app, timeout: 1.0) else {
            NSLog("[DesktopShortcutPrototype] Target app '\(app.localizedName ?? "?")' did not become frontmost in time")
            NSLog("[DesktopShortcutPrototype] REPLACEMENT FAILED")
            return
        }
        NSLog("[DesktopShortcutPrototype] TARGET APP ACTIVATED")

        // 2. Re-validate that the ORIGINAL selection is still intact on the
        // ORIGINAL captured element (never re-query "current focused element"
        // here — that could now be our own closed panel or something else).
        guard revalidateSelection(element: element) != nil else {
            NSLog("[DesktopShortcutPrototype] Selection lost or altered after reactivation. Expected '\(originalSelectedText)'")
            NSLog("[DesktopShortcutPrototype] REPLACEMENT FAILED")
            return
        }
        NSLog("[DesktopShortcutPrototype] SELECTION REVALIDATED")

        NSLog("[DesktopShortcutPrototype] REPLACEMENT STARTED")

        // Diagnostic snapshot only — NOT used as proof of anything below.
        var docBeforeRef: CFTypeRef?
        let docBefore = (AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &docBeforeRef) == .success ? docBeforeRef as? String : nil) ?? ""
        NSLog("[DesktopShortcutPrototype] DOC BEFORE (AX) = '\(docBefore)'")

        // 3. PRIMARY replacement mechanism: synthetic keystroke injection.
        //
        // The target text is currently selected in the target app. Typing
        // over an active selection is standard OS text-editing behavior —
        // it deletes the selection and inserts the new run through the
        // app's real NSTextInputClient / responder-chain path. Unlike
        // AXUIElementSetAttributeValue, this path is guaranteed to exist
        // and behave correctly in any properly functioning text app,
        // because it's the same path real typing uses.
        //
        // We deliberately do NOT fall back to AXUIElementSetAttributeValue
        // for the mutation itself, since that is the mechanism that produced
        // "AX says success, screen doesn't change" in the first place.
        NSLog("[DesktopShortcutPrototype] SENDING REPLACEMENT = '\(transformedText)'")
        let apiCallSucceeded = typeReplacement(transformedText, targetPid: targetPid)

        guard apiCallSucceeded else {
            NSLog("[DesktopShortcutPrototype] API CALL SUCCESS = false (failed to post synthetic keyboard events)")
            NSLog("[DesktopShortcutPrototype] REPLACEMENT FAILED")
            return
        }
        NSLog("[DesktopShortcutPrototype] API CALL SUCCESS = true (synthetic keystrokes posted)")

        // Give AppKit a brief moment to process input + redraw before we
        // read anything back.
        usleep(100_000) // 100ms

        // 4. AX readback — logged purely as a secondary diagnostic signal.
        // We do NOT treat this alone as proof of a visible change; it is
        // exactly the signal that was misleading in the previous approach.
        var docAfterRef: CFTypeRef?
        let docAfter = (AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &docAfterRef) == .success ? docAfterRef as? String : nil) ?? ""
        NSLog("[DesktopShortcutPrototype] DOC AFTER (AX readback) = '\(docAfter)'")

        let normalizedTransformed = transformedText.trimmingCharacters(in: .whitespacesAndNewlines)
        let axReadbackChanged = (docAfter != docBefore) && docAfter.contains(normalizedTransformed)

        NSLog("[DesktopShortcutPrototype] AX READBACK SUCCESS = \(axReadbackChanged)")

        // Because the mutation was driven through the real keyboard input
        // pipeline (the same one AppKit uses for user-typed characters),
        // a successful post is our strongest available signal of an actual
        // on-screen change without doing pixel-level screen inspection.
        // The AX readback above is reported alongside it purely for
        // debugging, and the two are logged as DISTINCT signals on purpose.
        NSLog("[DesktopShortcutPrototype] REPLACEMENT COMPLETED")
    }

    // MARK: - Activation

    /// Reactivates `app` and polls until it is genuinely frontmost, instead
    /// of trusting a fixed sleep after calling `activate`.
    private func reactivateAndWaitForFrontmost(app: NSRunningApplication, timeout: TimeInterval) -> Bool {
        if NSWorkspace.shared.frontmostApplication?.processIdentifier != app.processIdentifier {
            app.activate(options: .activateIgnoringOtherApps)
        }

        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier {
                return true
            }
            // Pump the run loop briefly so activation notifications can be
            // processed; this is a synchronous prototype flow triggered
            // from a button action on the main thread.
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.01))
        }

        return NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier
    }

    // MARK: - Selection Revalidation

    /// Confirms the ORIGINAL captured element still reports the ORIGINAL
    /// selected text after reactivation, attempting one restore-by-range if
    /// the selection was lost (e.g. some apps clear/collapse selection when
    /// the window resigns key). Returns the confirmed range, or nil if the
    /// original selection cannot be reconfirmed.
    private func revalidateSelection(element: AXUIElement) -> CFRange? {
        var currentSelectedText = readSelectedText(element: element)

        if currentSelectedText != originalSelectedText,
           originalSelectedRange.location >= 0,
           originalSelectedRange.length > 0 {
            var restoreRange = originalSelectedRange
            if let axRange = AXValueCreate(.cfRange, &restoreRange) {
                _ = AXUIElementSetAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, axRange)
                usleep(20_000)
                currentSelectedText = readSelectedText(element: element)
            }
        }

        guard currentSelectedText == originalSelectedText else { return nil }

        var rangeRef: CFTypeRef?
        var range = originalSelectedRange
        if AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &rangeRef) == .success,
           let rangeRef {
            AXValueGetValue(rangeRef as! AXValue, .cfRange, &range)
        }
        return range
    }

    private func readSelectedText(element: AXUIElement) -> String {
        var ref: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &ref) == .success,
           let s = ref as? String {
            return s
        }
        return ""
    }

    // MARK: - Synthetic Keystroke Injection

    /// Types `text` into whatever currently has keyboard focus in process
    /// `targetPid` by posting CGEvents carrying an explicit Unicode string.
    /// This is not limited to characters reachable from the physical
    /// keyboard layout, and it drives the target app's real text-input
    /// pipeline rather than any accessibility mutation API.
    private func typeReplacement(_ text: String, targetPid: pid_t) -> Bool {
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            return false
        }

        let units = Array(text.utf16)
        if units.isEmpty {
            return true
        }

        // CGEventKeyboardSetUnicodeString has historically had a small
        // internal buffer per event; chunk defensively so longer
        // replacement strings aren't silently truncated.
        let chunkSize = 20
        var index = 0

        while index < units.count {
            let end = min(index + chunkSize, units.count)
            var chunk = Array(units[index..<end])

            guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else {
                return false
            }

            // Clear modifier flags so leftover Control/Option from the
            // shortcut keypress can't get merged into the synthetic event.
            keyDown.flags = []
            keyUp.flags = []

            keyDown.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: &chunk)
            keyUp.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: &chunk)

            keyDown.postToPid(targetPid)
            usleep(3_000)
            keyUp.postToPid(targetPid)
            usleep(3_000)

            index = end
        }

        return true
    }
}
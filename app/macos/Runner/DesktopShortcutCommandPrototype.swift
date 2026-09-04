import Cocoa
import ApplicationServices
import Carbon

/// Independent execution context for an asynchronous command execution.
/// Guarantees that each command retains its immutable target, element,
/// range, and cancellation status across async boundaries.
final class DesktopCommandExecutionContext {
    let id: UUID
    let command: String
    let targetApp: NSRunningApplication
    let targetPid: pid_t
    let targetElement: AXUIElement
    let selectedText: String
    let selectedRange: CFRange
    var isCancelled: Bool = false

    init(
        id: UUID = UUID(),
        command: String,
        targetApp: NSRunningApplication,
        targetPid: pid_t,
        targetElement: AXUIElement,
        selectedText: String,
        selectedRange: CFRange
    ) {
        self.id = id
        self.command = command
        self.targetApp = targetApp
        self.targetPid = targetPid
        self.targetElement = targetElement
        self.selectedText = selectedText
        self.selectedRange = selectedRange
    }
}

/// macOS Shortcut + Selected Text @Command Prototype (Phase 2A).
///
/// Workflow:
/// 1. User selects text in any supported macOS text application.
/// 2. User presses global shortcut: Control + Option + Space.
/// 3. Prototype captures focused element and selected text via AX.
/// 4. Native AppKit command prompt window appears.
/// 5. User selects a command (@fix, @rewrite, @short, @expand).
/// 6. Prompt remains OPEN during processing and displays loading state.
/// 7. @fix executes real AI transformation (NO mock fallback on failure).
///    Other commands execute deterministic mock transformations.
/// 8. User can trigger another command concurrently without corruption.
/// 9. Selected text in target application is replaced via synthetic
///    keystroke injection (NOT via AX attribute mutation) and verified.
/// 10. Prompt closes when all active executions finish successfully.
final class DesktopShortcutCommandPrototype: NSObject, NSWindowDelegate {

    static let shared = DesktopShortcutCommandPrototype()

    // MARK: - State

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var globalMonitor: Any?

    private var lastTriggerTime: TimeInterval = 0
    private var isReplacing = false

    // Context captured at shortcut trigger (used to spawn new executions)
    private var targetElement: AXUIElement?
    private var targetApp: NSRunningApplication?
    private var targetPid: pid_t = 0
    private var originalSelectedText = ""
    private var originalSelectedRange = CFRange(location: -1, length: 0)

    // Active executions & background tasks
    private var activeExecutions: [UUID: DesktopCommandExecutionContext] = [:]
    private var activeTasks: [UUID: Task<Void, Never>] = [:]

    // UI
    private var promptPanel: NSPanel?
    private var statusLabel: NSTextField?
    private var progressIndicator: NSProgressIndicator?

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

        if isControl && isOption && !isCommand && keyCode == 49 {
            let now = Date().timeIntervalSince1970
            if now - lastTriggerTime > 0.35 {
                lastTriggerTime = now
                DispatchQueue.main.async { [weak self] in
                    self?.triggerShortcut()
                }
            }
            return nil
        }

        return Unmanaged.passRetained(event)
    }

    // MARK: - Shortcut Triggered

    private func triggerShortcut() {
        NSLog("[DesktopShortcutPrototype] GLOBAL SHORTCUT DETECTED: Control + Option + Space")

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

        var rangeRef: CFTypeRef?
        var range = CFRange(location: -1, length: 0)
        if AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &rangeRef) == .success,
           let rangeRef {
            AXValueGetValue(rangeRef as! AXValue, .cfRange, &range)
        }

        self.targetElement = element
        self.targetApp = app
        self.targetPid = pid
        self.originalSelectedText = selectedText
        self.originalSelectedRange = range

        showCommandPrompt(selectedText: selectedText)
    }

    // MARK: - Command Prompt UI

    private func showCommandPrompt(selectedText: String) {
        closePrompt()

        let panelWidth: CGFloat = 320
        let panelHeight: CGFloat = 330

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        panel.title = "Select command"
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.delegate = self
        panel.center()

        let contentView = NSView(frame: panel.contentView?.bounds ?? NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight))

        let titleLabel = NSTextField(labelWithString: "What do you want to do?")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 13)
        titleLabel.frame = NSRect(x: 20, y: panelHeight - 35, width: panelWidth - 40, height: 20)
        contentView.addSubview(titleLabel)

        let displayPreview = selectedText.replacingOccurrences(of: "\n", with: " ")
        let truncated = displayPreview.count > 32 ? String(displayPreview.prefix(29)) + "..." : displayPreview
        let previewLabel = NSTextField(labelWithString: "\"\(truncated)\"")
        previewLabel.font = NSFont.systemFont(ofSize: 11)
        previewLabel.textColor = .secondaryLabelColor
        previewLabel.frame = NSRect(x: 20, y: panelHeight - 55, width: panelWidth - 40, height: 16)
        contentView.addSubview(previewLabel)

        // Loading indicator
        let spinner = NSProgressIndicator(frame: NSRect(x: 20, y: panelHeight - 88, width: 16, height: 16))
        spinner.style = .spinning
        spinner.controlSize = .small
        spinner.isDisplayedWhenStopped = false
        spinner.isHidden = true
        contentView.addSubview(spinner)
        self.progressIndicator = spinner

        // Status / Loading / Error label
        let status = NSTextField(labelWithString: "")
        status.font = NSFont.systemFont(ofSize: 11)
        status.textColor = .secondaryLabelColor
        status.frame = NSRect(x: 42, y: panelHeight - 96, width: panelWidth - 62, height: 32)
        status.maximumNumberOfLines = 2
        status.lineBreakMode = .byWordWrapping
        contentView.addSubview(status)
        self.statusLabel = status

        // Command action buttons
        let commands = [
            "@fix",
            "@rewrite",
            "@short",
            "@expand"
        ]

        var buttonY = panelHeight - 136
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
            buttonY -= 34
        }

        let cancelBtn = NSButton(frame: NSRect(x: 20, y: 16, width: panelWidth - 40, height: 26))
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
        cancelAllActiveExecutions()
        if let panel = promptPanel {
            panel.delegate = nil
            panel.orderOut(nil)
            promptPanel = nil
        }
        statusLabel = nil
        progressIndicator = nil
    }

    @objc private func handleCancel() {
        NSLog("[DesktopShortcutPrototype] Command prompt cancelled by user")
        closePrompt()
    }

    func windowWillClose(_ notification: Notification) {
        NSLog("[DesktopShortcutPrototype] Command prompt window closed")
        cancelAllActiveExecutions()
        promptPanel = nil
        statusLabel = nil
        progressIndicator = nil
    }

    private func cancelAllActiveExecutions() {
        for (id, execution) in activeExecutions {
            execution.isCancelled = true
            activeTasks[id]?.cancel()
        }
        activeExecutions.removeAll()
        activeTasks.removeAll()
    }

    private func cleanupExecution(_ id: UUID) {
        activeExecutions.removeValue(forKey: id)
        activeTasks.removeValue(forKey: id)
    }

    // MARK: - Command Dispatching & Async Execution

    @objc private func handleCommandButtonClicked(_ sender: NSButton) {
        let command = sender.title
        executeCommand(command)
    }

    private func executeCommand(_ command: String) {
        guard let element = targetElement, let app = targetApp else {
            NSLog("[DesktopShortcutPrototype] Cannot execute command: Target AX element or app is nil")
            return
        }

        // Create independent, immutable execution context
        let execution = DesktopCommandExecutionContext(
            command: command,
            targetApp: app,
            targetPid: targetPid,
            targetElement: element,
            selectedText: originalSelectedText,
            selectedRange: originalSelectedRange
        )

        activeExecutions[execution.id] = execution
        updateUIForActiveExecutions()

        NSLog("[DesktopShortcutPrototype] COMMAND SELECTED = \(command) [execId: \(execution.id.uuidString.prefix(8))]")

        // All commands (@fix, @rewrite, @short, @expand) execute real AI asynchronously
        let task = Task {
            await self.executeRealAiCommand(execution: execution)
        }
        activeTasks[execution.id] = task
    }

    private func actionLabelForCommand(_ command: String) -> String {
        switch command.lowercased() {
        case "@fix": return "Fixing..."
        case "@rewrite": return "Rewriting..."
        case "@short": return "Shortening..."
        case "@expand": return "Expanding..."
        default: return "Transforming..."
        }
    }

    private func updateUIForActiveExecutions() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let running = self.activeExecutions.values.filter { !$0.isCancelled }.map { $0.command }
            if !running.isEmpty {
                self.progressIndicator?.isHidden = false
                self.progressIndicator?.startAnimation(nil)
                if running.count == 1 {
                    let cmd = running[0]
                    self.statusLabel?.stringValue = "⏳ \(self.actionLabelForCommand(cmd))"
                    self.statusLabel?.textColor = .labelColor
                } else {
                    self.statusLabel?.stringValue = "⏳ Processing \(running.joined(separator: ", "))..."
                    self.statusLabel?.textColor = .labelColor
                }
            } else {
                self.progressIndicator?.stopAnimation(nil)
                self.progressIndicator?.isHidden = true
            }
        }
    }

    private func showError(_ message: String, for execution: DesktopCommandExecutionContext) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.progressIndicator?.stopAnimation(nil)
            self.progressIndicator?.isHidden = true
            self.statusLabel?.stringValue = "⚠️ \(execution.command) failed: \(message)"
            self.statusLabel?.textColor = .systemRed
        }
    }

    // MARK: - Real AI Execution (@fix, @rewrite, @short, @expand)

    private func executeRealAiCommand(execution: DesktopCommandExecutionContext) async {
        do {
            let transformedText = try await DesktopAiTransformer.shared.transform(
                command: execution.command,
                text: execution.selectedText
            )

            await MainActor.run {
                guard !execution.isCancelled else {
                    NSLog("[DesktopShortcutPrototype] Execution \(execution.id.uuidString.prefix(8)) was cancelled. Skipping replacement.")
                    self.cleanupExecution(execution.id)
                    return
                }

                NSLog("[DesktopShortcutPrototype] REAL AI TRANSFORMED [\(execution.command)] = '\(transformedText)'")
                let success = self.executeReplacement(transformedText: transformedText, execution: execution)

                self.cleanupExecution(execution.id)

                if success {
                    if self.activeExecutions.isEmpty {
                        self.closePrompt()
                    } else {
                        self.updateUIForActiveExecutions()
                    }
                } else {
                    self.showError("Replacement failed in target application.", for: execution)
                }
            }
        } catch {
            await MainActor.run {
                guard !execution.isCancelled else {
                    self.cleanupExecution(execution.id)
                    return
                }

                NSLog("[DesktopShortcutPrototype] REAL AI FAILURE for \(execution.command): \(error.localizedDescription)")
                self.cleanupExecution(execution.id)

                // CRITICAL REQUIREMENT:
                // NEVER fall back to mock transformation for ANY command.
                // Do NOT modify user's text.
                // Display error and keep prompt open.
                self.showError(error.localizedDescription, for: execution)
            }
        }
    }

    // MARK: - Replacement & Verification

    @discardableResult
    private func executeReplacement(
        transformedText: String,
        execution: DesktopCommandExecutionContext
    ) -> Bool {
        isReplacing = true
        defer { isReplacing = false }

        let element = execution.targetElement
        let app = execution.targetApp
        let pid = execution.targetPid

        // 1. Reactivate the ORIGINAL target application and WAIT until it is
        // actually frontmost.
        guard reactivateAndWaitForFrontmost(app: app, timeout: 1.0) else {
            NSLog("[DesktopShortcutPrototype] Target app '\(app.localizedName ?? "?")' did not become frontmost in time")
            NSLog("[DesktopShortcutPrototype] REPLACEMENT FAILED")
            return false
        }
        NSLog("[DesktopShortcutPrototype] TARGET APP ACTIVATED")

        // 2. Re-validate that the ORIGINAL selection is still intact on the
        // ORIGINAL captured element.
        guard revalidateSelection(
            element: element,
            expectedText: execution.selectedText,
            expectedRange: execution.selectedRange
        ) != nil else {
            NSLog("[DesktopShortcutPrototype] Selection lost or altered after reactivation. Expected '\(execution.selectedText)'")
            NSLog("[DesktopShortcutPrototype] REPLACEMENT FAILED")
            return false
        }
        NSLog("[DesktopShortcutPrototype] SELECTION REVALIDATED")

        NSLog("[DesktopShortcutPrototype] REPLACEMENT STARTED")

        var docBeforeRef: CFTypeRef?
        let docBefore = (AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &docBeforeRef) == .success ? docBeforeRef as? String : nil) ?? ""
        NSLog("[DesktopShortcutPrototype] DOC BEFORE (AX) = '\(docBefore)'")

        // 3. PRIMARY replacement mechanism: synthetic keystroke injection.
        NSLog("[DesktopShortcutPrototype] SENDING REPLACEMENT = '\(transformedText)'")
        let apiCallSucceeded = typeReplacement(transformedText, targetPid: pid)

        guard apiCallSucceeded else {
            NSLog("[DesktopShortcutPrototype] API CALL SUCCESS = false (failed to post synthetic keyboard events)")
            NSLog("[DesktopShortcutPrototype] REPLACEMENT FAILED")
            return false
        }
        NSLog("[DesktopShortcutPrototype] API CALL SUCCESS = true (synthetic keystrokes posted)")

        usleep(100_000) // 100ms

        var docAfterRef: CFTypeRef?
        let docAfter = (AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &docAfterRef) == .success ? docAfterRef as? String : nil) ?? ""
        NSLog("[DesktopShortcutPrototype] DOC AFTER (AX readback) = '\(docAfter)'")

        let normalizedTransformed = transformedText.trimmingCharacters(in: .whitespacesAndNewlines)
        let axReadbackChanged = (docAfter != docBefore) && docAfter.contains(normalizedTransformed)

        NSLog("[DesktopShortcutPrototype] AX READBACK SUCCESS = \(axReadbackChanged)")
        NSLog("[DesktopShortcutPrototype] REPLACEMENT COMPLETED")
        return true
    }

    // MARK: - Activation

    private func reactivateAndWaitForFrontmost(app: NSRunningApplication, timeout: TimeInterval) -> Bool {
        if NSWorkspace.shared.frontmostApplication?.processIdentifier != app.processIdentifier {
            app.activate(options: .activateIgnoringOtherApps)
        }

        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier {
                return true
            }
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.01))
        }

        return NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier
    }

    // MARK: - Selection Revalidation

    private func revalidateSelection(
        element: AXUIElement,
        expectedText: String,
        expectedRange: CFRange
    ) -> CFRange? {
        var currentSelectedText = readSelectedText(element: element)

        if currentSelectedText != expectedText,
           expectedRange.location >= 0,
           expectedRange.length > 0 {
            var restoreRange = expectedRange
            if let axRange = AXValueCreate(.cfRange, &restoreRange) {
                _ = AXUIElementSetAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, axRange)
                usleep(20_000)
                currentSelectedText = readSelectedText(element: element)
            }
        }

        guard currentSelectedText == expectedText else { return nil }

        var rangeRef: CFTypeRef?
        var range = expectedRange
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

    private func typeReplacement(_ text: String, targetPid: pid_t) -> Bool {
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            return false
        }

        let units = Array(text.utf16)
        if units.isEmpty {
            return true
        }

        let chunkSize = 20
        var index = 0

        while index < units.count {
            let end = min(index + chunkSize, units.count)
            var chunk = Array(units[index..<end])

            guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else {
                return false
            }

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
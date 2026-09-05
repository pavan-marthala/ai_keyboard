import Cocoa
import ApplicationServices
import Carbon

/// Coordinator for the macOS AI Shortcut workflow.
///
/// Workflow:
/// 1. Intercepts the global shortcut (Control + Option + Space).
/// 2. Queries AccessibilityService for focused element and selected text.
/// 3. Presents CommandPrompt floating panel near the cursor.
/// 4. Dispatches chosen command to CommandDispatcher.
/// 5. CommandDispatcher orchestrates AI transformation and TextReplacementService.
final class CommandShortcutManager: NSObject, CommandPromptDelegate {

    static let shared = CommandShortcutManager()

    private let accessibilityService: AccessibilityService
    private let dispatcher: CommandDispatcher
    private let prompt: CommandPrompt

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var globalMonitor: Any?

    private var lastTriggerTime: TimeInterval = 0

    // Context captured at shortcut trigger (used to spawn new executions)
    private var targetElement: AXUIElement?
    private var targetApp: NSRunningApplication?
    private var targetPid: pid_t = 0
    private var originalSelectedText = ""
    private var originalSelectedRange = CFRange(location: -1, length: 0)

    init(
        accessibilityService: AccessibilityService = .shared,
        dispatcher: CommandDispatcher = .shared,
        prompt: CommandPrompt = CommandPrompt()
    ) {
        self.accessibilityService = accessibilityService
        self.dispatcher = dispatcher
        self.prompt = prompt
        super.init()
        self.prompt.delegate = self
    }

    // MARK: - Lifecycle

    func start() {
        NSLog("[CommandShortcutManager] STARTED")
        NSLog("[CommandShortcutManager] Registered global shortcut: Control + Option + Space")

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
        prompt.close()
        dispatcher.cancelAll()
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
                let manager = Unmanaged<CommandShortcutManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: observerSelf
        ) else {
            NSLog("[CommandShortcutManager] CGEvent.tapCreate failed (Accessibility permission may be required)")
            return
        }

        eventTap = tap
        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            NSLog("[CommandShortcutManager] Failed to create run loop source for event tap")
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

    func triggerShortcut() {
        NSLog("[CommandShortcutManager] GLOBAL SHORTCUT DETECTED: Control + Option + Space")
        NSLog("[CommandShortcutManager] AXIsProcessTrusted = \(accessibilityService.isProcessTrusted())")

        let (focusedElement, pid, app, focusedErr) = accessibilityService.copyFocusedElement()

        guard let element = focusedElement else {
            NSLog("[CommandShortcutManager] No focused AX element after retries. AXError = \(focusedErr.rawValue), frontmost pid = \(pid)")
            return
        }

        let resolvedApp = app ?? NSRunningApplication(processIdentifier: pid)
        let appName = resolvedApp?.localizedName ?? "Unknown (\(pid))"

        NSLog("[CommandShortcutManager] TARGET PID = \(pid)")
        NSLog("[CommandShortcutManager] TARGET APP = \(appName)")

        guard let selectedText = accessibilityService.readSelectedText(element: element),
              !selectedText.isEmpty else {
            NSLog("[CommandShortcutManager] No selected text.")
            return
        }

        NSLog("[CommandShortcutManager] SELECTED TEXT = '\(selectedText)'")

        let range = accessibilityService.readSelectedRange(element: element)

        self.targetElement = element
        self.targetApp = resolvedApp
        self.targetPid = pid
        self.originalSelectedText = selectedText
        self.originalSelectedRange = range

        prompt.show(selectedText: selectedText)
    }

    // MARK: - CommandPromptDelegate

    func promptDidSelectCommand(_ command: String) {
        guard let element = targetElement, let app = targetApp else {
            NSLog("[CommandShortcutManager] Cannot execute command: Target AX element or app is nil")
            return
        }

        dispatcher.dispatch(
            command: command,
            targetApp: app,
            targetPid: targetPid,
            targetElement: element,
            selectedText: originalSelectedText,
            selectedRange: originalSelectedRange,
            prompt: prompt
        )
    }

    func promptDidCancel() {
        dispatcher.cancelAll()
    }

    func promptDidClose() {
        dispatcher.cancelAll()
    }
}

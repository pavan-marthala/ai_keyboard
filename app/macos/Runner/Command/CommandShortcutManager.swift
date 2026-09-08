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

    private var isStarted = false

    // MARK: - Shortcut State
    private var currentEventHotKeyRef: EventHotKeyRef?
    private(set) var currentKey: String = "space"
    private(set) var currentModifiers: [String] = ["control", "option"]
    private(set) var currentKeyCode: CGKeyCode = 49
    private var hotKeyCounter: UInt32 = 1

    // MARK: - Lifecycle

    func start() {
        guard !isStarted else {
            NSLog("[CommandShortcutManager] Already started. Ignoring duplicate start request.")
            return
        }
        isStarted = true
        NSLog("[CommandShortcutManager] STARTED")

        if let saved = ConfigurationStore.shared.getShortcut(),
           registerShortcut(key: saved.key, modifiers: saved.modifiers, persist: false) {
            NSLog("[CommandShortcutManager] Restored saved shortcut: \(saved.modifiers.joined(separator: " + ")) + \(saved.key)")
        } else {
            _ = registerShortcut(key: "space", modifiers: ["control", "option"], persist: false)
            NSLog("[CommandShortcutManager] Registered default shortcut: Control + Option + Space")
        }

        setupEventTap()
        setupGlobalMonitor()
    }

    func stop() {
        isStarted = false
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
        if let ref = currentEventHotKeyRef {
            UnregisterEventHotKey(ref)
            currentEventHotKeyRef = nil
        }
        eventTap = nil
        runLoopSource = nil
        prompt.close()
        dispatcher.cancelAll()
    }

    // MARK: - Shortcut Registration & Mapping

    static func keyCode(forKeyName keyName: String) -> CGKeyCode? {
        let key = keyName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        switch key {
        case "a": return 0
        case "s": return 1
        case "d": return 2
        case "f": return 3
        case "h": return 4
        case "g": return 5
        case "z": return 6
        case "x": return 7
        case "c": return 8
        case "v": return 9
        case "b": return 11
        case "q": return 12
        case "w": return 13
        case "e": return 14
        case "r": return 15
        case "y": return 16
        case "t": return 17
        case "1": return 18
        case "2": return 19
        case "3": return 20
        case "4": return 21
        case "6": return 22
        case "5": return 23
        case "equal", "=": return 24
        case "9": return 25
        case "7": return 26
        case "minus", "-": return 27
        case "8": return 28
        case "0": return 29
        case "rightbracket", "]": return 30
        case "o": return 31
        case "u": return 32
        case "leftbracket", "[": return 33
        case "i": return 34
        case "p": return 35
        case "return", "enter": return 36
        case "l": return 37
        case "j": return 38
        case "quote", "'": return 39
        case "k": return 40
        case "semicolon", ";": return 41
        case "backslash", "\\": return 42
        case "comma", ",": return 43
        case "slash", "/": return 44
        case "n": return 45
        case "m": return 46
        case "period", ".": return 47
        case "tab": return 48
        case "space": return 49
        case "grave", "`": return 50
        case "backspace", "delete": return 51
        case "escape": return 53
        case "f1": return 122
        case "f2": return 120
        case "f3": return 99
        case "f4": return 118
        case "f5": return 96
        case "f6": return 97
        case "f7": return 98
        case "f8": return 100
        case "f9": return 101
        case "f10": return 109
        case "f11": return 103
        case "f12": return 111
        default: return nil
        }
    }

    static func carbonModifiers(for modifiers: [String]) -> UInt32 {
        var flags: UInt32 = 0
        for mod in modifiers {
            let m = mod.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            switch m {
            case "control", "ctrl":
                flags |= UInt32(controlKey)
            case "option", "alt":
                flags |= UInt32(optionKey)
            case "command", "cmd", "meta":
                flags |= UInt32(cmdKey)
            case "shift":
                flags |= UInt32(shiftKey)
            default:
                break
            }
        }
        return flags
    }

    func registerShortcut(key: String, modifiers: [String], persist: Bool = true) -> Bool {
        let cleanKey = key.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard let keyCode = CommandShortcutManager.keyCode(forKeyName: cleanKey) else {
            NSLog("[CommandShortcutManager] Unsupported key name: '\(key)'")
            return false
        }

        let cleanModifiers = modifiers.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
        guard !cleanModifiers.isEmpty else {
            NSLog("[CommandShortcutManager] Modifiers cannot be empty")
            return false
        }

        let carbonMods = CommandShortcutManager.carbonModifiers(for: cleanModifiers)

        // If the requested shortcut is already registered and active, avoid self-conflict
        if keyCode == currentKeyCode && cleanModifiers == currentModifiers && currentEventHotKeyRef != nil {
            if persist {
                ConfigurationStore.shared.saveShortcut(key: cleanKey, modifiers: cleanModifiers)
            }
            return true
        }

        // Attempt Carbon registration for conflict detection
        var candidateRef: EventHotKeyRef?
        hotKeyCounter += 1
        let hotKeyID = EventHotKeyID(signature: OSType(0x41544658), id: hotKeyCounter) // 'ATFX'
        let status = RegisterEventHotKey(
            UInt32(keyCode),
            carbonMods,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &candidateRef
        )

        if status != noErr {
            NSLog("[CommandShortcutManager] RegisterEventHotKey failed with OSStatus \(status). Shortcut is unavailable or reserved.")
            return false
        }

        // Unregister previous hotkey ref
        if let previousRef = currentEventHotKeyRef {
            UnregisterEventHotKey(previousRef)
            currentEventHotKeyRef = nil
        }

        currentEventHotKeyRef = candidateRef
        currentKey = cleanKey
        currentModifiers = cleanModifiers
        currentKeyCode = keyCode

        NSLog("[CommandShortcutManager] Successfully registered shortcut: \(cleanModifiers.joined(separator: " + ")) + \(cleanKey) (keyCode: \(keyCode))")

        if persist {
            ConfigurationStore.shared.saveShortcut(key: cleanKey, modifiers: cleanModifiers)
        }

        return true
    }

    func currentShortcutInfo() -> [String: Any] {
        return [
            "key": currentKey,
            "modifiers": currentModifiers
        ]
    }

    private func matchesModifiers(isControl: Bool, isOption: Bool, isCommand: Bool, isShift: Bool) -> Bool {
        let hasControl = currentModifiers.contains("control") || currentModifiers.contains("ctrl")
        let hasOption = currentModifiers.contains("option") || currentModifiers.contains("alt")
        let hasCommand = currentModifiers.contains("command") || currentModifiers.contains("cmd") || currentModifiers.contains("meta")
        let hasShift = currentModifiers.contains("shift")

        return isControl == hasControl &&
               isOption == hasOption &&
               isCommand == hasCommand &&
               isShift == hasShift
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
            let isShift = event.modifierFlags.contains(.shift)

            if event.keyCode == self.currentKeyCode &&
               self.matchesModifiers(isControl: isControl, isOption: isOption, isCommand: isCommand, isShift: isShift) {
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
        let isShift = flags.contains(.maskShift)
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))

        if keyCode == currentKeyCode &&
           matchesModifiers(isControl: isControl, isOption: isOption, isCommand: isCommand, isShift: isShift) {
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

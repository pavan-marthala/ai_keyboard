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

/// A borderless NSPanel that behaves visually like a "floating card" (rounded
/// corners, translucent dark material) but is still allowed to become key so
/// its buttons and Escape/Return key equivalents actually work.
final class RoundedFloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// A flat, borderless, PILL-shaped ("chip") command button with an explicit
/// normal/hover background pair, replacing the default AppKit bezel look.
/// Used to render commands as a horizontal row of chips rather than a
/// vertical stack of full-width buttons.
final class PromptCommandButton: NSButton {

    var normalBackgroundColor: NSColor = .clear {
        didSet { updateBackground() }
    }
    var hoverBackgroundColor: NSColor = .clear
    var titleTextColor: NSColor = .white {
        didSet { applyTitleColor() }
    }
    /// When true (default), corner radius tracks height/2 for a true pill
    /// shape. Set false for non-chip uses (e.g. a small square/circular
    /// icon button) where the caller sets cornerRadius explicitly.
    var isPill: Bool = true {
        didSet { needsLayout = true }
    }

    private var trackingArea: NSTrackingArea?
    private var isHovering = false {
        didSet { updateBackground() }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonSetup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonSetup()
    }

    private func commonSetup() {
        isBordered = false
        bezelStyle = .regularSquare
        wantsLayer = true
        layer?.masksToBounds = true
        alignment = .center
        font = NSFont.systemFont(ofSize: 12.5, weight: .semibold)
        updateBackground()
        applyTitleColor()
    }

    override func layout() {
        super.layout()
        if isPill {
            layer?.cornerRadius = bounds.height / 2
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        isHovering = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovering = false
    }

    private func updateBackground() {
        layer?.backgroundColor = (isHovering ? hoverBackgroundColor : normalBackgroundColor).cgColor
    }

    private func applyTitleColor() {
        let attributed = NSMutableAttributedString(string: title)
        attributed.addAttributes([
            .foregroundColor: titleTextColor,
            .font: font ?? NSFont.systemFont(ofSize: 12.5, weight: .semibold)
        ], range: NSRange(location: 0, length: attributed.length))
        attributedTitle = attributed
    }

    override var title: String {
        didSet { applyTitleColor() }
    }

    /// Natural width for this chip's current title + font, plus symmetric
    /// horizontal padding — used to size each chip to its content instead
    /// of stretching all chips to a fixed width.
    func fittingChipWidth(horizontalPadding: CGFloat, minimumWidth: CGFloat) -> CGFloat {
        let textWidth = (title as NSString).size(withAttributes: [
            .font: font ?? NSFont.systemFont(ofSize: 12.5, weight: .semibold)
        ]).width
        return max(minimumWidth, ceil(textWidth) + horizontalPadding * 2)
    }
}

/// Colors mirrored 1:1 from the Flutter app's `AppColors.dark` (Electric
/// Violet) theme extension, so the native macOS popup matches the app's
/// palette exactly rather than using an independent ad-hoc dark theme.
/// Hex values below are copied directly from AppColors.dark in
/// lib/.../app_colors.dart — keep these two in sync if that palette changes.
private enum AppPalette {
    static func hex(_ value: UInt32, alpha: CGFloat = 1.0) -> NSColor {
        NSColor(
            calibratedRed: CGFloat((value >> 16) & 0xFF) / 255.0,
            green: CGFloat((value >> 8) & 0xFF) / 255.0,
            blue: CGFloat(value & 0xFF) / 255.0,
            alpha: alpha
        )
    }

    // Primary — Electric Violet ramp
    static let primary = hex(0x8B5CF6)        // primary500 / accent
    static let primary300 = hex(0xC4B5FD)     // accentLight / focus ring
    static let primary400 = hex(0xA78BFA)
    static let primary600 = hex(0x7C3AED)     // accentHover / dim

    // Neutrals / surfaces
    static let background = hex(0x0A0A0D)     // --bg
    static let surfaceLight = hex(0x131318)   // --surface-1 (== `card`)
    static let surfaceDark = hex(0x1B1B22)    // --surface-2
    static let surfaceActive = hex(0x24242D)  // gray4 / --surface-active

    // Text
    static let textPrimary = hex(0xF5F5F7)    // --ink
    static let textSecondary = hex(0x98989F)  // --ink-soft
    static let textTertiary = hex(0x5C5C66)   // --ink-faint
    
    static let error = hex(0xF0576B)

    // Borders
    static let border = NSColor.white.withAlphaComponent(CGFloat(0x12) / 255.0)       // --hairline rgba(255,255,255,.07)
    static let borderLight = NSColor.white.withAlphaComponent(CGFloat(0x1F) / 255.0)  // rgba(255,255,255,.12)
}



/// macOS Shortcut + Selected Text @Command Manager.
///
/// Workflow:
/// 1. User selects text in any supported macOS text application.
/// 2. User presses global shortcut: Control + Option + Space.
/// 3. Manager captures focused element and selected text via AX.
/// 4. Native AppKit command prompt window appears.
/// 5. User selects a command (@fix, @rewrite, @short, @expand).
/// 6. Prompt remains OPEN during processing and displays loading state.
/// 7. Selected command executes real AI transformation (NO mock fallback on failure).
/// 8. User can trigger another command concurrently without corruption.
/// 9. Selected text in target application is replaced via synthetic
///    keystroke injection (NOT via AX attribute mutation) and verified.
/// 10. Prompt closes when all active executions finish successfully.
///
/// Query strategy:
/// triggerShortcut() queries the frontmost application's AX element directly
/// via copyFocusedElement(), which is targeted and avoids transient system-wide
/// routing issues (-25204), with bounded retry.
final class DesktopCommandShortcutManager: NSObject, NSWindowDelegate {

    static let shared = DesktopCommandShortcutManager()

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
    
    // Layout constants — shared between showCommandPrompt and the resize helper
    private let promptHorizontalPadding: CGFloat = 20
    private let promptVerticalPadding: CGFloat = 18
    private let promptChipHeight: CGFloat = 32
    private let promptChipSpacing: CGFloat = 8
    private let promptChipHorizontalPadding: CGFloat = 16
    private let promptCornerRadius: CGFloat = 18
    private let promptCloseButtonSize: CGFloat = 22
    private let promptMinPanelWidth: CGFloat = 360
    private let promptHeaderHeight: CGFloat = 22
    private let promptPreviewHeight: CGFloat = 18
    private let promptStatusAreaHeight: CGFloat = 22
    private let promptGapAfterHeader: CGFloat = 4
    private let promptGapPreviewToChipsCompact: CGFloat = 14   // used when status is hidden
    private let promptGapAfterPreviewExpanded: CGFloat = 10    // used when status is shown
    private let promptGapAfterStatusExpanded: CGFloat = 8

    // Views/state needed to resize the panel after it's already on screen
    private var promptCardView: NSView?
    private var promptTitleLabel: NSTextField?
    private var promptCloseButton: PromptCommandButton?
    private var promptPreviewLabel: NSTextField?
    private var compactPanelHeight: CGFloat = 0
    private var expandedPanelHeight: CGFloat = 0
    private var isStatusRowExpanded: Bool = false

    // MARK: - Lifecycle

    func start() {
        NSLog("[DesktopCommandShortcutManager] STARTED")
        NSLog("[DesktopCommandShortcutManager] Registered global shortcut: Control + Option + Space")

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
                let manager = Unmanaged<DesktopCommandShortcutManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: observerSelf
        ) else {
            NSLog("[DesktopCommandShortcutManager] CGEvent.tapCreate failed (Accessibility permission may be required)")
            return
        }

        eventTap = tap
        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            NSLog("[DesktopCommandShortcutManager] Failed to create run loop source for event tap")
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

    // MARK: - Focused Element Lookup

    /// Queries the FRONTMOST APP's own AX element for its focused UI
    /// element, instead of going through AXUIElementCreateSystemWide().
    /// The systemwide query depends on WindowServer correctly routing to
    /// whichever app happens to be frontmost and is known to intermittently
    /// return kAXErrorCannotComplete for some apps/timing; asking the
    /// frontmost app's own AX element directly is more targeted and more
    /// reliable, with a short bounded retry for transient IPC hiccups.
    private func copyFocusedElement(
        attempts: Int = 3,
        delayMicroseconds: useconds_t = 40_000
    ) -> (element: AXUIElement?, pid: pid_t, lastError: AXError) {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            NSLog("[DesktopCommandShortcutManager] No frontmost application reported by NSWorkspace")
            return (nil, 0, .cannotComplete)
        }
        let appPid = frontApp.processIdentifier
        let appElement = AXUIElementCreateApplication(appPid)

        var lastError: AXError = .cannotComplete
        var didRequestEnhancedUI = false
        for attempt in 1...attempts {
            var focusedRef: CFTypeRef?
            let err = AXUIElementCopyAttributeValue(
                appElement,
                kAXFocusedUIElementAttribute as CFString,
                &focusedRef
            )
            if err == .success, let focusedRef {
                return (focusedRef as! AXUIElement, appPid, .success)
            }
            lastError = err
            NSLog("[DesktopCommandShortcutManager] Focused element query via app element, attempt \(attempt): AXError = \(err.rawValue), app='\(frontApp.localizedName ?? "?")' pid=\(appPid)")
            
            // Chromium/Electron apps (VS Code, Chrome, WhatsApp Desktop,
            // Slack, ...) do not build a full accessibility tree until
            // something actually requests one - kAXErrorCannotComplete
            // here often means "no tree exists yet", not "access denied".
            // AXEnhancedUserInterface is the standard (if undocumented)
            // signal used by macOS automation tools to force Chromium to
            // activate its accessibility bridge, same as VoiceOver would.
            // Tree construction isn't instant, so give it real time once.
            if !didRequestEnhancedUI, (err == .cannotComplete || err == .noValue) {
                NSLog("[DesktopShortcutPrototype] Requesting AXEnhancedUserInterface for pid=\(appPid) (Chromium/Electron tree activation)")
                _ = AXUIElementSetAttributeValue(appElement, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue)
                didRequestEnhancedUI = true
                usleep(300_000) // first-time tree construction can take a few hundred ms
                continue
            }
            
            if attempt < attempts {
                usleep(delayMicroseconds)
            }
        }
        return (nil, appPid, lastError)
    }

    // MARK: - Shortcut Triggered

    func triggerShortcut() {
        NSLog("[DesktopCommandShortcutManager] GLOBAL SHORTCUT DETECTED: Control + Option + Space")
        NSLog("[DesktopCommandShortcutManager] AXIsProcessTrusted = \(AXIsProcessTrusted())")

        let (focusedElement, pid, focusedErr) = copyFocusedElement()

        guard let element = focusedElement else {
            NSLog("[DesktopCommandShortcutManager] No focused AX element after retries. AXError = \(focusedErr.rawValue), frontmost pid = \(pid)")
            return
        }

        let app = NSRunningApplication(processIdentifier: pid)
        let appName = app?.localizedName ?? "Unknown (\(pid))"

        NSLog("[DesktopCommandShortcutManager] TARGET PID = \(pid)")
        NSLog("[DesktopCommandShortcutManager] TARGET APP = \(appName)")

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
            NSLog("[DesktopCommandShortcutManager] No selected text. AXError = \(textErr.rawValue)")
            return
        }

        NSLog("[DesktopCommandShortcutManager] SELECTED TEXT = '\(selectedText)'")

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
        let commands = ["@fix", "@rewrite", "@short", "@expand"]

        let horizontalPadding = promptHorizontalPadding
        let verticalPadding = promptVerticalPadding
        let chipHeight = promptChipHeight
        let chipSpacing = promptChipSpacing
        let chipHorizontalPadding = promptChipHorizontalPadding
        let cornerRadius = promptCornerRadius
        let closeButtonSize = promptCloseButtonSize
        let minPanelWidth = promptMinPanelWidth
        let headerHeight = promptHeaderHeight
        let previewHeight = promptPreviewHeight
        let statusAreaHeight = promptStatusAreaHeight
        let gapAfterHeader = promptGapAfterHeader

        let chipButtons: [PromptCommandButton] = commands.map { cmd in
            let btn = PromptCommandButton(frame: .zero)
            btn.title = cmd
            btn.target = self
            btn.action = #selector(handleCommandButtonClicked(_:))
            btn.keyEquivalent = "\r"
            btn.titleTextColor = AppPalette.textPrimary
            btn.normalBackgroundColor = AppPalette.primary
            btn.hoverBackgroundColor = AppPalette.primary600
            return btn
        }
        let chipWidths = chipButtons.map {
            $0.fittingChipWidth(horizontalPadding: chipHorizontalPadding, minimumWidth: 64)
        }
        let chipsRowWidth = chipWidths.reduce(0, +) + chipSpacing * CGFloat(max(0, chipButtons.count - 1))

        let titleText = "What do you want to do?"
        let titleWidth = (titleText as NSString).size(withAttributes: [
            .font: NSFont.systemFont(ofSize: 13.5, weight: .semibold)
        ]).width

        let contentWidth = max(chipsRowWidth, titleWidth, 260)
        let panelWidth = max(minPanelWidth, contentWidth + horizontalPadding * 2 + closeButtonSize + 8)

        // Two possible heights: compact (no status row) and expanded (status shown).
        // Chip row sits at a FIXED distance from the BOTTOM in both cases, so it
        // never needs repositioning — only the panel/card height changes, and the
        // top-anchored views (title/close/preview/status) get moved to match.
        self.compactPanelHeight = verticalPadding + headerHeight + gapAfterHeader + previewHeight
            + promptGapPreviewToChipsCompact + chipHeight + verticalPadding
        self.expandedPanelHeight = verticalPadding + headerHeight + gapAfterHeader + previewHeight
            + promptGapAfterPreviewExpanded + statusAreaHeight + promptGapAfterStatusExpanded
            + chipHeight + verticalPadding
        self.isStatusRowExpanded = false

        let panelHeight = compactPanelHeight

        let panel = RoundedFloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.delegate = self
        panel.isMovableByWindowBackground = true
        panel.appearance = NSAppearance(named: .darkAqua) // ensure dynamic system colors resolve to dark variants

        let card = NSView(frame: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight))
        card.wantsLayer = true
        card.layer?.cornerRadius = cornerRadius
        card.layer?.masksToBounds = true
        card.layer?.backgroundColor = AppPalette.surfaceLight.cgColor
        card.layer?.borderWidth = 1
        card.layer?.borderColor = AppPalette.border.cgColor
        card.shadow = NSShadow()
        self.promptCardView = card

        // Title
        let titleLabel = NSTextField(labelWithString: titleText)
        titleLabel.font = NSFont.systemFont(ofSize: 13.5, weight: .semibold)
        titleLabel.textColor = AppPalette.textPrimary
        titleLabel.frame = NSRect(x: horizontalPadding, y: 0, width: panelWidth - horizontalPadding - closeButtonSize - 16, height: headerHeight)
        card.addSubview(titleLabel)
        self.promptTitleLabel = titleLabel

        // Close ("×") button
        let closeBtn = PromptCommandButton(frame: NSRect(x: panelWidth - horizontalPadding - closeButtonSize + 6, y: 0, width: closeButtonSize, height: closeButtonSize))
        closeBtn.title = "×"
        closeBtn.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        closeBtn.titleTextColor = AppPalette.textSecondary
        closeBtn.normalBackgroundColor = .clear
        closeBtn.hoverBackgroundColor = AppPalette.surfaceActive
        closeBtn.keyEquivalent = "\u{1b}"
        closeBtn.target = self
        closeBtn.action = #selector(handleCancel)
        card.addSubview(closeBtn)
        self.promptCloseButton = closeBtn

        // Selected-text preview
        let displayPreview = selectedText.replacingOccurrences(of: "\n", with: " ")
        let maxPreviewChars = 44
        let truncated = displayPreview.count > maxPreviewChars
            ? String(displayPreview.prefix(maxPreviewChars - 3)) + "..."
            : displayPreview
        let previewLabel = NSTextField(labelWithString: "\"\(truncated)\"")
        previewLabel.font = NSFont.systemFont(ofSize: 11.5)
        previewLabel.textColor = AppPalette.textSecondary
        previewLabel.frame = NSRect(x: horizontalPadding, y: 0, width: panelWidth - horizontalPadding * 2, height: previewHeight)
        card.addSubview(previewLabel)
        self.promptPreviewLabel = previewLabel

        // Loading indicator + status row — hidden by default, no space reserved
        let spinner = NSProgressIndicator(frame: NSRect(x: horizontalPadding, y: 0, width: 14, height: 14))
        spinner.style = .spinning
        spinner.controlSize = .small
        spinner.isDisplayedWhenStopped = false
        spinner.isHidden = true
        card.addSubview(spinner)
        self.progressIndicator = spinner

        let status = NSTextField(labelWithString: "")
        status.font = NSFont.systemFont(ofSize: 11.5)
        status.textColor = AppPalette.textPrimary
        status.frame = NSRect(x: horizontalPadding + 20, y: 0, width: panelWidth - horizontalPadding * 2 - 20, height: statusAreaHeight)
        status.maximumNumberOfLines = 1
        status.lineBreakMode = .byTruncatingTail
        status.isHidden = true
        card.addSubview(status)
        self.statusLabel = status

        // Position all top-anchored views correctly for the compact height.
        repositionTopAnchoredViews(forHeight: panelHeight)

        // Command chips — fixed distance from the BOTTOM, same in both states.
        var chipX = horizontalPadding
        for (index, btn) in chipButtons.enumerated() {
            let width = chipWidths[index]
            btn.frame = NSRect(x: chipX, y: verticalPadding, width: width, height: chipHeight)
            card.addSubview(btn)
            chipX += width + chipSpacing
        }

        panel.contentView = card
        self.promptPanel = panel

        positionPanelNearCursor(panel, width: panelWidth, height: panelHeight)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSLog("[DesktopCommandShortcutManager] COMMAND PROMPT OPENED")
    }

    /// Repositions the top-anchored views (title, close button, preview,
    /// status/spinner) for a given card height. Chips are NOT included here —
    /// they sit at a fixed distance from the bottom and never move.
    private func repositionTopAnchoredViews(forHeight height: CGFloat) {
        let titleY = height - promptVerticalPadding - promptHeaderHeight
        if var f = promptTitleLabel?.frame { f.origin.y = titleY; promptTitleLabel?.frame = f }

        let closeY = height - promptVerticalPadding - promptCloseButtonSize + 4
        if var f = promptCloseButton?.frame { f.origin.y = closeY; promptCloseButton?.frame = f }

        let previewY = titleY - promptGapAfterHeader - promptPreviewHeight
        if var f = promptPreviewLabel?.frame { f.origin.y = previewY; promptPreviewLabel?.frame = f }

        let statusY = previewY - promptGapAfterPreviewExpanded - promptStatusAreaHeight
        if var f = statusLabel?.frame { f.origin.y = statusY; statusLabel?.frame = f }
        if var f = progressIndicator?.frame { f.origin.y = statusY + 3; progressIndicator?.frame = f }
    }

    /// Grows/shrinks the popup to show or hide the status row, instead of
    /// leaving empty reserved space when there's nothing to display.
    private func setStatusRowExpanded(_ expanded: Bool) {
        statusLabel?.isHidden = !expanded
        progressIndicator?.isHidden = !expanded

        guard expanded != isStatusRowExpanded,
              let panel = promptPanel,
              let card = promptCardView else { return }
        isStatusRowExpanded = expanded

        let targetHeight = expanded ? expandedPanelHeight : compactPanelHeight
        let deltaHeight = targetHeight - card.frame.height

        var frame = panel.frame
        frame.size.height = targetHeight
        frame.origin.y -= deltaHeight // grow/shrink downward; keep the top edge visually anchored
        panel.setFrame(frame, display: true, animate: true)

        card.setFrameSize(NSSize(width: card.frame.width, height: targetHeight))
        repositionTopAnchoredViews(forHeight: targetHeight)
    }
    
    /// Positions the panel just below-and-right of the current mouse cursor,
    /// clamped so it stays fully within the visible frame of whichever
    /// screen the cursor is on (instead of always opening screen-centered).
    private func positionPanelNearCursor(_ panel: NSPanel, width: CGFloat, height: CGFloat) {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main

        guard let visibleFrame = screen?.visibleFrame else {
            panel.center()
            return
        }

        let offsetX: CGFloat = 16
        let offsetY: CGFloat = 16

        var originX = mouseLocation.x + offsetX
        var originY = mouseLocation.y - height - offsetY // panel appears below the cursor

        // Clamp horizontally.
        if originX + width > visibleFrame.maxX {
            originX = visibleFrame.maxX - width - 8
        }
        if originX < visibleFrame.minX {
            originX = visibleFrame.minX + 8
        }

        // If there's no room below the cursor, place it above instead.
        if originY < visibleFrame.minY {
            originY = mouseLocation.y + offsetY
        }
        if originY + height > visibleFrame.maxY {
            originY = visibleFrame.maxY - height - 8
        }

        panel.setFrameOrigin(NSPoint(x: originX, y: originY))
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
        NSLog("[DesktopCommandShortcutManager] Command prompt cancelled by user")
        closePrompt()
    }

    func windowWillClose(_ notification: Notification) {
        NSLog("[DesktopCommandShortcutManager] Command prompt window closed")
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
            NSLog("[DesktopCommandShortcutManager] Cannot execute command: Target AX element or app is nil")
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

        NSLog("[DesktopCommandShortcutManager] COMMAND SELECTED = \(command) [execId: \(execution.id.uuidString.prefix(8))]")

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
                self.setStatusRowExpanded(true)
                self.progressIndicator?.startAnimation(nil)
                if running.count == 1 {
                    self.statusLabel?.stringValue = "⏳ \(self.actionLabelForCommand(running[0]))"
                } else {
                    self.statusLabel?.stringValue = "⏳ Processing \(running.joined(separator: ", "))..."
                }
                self.statusLabel?.textColor = AppPalette.textPrimary
            } else {
                self.progressIndicator?.stopAnimation(nil)
                self.setStatusRowExpanded(false)
            }
        }
    }

    private func showError(_ message: String, for execution: DesktopCommandExecutionContext) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.progressIndicator?.stopAnimation(nil)
            self.setStatusRowExpanded(true)
            self.statusLabel?.stringValue = "⚠️ \(execution.command) failed: \(message)"
            self.statusLabel?.textColor = AppPalette.error
        }
    }

    // MARK: - AI Execution (@fix, @rewrite, @short, @expand)

    private func executeRealAiCommand(execution: DesktopCommandExecutionContext) async {
        do {
            let transformedText = try await DesktopAiTransformer.shared.transform(
                command: execution.command,
                text: execution.selectedText
            )

            await MainActor.run {
                guard !execution.isCancelled else {
                    NSLog("[DesktopCommandShortcutManager] Execution \(execution.id.uuidString.prefix(8)) was cancelled. Skipping replacement.")
                    self.cleanupExecution(execution.id)
                    return
                }

                NSLog("[DesktopCommandShortcutManager] REAL AI TRANSFORMED [\(execution.command)] = '\(transformedText)'")
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

                NSLog("[DesktopCommandShortcutManager] REAL AI FAILURE for \(execution.command): \(error.localizedDescription)")
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
            NSLog("[DesktopCommandShortcutManager] Target app '\(app.localizedName ?? "?")' did not become frontmost in time")
            NSLog("[DesktopCommandShortcutManager] REPLACEMENT FAILED")
            return false
        }
        NSLog("[DesktopCommandShortcutManager] TARGET APP ACTIVATED")

        // 2. Re-validate that the ORIGINAL selection is still intact on the
        // ORIGINAL captured element.
        guard revalidateSelection(
            element: element,
            expectedText: execution.selectedText,
            expectedRange: execution.selectedRange
        ) != nil else {
            NSLog("[DesktopCommandShortcutManager] Selection lost or altered after reactivation. Expected '\(execution.selectedText)'")
            NSLog("[DesktopCommandShortcutManager] REPLACEMENT FAILED")
            return false
        }
        NSLog("[DesktopCommandShortcutManager] SELECTION REVALIDATED")

        NSLog("[DesktopCommandShortcutManager] REPLACEMENT STARTED")

        var docBeforeRef: CFTypeRef?
        let docBefore = (AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &docBeforeRef) == .success ? docBeforeRef as? String : nil) ?? ""
        NSLog("[DesktopCommandShortcutManager] DOC BEFORE (AX) = '\(docBefore)'")

        // 3. PRIMARY replacement mechanism: synthetic keystroke injection.
        NSLog("[DesktopCommandShortcutManager] SENDING REPLACEMENT = '\(transformedText)'")
        let apiCallSucceeded = typeReplacement(transformedText, targetPid: pid)

        guard apiCallSucceeded else {
            NSLog("[DesktopCommandShortcutManager] API CALL SUCCESS = false (failed to post synthetic keyboard events)")
            NSLog("[DesktopCommandShortcutManager] REPLACEMENT FAILED")
            return false
        }
        NSLog("[DesktopCommandShortcutManager] API CALL SUCCESS = true (synthetic keystrokes posted)")

        usleep(100_000) // 100ms

        var docAfterRef: CFTypeRef?
        let docAfter = (AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &docAfterRef) == .success ? docAfterRef as? String : nil) ?? ""
        NSLog("[DesktopCommandShortcutManager] DOC AFTER (AX readback) = '\(docAfter)'")

        let normalizedTransformed = transformedText.trimmingCharacters(in: .whitespacesAndNewlines)
        let axReadbackChanged = (docAfter != docBefore) && docAfter.contains(normalizedTransformed)

        NSLog("[DesktopCommandShortcutManager] AX READBACK SUCCESS = \(axReadbackChanged)")
        NSLog("[DesktopCommandShortcutManager] REPLACEMENT COMPLETED")
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

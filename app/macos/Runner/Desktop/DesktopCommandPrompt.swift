import Cocoa

/// Delegate protocol for DesktopCommandPrompt user interactions and lifecycle events.
protocol DesktopCommandPromptDelegate: AnyObject {
    func promptDidSelectCommand(_ command: String)
    func promptDidCancel()
    func promptDidClose()
}

/// A borderless NSPanel that behaves visually like a "floating card" (rounded
/// corners, translucent dark material) but is still allowed to become key so
/// its buttons and Escape/Return key equivalents work.
final class RoundedFloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// A flat, borderless, PILL-shaped ("chip") command button with an explicit
/// normal/hover background pair.
final class PromptCommandButton: NSButton {

    var normalBackgroundColor: NSColor = .clear {
        didSet { updateBackground() }
    }
    var hoverBackgroundColor: NSColor = .clear
    var titleTextColor: NSColor = .white {
        didSet { applyTitleColor() }
    }
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

    func fittingChipWidth(horizontalPadding: CGFloat, minimumWidth: CGFloat) -> CGFloat {
        let textWidth = (title as NSString).size(withAttributes: [
            .font: font ?? NSFont.systemFont(ofSize: 12.5, weight: .semibold)
        ]).width
        return max(minimumWidth, ceil(textWidth) + horizontalPadding * 2)
    }
}

/// Colors mirrored 1:1 from the Flutter app's `AppColors.dark` (Electric Violet) theme.
enum AppPalette {
    static func hex(_ value: UInt32, alpha: CGFloat = 1.0) -> NSColor {
        NSColor(
            calibratedRed: CGFloat((value >> 16) & 0xFF) / 255.0,
            green: CGFloat((value >> 8) & 0xFF) / 255.0,
            blue: CGFloat(value & 0xFF) / 255.0,
            alpha: alpha
        )
    }

    static let primary = hex(0x8B5CF6)
    static let primary300 = hex(0xC4B5FD)
    static let primary400 = hex(0xA78BFA)
    static let primary600 = hex(0x7C3AED)

    static let background = hex(0x0A0A0D)
    static let surfaceLight = hex(0x131318)
    static let surfaceDark = hex(0x1B1B22)
    static let surfaceActive = hex(0x24242D)

    static let textPrimary = hex(0xF5F5F7)
    static let textSecondary = hex(0x98989F)
    static let textTertiary = hex(0x5C5C66)

    static let error = hex(0xF0576B)

    static let border = NSColor.white.withAlphaComponent(CGFloat(0x12) / 255.0)
    static let borderLight = NSColor.white.withAlphaComponent(CGFloat(0x1F) / 255.0)
}

/// Native AppKit floating command prompt window.
final class DesktopCommandPrompt: NSObject, NSWindowDelegate {

    weak var delegate: DesktopCommandPromptDelegate?

    private var promptPanel: NSPanel?
    private var promptCardView: NSView?
    private var promptTitleLabel: NSTextField?
    private var promptCloseButton: PromptCommandButton?
    private var promptPreviewLabel: NSTextField?
    private var statusLabel: NSTextField?
    private var progressIndicator: NSProgressIndicator?

    // Layout constants
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
    private let promptGapPreviewToChipsCompact: CGFloat = 14
    private let promptGapAfterPreviewExpanded: CGFloat = 10
    private let promptGapAfterStatusExpanded: CGFloat = 8

    private var compactPanelHeight: CGFloat = 0
    private var expandedPanelHeight: CGFloat = 0
    private var isStatusRowExpanded: Bool = false

    var isVisible: Bool {
        return promptPanel != nil && promptPanel?.isVisible == true
    }

    // MARK: - Presentation

    func show(selectedText: String) {
        close()
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

        compactPanelHeight = verticalPadding + headerHeight + gapAfterHeader + previewHeight
            + promptGapPreviewToChipsCompact + chipHeight + verticalPadding
        expandedPanelHeight = verticalPadding + headerHeight + gapAfterHeader + previewHeight
            + promptGapAfterPreviewExpanded + statusAreaHeight + promptGapAfterStatusExpanded
            + chipHeight + verticalPadding
        isStatusRowExpanded = false

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
        panel.appearance = NSAppearance(named: .darkAqua)

        let card = NSView(frame: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight))
        card.wantsLayer = true
        card.layer?.cornerRadius = cornerRadius
        card.layer?.masksToBounds = true
        card.layer?.backgroundColor = AppPalette.surfaceLight.cgColor
        card.layer?.borderWidth = 1
        card.layer?.borderColor = AppPalette.border.cgColor
        card.shadow = NSShadow()
        promptCardView = card

        // Title
        let titleLabel = NSTextField(labelWithString: titleText)
        titleLabel.font = NSFont.systemFont(ofSize: 13.5, weight: .semibold)
        titleLabel.textColor = AppPalette.textPrimary
        titleLabel.frame = NSRect(x: horizontalPadding, y: 0, width: panelWidth - horizontalPadding - closeButtonSize - 16, height: headerHeight)
        card.addSubview(titleLabel)
        promptTitleLabel = titleLabel

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
        promptCloseButton = closeBtn

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
        promptPreviewLabel = previewLabel

        // Loading spinner
        let spinner = NSProgressIndicator(frame: NSRect(x: horizontalPadding, y: 0, width: 14, height: 14))
        spinner.style = .spinning
        spinner.controlSize = .small
        spinner.isDisplayedWhenStopped = false
        spinner.isHidden = true
        card.addSubview(spinner)
        progressIndicator = spinner

        // Status label
        let status = NSTextField(labelWithString: "")
        status.font = NSFont.systemFont(ofSize: 11.5)
        status.textColor = AppPalette.textPrimary
        status.frame = NSRect(x: horizontalPadding + 20, y: 0, width: panelWidth - horizontalPadding * 2 - 20, height: statusAreaHeight)
        status.maximumNumberOfLines = 1
        status.lineBreakMode = .byTruncatingTail
        status.isHidden = true
        card.addSubview(status)
        statusLabel = status

        repositionTopAnchoredViews(forHeight: panelHeight)

        // Command chips (anchored from bottom)
        var chipX = horizontalPadding
        for (index, btn) in chipButtons.enumerated() {
            let width = chipWidths[index]
            btn.frame = NSRect(x: chipX, y: verticalPadding, width: width, height: chipHeight)
            card.addSubview(btn)
            chipX += width + chipSpacing
        }

        panel.contentView = card
        promptPanel = panel

        positionPanelNearCursor(panel, width: panelWidth, height: panelHeight)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSLog("[DesktopCommandPrompt] COMMAND PROMPT OPENED")
    }

    func close() {
        if let panel = promptPanel {
            panel.delegate = nil
            panel.orderOut(nil)
            promptPanel = nil
        }
        promptCardView = nil
        promptTitleLabel = nil
        promptCloseButton = nil
        promptPreviewLabel = nil
        statusLabel = nil
        progressIndicator = nil
    }

    // MARK: - Dynamic State & Layout

    func updateLoadingState(runningCommands: [String]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if !runningCommands.isEmpty {
                self.setStatusRowExpanded(true)
                self.progressIndicator?.startAnimation(nil)
                if runningCommands.count == 1 {
                    self.statusLabel?.stringValue = "⏳ \(self.actionLabelForCommand(runningCommands[0]))"
                } else {
                    self.statusLabel?.stringValue = "⏳ Processing \(runningCommands.joined(separator: ", "))..."
                }
                self.statusLabel?.textColor = AppPalette.textPrimary
            } else {
                self.progressIndicator?.stopAnimation(nil)
                self.setStatusRowExpanded(false)
            }
        }
    }

    func showError(command: String, message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.progressIndicator?.stopAnimation(nil)
            self.setStatusRowExpanded(true)
            self.statusLabel?.stringValue = "⚠️ \(command) failed: \(message)"
            self.statusLabel?.textColor = AppPalette.error
        }
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
        frame.origin.y -= deltaHeight
        panel.setFrame(frame, display: true, animate: true)

        card.setFrameSize(NSSize(width: card.frame.width, height: targetHeight))
        repositionTopAnchoredViews(forHeight: targetHeight)
    }

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
        var originY = mouseLocation.y - height - offsetY

        if originX + width > visibleFrame.maxX {
            originX = visibleFrame.maxX - width - 8
        }
        if originX < visibleFrame.minX {
            originX = visibleFrame.minX + 8
        }

        if originY < visibleFrame.minY {
            originY = mouseLocation.y + offsetY
        }
        if originY + height > visibleFrame.maxY {
            originY = visibleFrame.maxY - height - 8
        }

        panel.setFrameOrigin(NSPoint(x: originX, y: originY))
    }

    // MARK: - Actions & Delegate

    @objc private func handleCommandButtonClicked(_ sender: NSButton) {
        delegate?.promptDidSelectCommand(sender.title)
    }

    @objc private func handleCancel() {
        NSLog("[DesktopCommandPrompt] Command prompt cancelled by user")
        delegate?.promptDidCancel()
        close()
    }

    func windowWillClose(_ notification: Notification) {
        NSLog("[DesktopCommandPrompt] Command prompt window closed")
        delegate?.promptDidClose()
        promptPanel = nil
        promptCardView = nil
        promptTitleLabel = nil
        promptCloseButton = nil
        promptPreviewLabel = nil
        statusLabel = nil
        progressIndicator = nil
    }
}

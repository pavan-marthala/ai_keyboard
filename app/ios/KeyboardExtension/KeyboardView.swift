import UIKit

class KeyboardView: UIView {
    private var controller: KeyboardController?
    private var theme: KeyboardTheme

    private var isSymbolPanel = false

    private let statusLabel = UILabel()
    private let toolbarScrollView = UIScrollView()
    private let toolbarStack = UIStackView()
    private let mainContainerStack = UIStackView()

    private let qwertyPanel = UIStackView()
    private let symbolPanel = UIStackView()

    private var letterKeyButtons: [KeyboardKeyButton] = []
    private var shiftKeyButton: KeyboardKeyButton?

    init(theme: KeyboardTheme) {
        self.theme = theme
        super.init(frame: .zero)
        backgroundColor = theme.backgroundColor
        translatesAutoresizingMaskIntoConstraints = false
        setupUi()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(controller: KeyboardController) {
        self.controller = controller
        controller.onStatusUpdate = { [weak self] status in
            DispatchQueue.main.async {
                self?.statusLabel.text = status
            }
        }
        controller.onShiftStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                self?.updateShiftStateUi(state)
            }
        }
        buildToolbarButtons()
    }

    func updateTheme(_ theme: KeyboardTheme) {
        self.theme = theme
        backgroundColor = theme.backgroundColor
        toolbarScrollView.backgroundColor = theme.toolbarColor
        statusLabel.textColor = theme.accentColor
        renderPanels()
    }

    private func setupUi() {
        // AI Toolbar ScrollView
        toolbarScrollView.showsHorizontalScrollIndicator = false
        toolbarScrollView.backgroundColor = theme.toolbarColor
        toolbarScrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(toolbarScrollView)

        toolbarStack.axis = .horizontal
        toolbarStack.spacing = 8
        toolbarStack.alignment = .center
        toolbarStack.translatesAutoresizingMaskIntoConstraints = false
        toolbarScrollView.addSubview(toolbarStack)

        statusLabel.text = "✨ AtFIx"
        statusLabel.font = .boldSystemFont(ofSize: 13)
        statusLabel.textColor = theme.accentColor
        statusLabel.accessibilityLabel = "AtFIx Status"
        toolbarStack.addArrangedSubview(statusLabel)

        // Main Container Stack
        mainContainerStack.axis = .vertical
        mainContainerStack.spacing = 6
        mainContainerStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainContainerStack)

        NSLayoutConstraint.activate([
            toolbarScrollView.topAnchor.constraint(equalTo: topAnchor),
            toolbarScrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbarScrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolbarScrollView.heightAnchor.constraint(equalToConstant: 38),

            toolbarStack.topAnchor.constraint(equalTo: toolbarScrollView.topAnchor, constant: 3),
            toolbarStack.bottomAnchor.constraint(equalTo: toolbarScrollView.bottomAnchor, constant: -3),
            toolbarStack.leadingAnchor.constraint(equalTo: toolbarScrollView.leadingAnchor, constant: 8),
            toolbarStack.trailingAnchor.constraint(equalTo: toolbarScrollView.trailingAnchor, constant: -8),
            toolbarStack.heightAnchor.constraint(equalToConstant: 32),

            mainContainerStack.topAnchor.constraint(equalTo: toolbarScrollView.bottomAnchor, constant: 4),
            mainContainerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            mainContainerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            mainContainerStack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -4)
        ])

        qwertyPanel.axis = .vertical
        qwertyPanel.spacing = 5
        qwertyPanel.translatesAutoresizingMaskIntoConstraints = false
        mainContainerStack.addArrangedSubview(qwertyPanel)

        symbolPanel.axis = .vertical
        symbolPanel.spacing = 5
        symbolPanel.translatesAutoresizingMaskIntoConstraints = false
        symbolPanel.isHidden = true
        mainContainerStack.addArrangedSubview(symbolPanel)

        renderPanels()
    }

    private func buildToolbarButtons() {
        let commands: [(String, String)] = [
            ("@fix", "Fix"),
            ("@rewrite", "Rewrite"),
            ("@pro", "Pro"),
            ("@casual", "Casual"),
            ("@short", "Short"),
            ("@expand", "Expand"),
            ("@translate", "Translate")
        ]

        for (trigger, label) in commands {
            let btn = UIButton(type: .system)
            btn.setTitle(label, for: .normal)
            btn.titleLabel?.font = .boldSystemFont(ofSize: 12)
            btn.setTitleColor(.white, for: .normal)
            btn.backgroundColor = theme.accentColor
            btn.layer.cornerRadius = 14
            btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
            btn.accessibilityLabel = "AI Command \(label)"

            btn.addAction(UIAction { [weak self] _ in
                if trigger == "@translate" {
                    self?.showLanguageSelector()
                } else {
                    self?.controller?.onCommandButtonClicked(trigger)
                }
            }, for: .touchUpInside)

            toolbarStack.addArrangedSubview(btn)
        }
    }

    private func showLanguageSelector() {
        guard let vc = findViewController() else { return }
        let alert = UIAlertController(title: "Select Target Language", message: nil, preferredStyle: .actionSheet)

        for (code, name) in CommandParser.supportedLanguages {
            alert.addAction(UIAlertAction(title: name, style: .default) { [weak self] _ in
                self?.controller?.onTranslateLanguageSelected(code)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = toolbarScrollView
            popover.sourceRect = toolbarScrollView.bounds
        }

        vc.present(alert, animated: true)
    }

    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            responder = responder?.next
            if let vc = responder as? UIViewController {
                return vc
            }
        }
        return nil
    }

    private func renderPanels() {
        qwertyPanel.arrangedSubviews.forEach { $0.removeFromSuperview() }
        symbolPanel.arrangedSubviews.forEach { $0.removeFromSuperview() }
        letterKeyButtons.removeAll()

        buildQwertyPanel()
        buildSymbolPanel()

        qwertyPanel.isHidden = isSymbolPanel
        symbolPanel.isHidden = !isSymbolPanel
    }

    private func buildQwertyPanel() {
        let r1Keys = ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
        let r2Keys = ["a", "s", "d", "f", "g", "h", "j", "k", "l"]
        let r3Keys = ["z", "x", "c", "v", "b", "n", "m"]

        // Row 1
        let r1 = createFillRowStack()
        for char in r1Keys {
            let btn = KeyboardKeyButton(title: char, keyType: .letter, theme: theme)
            btn.addAction(UIAction { [weak self] _ in self?.controller?.onKeyTyped(char) }, for: .touchUpInside)
            letterKeyButtons.append(btn)
            r1.addArrangedSubview(btn)
        }
        qwertyPanel.addArrangedSubview(r1)

        // Row 2 (Indented with 16pt side padding)
        let r2Container = UIView()
        r2Container.translatesAutoresizingMaskIntoConstraints = false
        r2Container.heightAnchor.constraint(equalToConstant: 42).isActive = true

        let r2 = createFillRowStack()
        for char in r2Keys {
            let btn = KeyboardKeyButton(title: char, keyType: .letter, theme: theme)
            btn.addAction(UIAction { [weak self] _ in self?.controller?.onKeyTyped(char) }, for: .touchUpInside)
            letterKeyButtons.append(btn)
            r2.addArrangedSubview(btn)
        }

        r2Container.addSubview(r2)
        NSLayoutConstraint.activate([
            r2.topAnchor.constraint(equalTo: r2Container.topAnchor),
            r2.bottomAnchor.constraint(equalTo: r2Container.bottomAnchor),
            r2.leadingAnchor.constraint(equalTo: r2Container.leadingAnchor, constant: 16),
            r2.trailingAnchor.constraint(equalTo: r2Container.trailingAnchor, constant: -16)
        ])
        qwertyPanel.addArrangedSubview(r2Container)

        // Row 3
        let r3 = UIStackView()
        r3.axis = .horizontal
        r3.spacing = 4
        r3.distribution = .fillProportionally
        r3.translatesAutoresizingMaskIntoConstraints = false
        r3.heightAnchor.constraint(equalToConstant: 42).isActive = true

        let shiftBtn = KeyboardKeyButton(iconName: "shift", keyType: .special, theme: theme)
        shiftBtn.accessibilityLabel = "Shift"
        shiftBtn.widthAnchor.constraint(equalToConstant: 44).isActive = true
        shiftBtn.addAction(UIAction { [weak self] _ in self?.controller?.onShiftPressed() }, for: .touchUpInside)
        shiftKeyButton = shiftBtn
        r3.addArrangedSubview(shiftBtn)

        let r3LetterStack = createFillRowStack()
        for char in r3Keys {
            let btn = KeyboardKeyButton(title: char, keyType: .letter, theme: theme)
            btn.addAction(UIAction { [weak self] _ in self?.controller?.onKeyTyped(char) }, for: .touchUpInside)
            letterKeyButtons.append(btn)
            r3LetterStack.addArrangedSubview(btn)
        }
        r3.addArrangedSubview(r3LetterStack)

        let backspaceBtn = KeyboardKeyButton(iconName: "delete.left", keyType: .special, theme: theme)
        backspaceBtn.accessibilityLabel = "Delete"
        backspaceBtn.widthAnchor.constraint(equalToConstant: 44).isActive = true
        backspaceBtn.enableHoldToRepeat { [weak self] in
            self?.controller?.onBackspacePressed()
        }
        r3.addArrangedSubview(backspaceBtn)

        qwertyPanel.addArrangedSubview(r3)

        // Bottom Row
        qwertyPanel.addArrangedSubview(createBottomRow(toggleTitle: "123"))
    }

    private func buildSymbolPanel() {
        let r1Keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
        let r2Keys = ["-", "/", ":", ";", "(", ")", "$", "&", "@"]
        let r3Keys = [".", ",", "?", "!", "'", "\"", "_", "#", "%"]

        // Row 1
        let r1 = createFillRowStack()
        for char in r1Keys {
            let btn = KeyboardKeyButton(title: char, keyType: .letter, theme: theme)
            btn.addAction(UIAction { [weak self] _ in self?.controller?.onKeyTyped(char) }, for: .touchUpInside)
            r1.addArrangedSubview(btn)
        }
        symbolPanel.addArrangedSubview(r1)

        // Row 2
        let r2Container = UIView()
        r2Container.translatesAutoresizingMaskIntoConstraints = false
        r2Container.heightAnchor.constraint(equalToConstant: 42).isActive = true

        let r2 = createFillRowStack()
        for char in r2Keys {
            let btn = KeyboardKeyButton(title: char, keyType: .letter, theme: theme)
            btn.addAction(UIAction { [weak self] _ in self?.controller?.onKeyTyped(char) }, for: .touchUpInside)
            r2.addArrangedSubview(btn)
        }

        r2Container.addSubview(r2)
        NSLayoutConstraint.activate([
            r2.topAnchor.constraint(equalTo: r2Container.topAnchor),
            r2.bottomAnchor.constraint(equalTo: r2Container.bottomAnchor),
            r2.leadingAnchor.constraint(equalTo: r2Container.leadingAnchor, constant: 16),
            r2.trailingAnchor.constraint(equalTo: r2Container.trailingAnchor, constant: -16)
        ])
        symbolPanel.addArrangedSubview(r2Container)

        // Row 3
        let r3 = UIStackView()
        r3.axis = .horizontal
        r3.spacing = 4
        r3.distribution = .fillProportionally
        r3.translatesAutoresizingMaskIntoConstraints = false
        r3.heightAnchor.constraint(equalToConstant: 42).isActive = true

        let r3SymbolStack = createFillRowStack()
        for char in r3Keys {
            let btn = KeyboardKeyButton(title: char, keyType: .letter, theme: theme)
            btn.addAction(UIAction { [weak self] _ in self?.controller?.onKeyTyped(char) }, for: .touchUpInside)
            r3SymbolStack.addArrangedSubview(btn)
        }
        r3.addArrangedSubview(r3SymbolStack)

        let backspaceBtn = KeyboardKeyButton(iconName: "delete.left", keyType: .special, theme: theme)
        backspaceBtn.accessibilityLabel = "Delete"
        backspaceBtn.widthAnchor.constraint(equalToConstant: 44).isActive = true
        backspaceBtn.enableHoldToRepeat { [weak self] in
            self?.controller?.onBackspacePressed()
        }
        r3.addArrangedSubview(backspaceBtn)

        symbolPanel.addArrangedSubview(r3)

        // Bottom Row
        symbolPanel.addArrangedSubview(createBottomRow(toggleTitle: "ABC"))
    }

    private func createBottomRow(toggleTitle: String) -> UIStackView {
        let bottomStack = UIStackView()
        bottomStack.axis = .horizontal
        bottomStack.spacing = 4
        bottomStack.distribution = .fillProportionally
        bottomStack.translatesAutoresizingMaskIntoConstraints = false
        bottomStack.heightAnchor.constraint(equalToConstant: 42).isActive = true

        let toggleBtn = KeyboardKeyButton(title: toggleTitle, keyType: .special, theme: theme)
        toggleBtn.accessibilityLabel = toggleTitle == "123" ? "Numbers" : "Letters"
        toggleBtn.widthAnchor.constraint(equalToConstant: 48).isActive = true
        toggleBtn.addAction(UIAction { [weak self] _ in
            self?.isSymbolPanel.toggle()
            self?.qwertyPanel.isHidden = self?.isSymbolPanel ?? false
            self?.symbolPanel.isHidden = !(self?.isSymbolPanel ?? false)
        }, for: .touchUpInside)
        bottomStack.addArrangedSubview(toggleBtn)

        let globeBtn = KeyboardKeyButton(iconName: "globe", keyType: .special, theme: theme)
        globeBtn.accessibilityLabel = "Globe"
        globeBtn.widthAnchor.constraint(equalToConstant: 42).isActive = true
        globeBtn.addAction(UIAction { [weak self] _ in
            self?.findViewController()?.advanceToNextInputMode()
        }, for: .touchUpInside)
        bottomStack.addArrangedSubview(globeBtn)

        let spaceBtn = KeyboardKeyButton(title: "space", keyType: .space, theme: theme)
        spaceBtn.accessibilityLabel = "Space"
        spaceBtn.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spaceBtn.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        spaceBtn.addAction(UIAction { [weak self] _ in
            self?.controller?.onKeyTyped(" ")
        }, for: .touchUpInside)
        bottomStack.addArrangedSubview(spaceBtn)

        let returnBtn = KeyboardKeyButton(iconName: "return", keyType: .special, theme: theme)
        returnBtn.accessibilityLabel = "Return"
        returnBtn.widthAnchor.constraint(equalToConstant: 68).isActive = true
        returnBtn.addAction(UIAction { [weak self] _ in
            self?.controller?.onKeyTyped("\n")
        }, for: .touchUpInside)
        bottomStack.addArrangedSubview(returnBtn)

        return bottomStack
    }

    private func createFillRowStack() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.heightAnchor.constraint(equalToConstant: 42).isActive = true
        return stack
    }

    private func updateShiftStateUi(_ state: ShiftState) {
        let isUpper = state != .lowercase

        switch state {
        case .lowercase:
            shiftKeyButton?.updateIcon(iconName: "shift")
        case .shift:
            shiftKeyButton?.updateIcon(iconName: "shift.fill")
        case .capsLock:
            shiftKeyButton?.updateIcon(iconName: "capslock.fill")
        }

        for btn in letterKeyButtons {
            if let t = btn.title(for: .normal) {
                btn.setTitle(isUpper ? t.uppercased() : t.lowercased(), for: .normal)
            }
        }
    }
}

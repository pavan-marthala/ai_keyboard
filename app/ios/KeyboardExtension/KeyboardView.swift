import UIKit

class KeyboardView: UIView {
    private var controller: KeyboardController?
    private var theme: KeyboardTheme

    private var isSymbolPanel = false

    private let statusLabel = UILabel()
    private let toolbarScrollView = UIScrollView()
    private let toolbarStack = UIStackView()
    private let mainPanelStack = UIStackView()

    private var letterKeyButtons: [UIButton] = []
    private var shiftKeyButton: UIButton?

    init(theme: KeyboardTheme) {
        self.theme = theme
        super.init(frame: .zero)
        backgroundColor = theme.backgroundColor
        setupUi()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(controller: KeyboardController) {
        self.controller = controller
        controller.onStatusUpdate = { [weak self] status in
            self?.statusLabel.text = status
        }
        controller.onShiftStateChanged = { [weak self] state in
            self?.updateShiftStateUi(state)
        }
        buildToolbarButtons()
    }

    func updateTheme(_ theme: KeyboardTheme) {
        self.theme = theme
        backgroundColor = theme.backgroundColor
        renderPanel()
    }

    private func setupUi() {
        toolbarScrollView.showsHorizontalScrollIndicator = false
        toolbarScrollView.backgroundColor = theme.toolbarColor
        toolbarScrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(toolbarScrollView)

        toolbarStack.axis = .horizontal
        toolbarStack.spacing = 8
        toolbarStack.alignment = .center
        toolbarStack.translatesAutoresizingMaskIntoConstraints = false
        toolbarScrollView.addSubview(toolbarStack)

        statusLabel.text = "✨ AI Keyboard"
        statusLabel.font = .boldSystemFont(ofSize: 13)
        statusLabel.textColor = theme.accentColor
        toolbarStack.addArrangedSubview(statusLabel)

        mainPanelStack.axis = .vertical
        mainPanelStack.spacing = 6
        mainPanelStack.distribution = .fillEqually
        mainPanelStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainPanelStack)

        NSLayoutConstraint.activate([
            toolbarScrollView.topAnchor.constraint(equalTo: topAnchor),
            toolbarScrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbarScrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolbarScrollView.heightAnchor.constraint(equalToConstant: 40),

            toolbarStack.topAnchor.constraint(equalTo: toolbarScrollView.topAnchor, constant: 4),
            toolbarStack.bottomAnchor.constraint(equalTo: toolbarScrollView.bottomAnchor, constant: -4),
            toolbarStack.leadingAnchor.constraint(equalTo: toolbarScrollView.leadingAnchor, constant: 8),
            toolbarStack.trailingAnchor.constraint(equalTo: toolbarScrollView.trailingAnchor, constant: -8),

            mainPanelStack.topAnchor.constraint(equalTo: toolbarScrollView.bottomAnchor, constant: 6),
            mainPanelStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            mainPanelStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            mainPanelStack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -4)
        ])

        renderPanel()
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

    private func renderPanel() {
        mainPanelStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        letterKeyButtons.removeAll()

        if isSymbolPanel {
            renderSymbolLayout()
        } else {
            renderQwertyLayout()
        }
    }

    private func renderQwertyLayout() {
        let r1 = ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
        let r2 = ["a", "s", "d", "f", "g", "h", "j", "k", "l"]
        let r3 = ["z", "x", "c", "v", "b", "n", "m"]

        mainPanelStack.addArrangedSubview(createRowStack(r1))
        mainPanelStack.addArrangedSubview(createRowStack(r2))

        let row3 = UIStackView()
        row3.axis = .horizontal
        row3.spacing = 4
        row3.distribution = .fillProportionally

        let shiftBtn = createKeyButton(title: "⇧", isSpecial: true) { [weak self] in
            self?.controller?.onShiftPressed()
        }
        shiftKeyButton = shiftBtn
        row3.addArrangedSubview(shiftBtn)

        for char in r3 {
            let btn = createKeyButton(title: char) { [weak self] in
                self?.controller?.onKeyTyped(char)
            }
            letterKeyButtons.append(btn)
            row3.addArrangedSubview(btn)
        }

        let backspaceBtn = createKeyButton(title: "⌫", isSpecial: true) { [weak self] in
            self?.controller?.onBackspacePressed()
        }
        row3.addArrangedSubview(backspaceBtn)

        mainPanelStack.addArrangedSubview(row3)
        renderBottomRow()
    }

    private func renderSymbolLayout() {
        let r1 = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
        let r2 = ["@", "#", "$", "%", "&", "*", "(", ")", "-", "+"]
        let r3 = ["_", "\"", "'", ":", ";", "!", "?", "/", "."]

        mainPanelStack.addArrangedSubview(createRowStack(r1))
        mainPanelStack.addArrangedSubview(createRowStack(r2))

        let row3 = UIStackView()
        row3.axis = .horizontal
        row3.spacing = 4
        row3.distribution = .fillProportionally

        for char in r3 {
            row3.addArrangedSubview(createKeyButton(title: char) { [weak self] in
                self?.controller?.onKeyTyped(char)
            })
        }

        let backspaceBtn = createKeyButton(title: "⌫", isSpecial: true) { [weak self] in
            self?.controller?.onBackspacePressed()
        }
        row3.addArrangedSubview(backspaceBtn)

        mainPanelStack.addArrangedSubview(row3)
        renderBottomRow()
    }

    private func renderBottomRow() {
        let bottomStack = UIStackView()
        bottomStack.axis = .horizontal
        bottomStack.spacing = 4
        bottomStack.distribution = .fillProportionally

        let toggleBtn = createKeyButton(title: isSymbolPanel ? "ABC" : "123", isSpecial: true) { [weak self] in
            self?.isSymbolPanel.toggle()
            self?.renderPanel()
        }
        bottomStack.addArrangedSubview(toggleBtn)

        let globeBtn = createKeyButton(title: "🌐", isSpecial: true) { [weak self] in
            self?.findViewController()?.advanceToNextInputMode()
        }
        bottomStack.addArrangedSubview(globeBtn)

        let spaceBtn = createKeyButton(title: "space") { [weak self] in
            self?.controller?.onKeyTyped(" ")
        }
        bottomStack.addArrangedSubview(spaceBtn)

        let returnBtn = createKeyButton(title: "return", isSpecial: true) { [weak self] in
            self?.controller?.onKeyTyped("\n")
        }
        bottomStack.addArrangedSubview(returnBtn)

        mainPanelStack.addArrangedSubview(bottomStack)
    }

    private func createRowStack(_ keys: [String]) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.distribution = .fillEqually
        for char in keys {
            let btn = createKeyButton(title: char) { [weak self] in
                self?.controller?.onKeyTyped(char)
            }
            if !isSymbolPanel { letterKeyButtons.append(btn) }
            stack.addArrangedSubview(btn)
        }
        return stack
    }

    private func createKeyButton(title: String, isSpecial: Bool = false, onTap: @escaping () -> Void) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18)
        btn.setTitleColor(theme.textColor, for: .normal)
        btn.backgroundColor = isSpecial ? theme.specialKeyColor : theme.keyColor
        btn.layer.cornerRadius = 6
        btn.addAction(UIAction { _ in onTap() }, for: .touchUpInside)
        return btn
    }

    private func updateShiftStateUi(_ state: ShiftState) {
        shiftKeyButton?.setTitle(state == .capsLock ? "🔒" : (state == .shift ? "⇪" : "⇧"), for: .normal)
        let isUpper = state != .lowercase
        for btn in letterKeyButtons {
            if let t = btn.title(for: .normal) {
                btn.setTitle(isUpper ? t.uppercased() : t.lowercased(), for: .normal)
            }
        }
    }
}


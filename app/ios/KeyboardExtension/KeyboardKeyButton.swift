import UIKit

enum KeyType {
    case letter
    case special
    case space
    case action
}

class KeyboardKeyButton: UIButton {
    let keyType: KeyType
    private var normalColor: UIColor
    private var pressedColor: UIColor

    var onRepeat: (() -> Void)?
    private var repeatTimer: Timer?

    init(title: String? = nil, iconName: String? = nil, keyType: KeyType = .letter, theme: KeyboardTheme) {
        self.keyType = keyType
        self.normalColor = (keyType == .letter || keyType == .space) ? theme.keyColor : theme.specialKeyColor
        self.pressedColor = theme.keyPressedColor
        super.init(frame: .zero)

        backgroundColor = normalColor
        layer.cornerRadius = 6
        layer.masksToBounds = true
        titleLabel?.font = .systemFont(ofSize: keyType == .space ? 14 : 18, weight: .regular)
        setTitleColor(theme.textColor, for: .normal)
        tintColor = theme.textColor
        contentEdgeInsets = UIEdgeInsets(top: 4, left: 2, bottom: 4, right: 2)

        if let title = title {
            setTitle(title, for: .normal)
            accessibilityLabel = title
        }

        if let iconName = iconName {
            let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
            if let image = UIImage(systemName: iconName, withConfiguration: config) {
                setImage(image, for: .normal)
            }
            if title == nil {
                accessibilityLabel = iconName
            }
        }

        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 42).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? pressedColor : normalColor
        }
    }

    func updateTheme(_ theme: KeyboardTheme) {
        self.normalColor = (keyType == .letter || keyType == .space) ? theme.keyColor : theme.specialKeyColor
        self.pressedColor = theme.keyPressedColor
        backgroundColor = isHighlighted ? pressedColor : normalColor
        setTitleColor(theme.textColor, for: .normal)
        tintColor = theme.textColor
    }

    func updateIcon(iconName: String) {
        let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        if let image = UIImage(systemName: iconName, withConfiguration: config) {
            setImage(image, for: .normal)
            setTitle(nil, for: .normal)
        }
    }

    func enableHoldToRepeat(action: @escaping () -> Void) {
        self.onRepeat = action
        addTarget(self, action: #selector(handleTouchDown), for: .touchDown)
        addTarget(self, action: #selector(handleTouchCancel), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    @objc private func handleTouchDown() {
        onRepeat?()
        repeatTimer?.invalidate()
        repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { [weak self] _ in
            self?.repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
                self?.onRepeat?()
            }
        }
    }

    @objc private func handleTouchCancel() {
        repeatTimer?.invalidate()
        repeatTimer = nil
    }

    deinit {
        repeatTimer?.invalidate()
    }
}


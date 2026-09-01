import UIKit

struct KeyboardTheme {
    let backgroundColor: UIColor
    let toolbarColor: UIColor
    let keyColor: UIColor
    let keyPressedColor: UIColor
    let specialKeyColor: UIColor
    let textColor: UIColor
    let accentColor: UIColor
    let dividerColor: UIColor

    static var light: KeyboardTheme {
        return KeyboardTheme(
            backgroundColor: UIColor(red: 0.82, green: 0.84, blue: 0.86, alpha: 1.0),
            toolbarColor: .white,
            keyColor: .white,
            keyPressedColor: UIColor(red: 0.72, green: 0.74, blue: 0.76, alpha: 1.0),
            specialKeyColor: UIColor(red: 0.68, green: 0.71, blue: 0.74, alpha: 1.0),
            textColor: .black,
            accentColor: UIColor(red: 0.40, green: 0.23, blue: 0.72, alpha: 1.0),
            dividerColor: UIColor(red: 0.78, green: 0.80, blue: 0.82, alpha: 1.0)
        )
    }

    static var dark: KeyboardTheme {
        return KeyboardTheme(
            backgroundColor: UIColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1.0),
            toolbarColor: UIColor(red: 0.16, green: 0.16, blue: 0.22, alpha: 1.0),
            keyColor: UIColor(red: 0.20, green: 0.20, blue: 0.28, alpha: 1.0),
            keyPressedColor: UIColor(red: 0.28, green: 0.28, blue: 0.36, alpha: 1.0),
            specialKeyColor: UIColor(red: 0.24, green: 0.24, blue: 0.32, alpha: 1.0),
            textColor: .white,
            accentColor: UIColor(red: 0.74, green: 0.58, blue: 0.98, alpha: 1.0),
            dividerColor: UIColor(red: 0.28, green: 0.28, blue: 0.36, alpha: 1.0)
        )
    }

    static func current(traitCollection: UITraitCollection) -> KeyboardTheme {
        return traitCollection.userInterfaceStyle == .dark ? dark : light
    }
}


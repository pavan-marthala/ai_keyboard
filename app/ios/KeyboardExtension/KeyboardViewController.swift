import UIKit

class KeyboardViewController: UIInputViewController {
    private let editor = TextDocumentEditor()
    private var controller: KeyboardController!
    private var keyboardView: KeyboardView!

    override func viewDidLoad() {
        super.viewDidLoad()

        editor.updateProxy(textDocumentProxy)
        controller = KeyboardController(editor: editor)

        let theme = KeyboardTheme.current(traitCollection: traitCollection)
        keyboardView = KeyboardView(theme: theme)
        keyboardView.bind(controller: controller)

        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboardView)

        NSLayoutConstraint.activate([
            keyboardView.topAnchor.constraint(equalTo: view.topAnchor),
            keyboardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func textWillChange(_ textInput: UITextInput?) {
        super.textWillChange(textInput)
        editor.updateProxy(textDocumentProxy)
        controller?.invalidateInputContext()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        editor.updateProxy(textDocumentProxy)
        controller?.checkForCommandTrigger()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let theme = KeyboardTheme.current(traitCollection: traitCollection)
        keyboardView?.updateTheme(theme)
    }

    deinit {
        controller?.invalidateInputContext()
    }
}

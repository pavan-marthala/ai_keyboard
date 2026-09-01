import UIKit

/**
 * TextDocumentEditor encapsulates interactions with Apple's [UITextDocumentProxy].
 * Exposes textBeforeInput, textAfterInput, selectedText properties and safe editing operations.
 */
class TextDocumentEditor {
    private weak var proxy: UITextDocumentProxy?

    init(proxy: UITextDocumentProxy? = nil) {
        self.proxy = proxy
    }

    func updateProxy(_ proxy: UITextDocumentProxy?) {
        self.proxy = proxy
    }

    var textBeforeInput: String? {
        return proxy?.textBeforeInput
    }

    var textAfterInput: String? {
        return proxy?.textAfterInput
    }

    var selectedText: String? {
        return proxy?.selectedText
    }

    var hasText: Bool {
        return proxy?.hasText ?? false
    }

    func insertText(_ text: String) {
        proxy?.insertText(text)
    }

    func deleteBackward() {
        proxy?.deleteBackward()
    }

    func deleteBeforeCursor(count: Int) {
        guard let proxy = proxy else { return }
        for _ in 0..<count {
            proxy.deleteBackward()
        }
    }
}


import Foundation
import UIKit

enum ShiftState {
    case lowercase
    case shift
    case capsLock
}

struct TransformationRequestContext {
    let requestId: UUID
    let sessionId: Int
    let submittedTextBeforeInput: String
    let fullMatchLength: Int
    let cleanText: String
}

class KeyboardController {
    let editor: TextDocumentEditor

    var shiftState: ShiftState = .lowercase {
        didSet {
            onShiftStateChanged?(shiftState)
        }
    }

    var onStatusUpdate: ((String) -> Void)?
    var onShiftStateChanged: ((ShiftState) -> Void)?

    private var lastShiftTapTime: TimeInterval = 0

    private(set) var currentSessionId = 0
    private var activeRequestContext: TransformationRequestContext?
    private var activeTask: Task<Void, Never>?
    private var isTransforming = false

    init(editor: TextDocumentEditor) {
        self.editor = editor
    }

    func invalidateInputContext() {
        currentSessionId += 1
        activeRequestContext = nil
        activeTask?.cancel()
        activeTask = nil
        isTransforming = false
    }

    func onKeyTyped(_ char: String) {
        if isTransforming { return }

        let charToInsert: String
        switch shiftState {
        case .shift:
            charToInsert = char.uppercased()
            shiftState = .lowercase
        case .capsLock:
            charToInsert = char.uppercased()
        case .lowercase:
            charToInsert = char
        }

        editor.insertText(charToInsert)
        checkForCommandTrigger()
    }

    func onShiftPressed() {
        let now = Date().timeIntervalSince1970
        if now - lastShiftTapTime < 0.3 {
            shiftState = .capsLock
        } else {
            switch shiftState {
            case .lowercase: shiftState = .shift
            case .shift: shiftState = .lowercase
            case .capsLock: shiftState = .lowercase
            }
        }
        lastShiftTapTime = now
    }

    func onBackspacePressed() {
        if isTransforming { return }
        editor.deleteBackward()
    }

    func onCommandButtonClicked(_ trigger: String) {
        if isTransforming { return }
        let textBefore = editor.textBeforeInput ?? ""
        let prefixSpace = (!textBefore.isEmpty && !textBefore.hasSuffix(" ")) ? " " : ""
        editor.insertText("\(prefixSpace)\(trigger) ")
        checkForCommandTrigger()
    }

    func onTranslateLanguageSelected(_ langCode: String) {
        if isTransforming { return }
        let textBefore = editor.textBeforeInput ?? ""
        let prefixSpace = (!textBefore.isEmpty && !textBefore.hasSuffix(" ")) ? " " : ""
        editor.insertText("\(prefixSpace)@translate:\(langCode) ")
        checkForCommandTrigger()
    }

    func checkForCommandTrigger() {
        guard let textBefore = editor.textBeforeInput, !textBefore.isEmpty else {
            onStatusUpdate?("✨ AtFIx")
            return
        }

        guard let parsed = CommandParser.parse(inputText: textBefore) else {
            onStatusUpdate?("✨ AtFIx")
            return
        }

        onStatusUpdate?(parsed.statusMessage)
        executeTransformation(parsed: parsed, submittedTextBefore: textBefore)
    }

    private func executeTransformation(parsed: ParsedCommand, submittedTextBefore: String) {
        if isTransforming { return }

        let requestId = UUID()
        let requestContext = TransformationRequestContext(
            requestId: requestId,
            sessionId: currentSessionId,
            submittedTextBeforeInput: submittedTextBefore,
            fullMatchLength: parsed.fullMatchLength,
            cleanText: parsed.cleanText
        )

        activeRequestContext = requestContext
        isTransforming = true

        activeTask = Task { [weak self] in
            guard let self = self else { return }

            let result = await AiTextTransformer.shared.transformText(
                text: parsed.cleanText,
                prompt: parsed.prompt
            )

            if Task.isCancelled { return }

            await MainActor.run { [weak self] in
                guard let self = self else { return }
                defer { self.isTransforming = false }

                guard let currentCtx = self.activeRequestContext,
                      currentCtx.requestId == requestId,
                      currentCtx.sessionId == self.currentSessionId else {
                    return
                }

                let currentTextBefore = self.editor.textBeforeInput ?? ""
                if currentTextBefore != submittedTextBefore {
                    self.onStatusUpdate?("✨ AtFIx")
                    return
                }

                switch result {
                case .success(let transformedText):
                    self.editor.deleteBeforeCursor(count: parsed.fullMatchLength)
                    self.editor.insertText(transformedText)
                    self.onStatusUpdate?("✨ AtFIx")
                case .failure(let failure):
                    self.onStatusUpdate?(failure.userMessage)
                }
            }
        }
    }
}

import Cocoa
import ApplicationServices

/// Service responsible for replacing selected text in target applications using
/// reliable synthetic keyboard event injection and AX selection revalidation.
final class TextReplacementService {

    static let shared = TextReplacementService()

    private let accessibilityService: AccessibilityService

    init(accessibilityService: AccessibilityService = .shared) {
        self.accessibilityService = accessibilityService
    }

    // MARK: - Replacement Workflow

    @discardableResult
    func replaceSelectedText(
        transformedText: String,
        targetApp: NSRunningApplication,
        targetPid: pid_t,
        targetElement: AXUIElement,
        expectedSelectedText: String,
        expectedSelectedRange: CFRange
    ) -> Bool {
        // 1. Reactivate the ORIGINAL target application and wait until it is frontmost.
        guard reactivateAndWaitForFrontmost(app: targetApp, timeout: 1.0) else {
            NSLog("[TextReplacementService] Target app '\(targetApp.localizedName ?? "?")' did not become frontmost in time")
            NSLog("[TextReplacementService] REPLACEMENT FAILED")
            return false
        }
        NSLog("[TextReplacementService] TARGET APP ACTIVATED")

        // 2. Re-validate that the ORIGINAL selection is still intact on the ORIGINAL captured element.
        guard accessibilityService.revalidateSelection(
            element: targetElement,
            expectedText: expectedSelectedText,
            expectedRange: expectedSelectedRange
        ) != nil else {
            NSLog("[TextReplacementService] Selection lost or altered after reactivation. Expected '\(expectedSelectedText)'")
            NSLog("[TextReplacementService] REPLACEMENT FAILED")
            return false
        }
        NSLog("[TextReplacementService] SELECTION REVALIDATED")

        NSLog("[TextReplacementService] REPLACEMENT STARTED")

        let docBefore = accessibilityService.readDocumentValue(element: targetElement)
        NSLog("[TextReplacementService] DOC BEFORE (AX) = '\(docBefore)'")

        // 3. Primary replacement mechanism: synthetic keystroke injection.
        NSLog("[TextReplacementService] SENDING REPLACEMENT = '\(transformedText)'")
        let apiCallSucceeded = typeReplacement(transformedText, targetPid: targetPid)

        guard apiCallSucceeded else {
            NSLog("[TextReplacementService] API CALL SUCCESS = false (failed to post synthetic keyboard events)")
            NSLog("[TextReplacementService] REPLACEMENT FAILED")
            return false
        }
        NSLog("[TextReplacementService] API CALL SUCCESS = true (synthetic keystrokes posted)")

        usleep(100_000) // 100ms synchronization pause

        let docAfter = accessibilityService.readDocumentValue(element: targetElement)
        NSLog("[TextReplacementService] DOC AFTER (AX readback) = '\(docAfter)'")

        let normalizedTransformed = transformedText.trimmingCharacters(in: .whitespacesAndNewlines)
        let axReadbackChanged = (docAfter != docBefore) && docAfter.contains(normalizedTransformed)

        NSLog("[TextReplacementService] AX READBACK SUCCESS = \(axReadbackChanged)")
        NSLog("[TextReplacementService] REPLACEMENT COMPLETED")
        return true
    }

    // MARK: - App Activation & Synchronization

    func reactivateAndWaitForFrontmost(app: NSRunningApplication, timeout: TimeInterval) -> Bool {
        if NSWorkspace.shared.frontmostApplication?.processIdentifier != app.processIdentifier {
            if #available(macOS 14.0, *) {
                app.activate()
            } else {
                app.activate(options: .activateIgnoringOtherApps)
            }
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

    // MARK: - Synthetic Keystroke Injection

    func typeReplacement(_ text: String, targetPid: pid_t) -> Bool {
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

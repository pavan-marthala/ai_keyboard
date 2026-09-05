import Cocoa
import ApplicationServices

/// Service encapsulating all macOS Accessibility (AXUIElement) operations.
/// Hides low-level AX attribute APIs and platform-specific quirks (e.g. Chromium tree activation).
final class AccessibilityService {

    static let shared = AccessibilityService()

    private init() {}

    // MARK: - Permission Check

    func isProcessTrusted() -> Bool {
        return AXIsProcessTrusted()
    }

    // MARK: - Focused Element Query

    /// Queries the FRONTMOST APP's own AX element for its focused UI element,
    /// rather than going through AXUIElementCreateSystemWide().
    /// Direct querying avoids WindowServer routing failures (-25204).
    /// Includes bounded retries and an explicit AXEnhancedUserInterface signal
    /// for Chromium/Electron applications (VS Code, Chrome, Slack, etc.) that
    /// don't construct their accessibility tree until requested.
    func copyFocusedElement(
        attempts: Int = 3,
        delayMicroseconds: useconds_t = 40_000
    ) -> (element: AXUIElement?, pid: pid_t, app: NSRunningApplication?, lastError: AXError) {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            NSLog("[AccessibilityService] No frontmost application reported by NSWorkspace")
            return (nil, 0, nil, .cannotComplete)
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
                let element = unsafeBitCast(focusedRef, to: AXUIElement.self)
                return (element, appPid, frontApp, .success)
            }
            lastError = err
            NSLog("[AccessibilityService] Focused element query via app element, attempt \(attempt): AXError = \(err.rawValue), app='\(frontApp.localizedName ?? "?")' pid=\(appPid)")

            // Chromium/Electron apps (VS Code, Chrome, WhatsApp Desktop,
            // Slack, ...) do not build a full accessibility tree until
            // something actually requests one - kAXErrorCannotComplete
            // here often means "no tree exists yet", not "access denied".
            // AXEnhancedUserInterface is the standard signal used to force
            // Chromium to activate its accessibility bridge.
            if !didRequestEnhancedUI, (err == .cannotComplete || err == .noValue) {
                NSLog("[AccessibilityService] Requesting AXEnhancedUserInterface for pid=\(appPid) (Chromium/Electron tree activation)")
                _ = AXUIElementSetAttributeValue(appElement, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue)
                didRequestEnhancedUI = true
                usleep(300_000) // First-time tree construction takes a few hundred ms
                continue
            }

            if attempt < attempts {
                usleep(delayMicroseconds)
            }
        }
        return (nil, appPid, frontApp, lastError)
    }

    // MARK: - Selected Text & Range

    func readSelectedText(element: AXUIElement) -> String? {
        var ref: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            &ref
        )
        guard err == .success, let s = ref as? String else {
            return nil
        }
        return s
    }

    func readSelectedRange(element: AXUIElement) -> CFRange {
        var rangeRef: CFTypeRef?
        var range = CFRange(location: -1, length: 0)
        if AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &rangeRef) == .success,
           let rangeRef {
            AXValueGetValue(rangeRef as! AXValue, .cfRange, &range)
        }
        return range
    }

    // MARK: - Selection Revalidation & Restore

    /// Re-validates that the captured selection remains intact.
    /// If the selection range shifted or was deselected, attempts to restore it
    /// via kAXSelectedTextRangeAttribute before verifying text identity.
    func revalidateSelection(
        element: AXUIElement,
        expectedText: String,
        expectedRange: CFRange
    ) -> CFRange? {
        var currentSelectedText = readSelectedText(element: element) ?? ""

        if currentSelectedText != expectedText,
           expectedRange.location >= 0,
           expectedRange.length > 0 {
            var restoreRange = expectedRange
            if let axRange = AXValueCreate(.cfRange, &restoreRange) {
                _ = AXUIElementSetAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, axRange)
                usleep(20_000)
                currentSelectedText = readSelectedText(element: element) ?? ""
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

    // MARK: - Document Text Readback

    func readDocumentValue(element: AXUIElement) -> String {
        var docRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &docRef) == .success,
           let text = docRef as? String {
            return text
        }
        return ""
    }
}

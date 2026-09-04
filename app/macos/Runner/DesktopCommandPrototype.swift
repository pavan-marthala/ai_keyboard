import Cocoa
import ApplicationServices
import Carbon

/// macOS @command end-to-end native prototype.
///
/// Observes global keyboard input, detects trailing @fix commands,
/// performs a deterministic mock transformation, and replaces the
/// corresponding text in the focused application.
///
/// This prototype intentionally contains no real AI integration
/// and no TCC/identity/forensic diagnostics.
///
/// FIX NOTES (13.2.7):
///
/// The range-discovery logic (finding exactly "hello world @fix" via AX
/// value + cursor offset, converting to a UTF-16 range, and selecting that
/// range via kAXSelectedTextRangeAttribute) was already correct and is left
/// untouched — the logs from the previous run confirm the selection itself
/// lands on the right characters.
///
/// What was NOT reliable was the mutation step: calling
/// AXUIElementSetAttributeValue on kAXSelectedTextAttribute / kAXValueAttribute
/// can report kAXErrorSuccess, and a follow-up AXUIElementCopyAttributeValue
/// can even echo back the expected string, without the target app's actual
/// on-screen text ever changing. That's the same failure mode found and
/// fixed in DesktopShortcutCommandPrototype.swift.
///
/// The fix applies the same principle here, adapted to the fact that this
/// prototype has no pre-existing user selection: once the trailing
/// "<text> @fix" range is located and selected via AX (a reliable,
/// navigation-oriented AX operation), the actual replacement is performed
/// by synthesizing real keystrokes (CGEvent + keyboardSetUnicodeString)
/// targeted at the focused app's process. Typing while a selection is
/// active is standard OS text-editing behavior — it deletes the selection
/// and inserts the new run through the app's real NSTextInputClient /
/// responder-chain path, the same one a live keystroke uses.
///
/// FIX NOTES (13.2.8):
///
/// Step 5 from the task spec — "make sure the target application actually
/// owns keyboard focus" — was only partially enforced. The post-selection
/// verification guard previously accepted ANY non-empty selected text
/// (`|| !selectedTextAfterSelection.isEmpty`), which meant a stale AX
/// element or a focus race could still fall through to typing over the
/// wrong text. That escape hatch is removed.
///
/// Added:
///   - An explicit frontmost/activation check + short settle delay before
///     typing, since AX operations can succeed even when the target app
///     isn't actually key/frontmost.
///   - A second, STRICT re-read of kAXSelectedTextAttribute after any
///     activation (activation can itself perturb selection), compared via
///     exact trimmed equality against the expected "<clean text> @fix"
///     string. If it doesn't match, the replacement is aborted rather than
///     risking a silent wrong-range type-over.
final class DesktopCommandPrototype {

    static let shared = DesktopCommandPrototype()

    // MARK: - Event Tap

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    // MARK: - Typing State

    private var typedBuffer = ""
    private let maxBufferSize = 500

    private var isTransforming = false

    // MARK: - Mock Transformations

    private let mockDatabase: [String: String] = [
        "hello world": "Hello world.",
        "i has a apple": "I have an apple.",
        "i have a apple": "I have an apple.",
        "this sentence needs fixing": "This sentence has been fixed.",
        "i am going office tomorrow": "I am going to the office tomorrow."
    ]

    private init() {}

    deinit {
        stop()
    }

    // MARK: - Start

func start() {

    NSLog(
        "[DesktopCommandPrototype] START() CALLED - eventTap is \(eventTap == nil ? "NIL" : "NON-NIL")"
    )

    if eventTap != nil {
        NSLog(
            "[DesktopCommandPrototype] START() ABORTED - eventTap already exists"
        )
        return
    }

    NSLog(
        "[DesktopCommandPrototype] Creating CGEventTap..."
    )

    let mask = CGEventMask(
        1 << CGEventType.keyDown.rawValue
    )

    let observerSelf = Unmanaged
        .passUnretained(self)
        .toOpaque()

    guard let tap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: mask,
        callback: {
            proxy,
            type,
            event,
            refcon in

            guard let refcon else {
                return Unmanaged.passRetained(event)
            }

            let prototype =
                Unmanaged<DesktopCommandPrototype>
                    .fromOpaque(refcon)
                    .takeUnretainedValue()

            return prototype.handleEventTap(
                proxy: proxy,
                type: type,
                event: event
            )
        },
        userInfo: observerSelf
    ) else {

        NSLog(
            "[DesktopCommandPrototype] CGEvent.tapCreate FAILED"
        )

        return
    }

    NSLog(
        "[DesktopCommandPrototype] CGEvent.tapCreate SUCCEEDED"
    )

    eventTap = tap

    guard let source = CFMachPortCreateRunLoopSource(
        kCFAllocatorDefault,
        tap,
        0
    ) else {

        NSLog(
            "[DesktopCommandPrototype] CFMachPortCreateRunLoopSource FAILED"
        )

        eventTap = nil
        return
    }

    runLoopSource = source

    CFRunLoopAddSource(
        CFRunLoopGetMain(),
        source,
        .commonModes
    )

    CGEvent.tapEnable(
        tap: tap,
        enable: true
    )

    NSLog(
        "[DesktopCommandPrototype] KEYBOARD EVENT TAP ACTIVE"
    )
}

    // MARK: - Stop

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(
                tap: tap,
                enable: false
            )
        }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(
                CFRunLoopGetMain(),
                source,
                .commonModes
            )
        }

        eventTap = nil
        runLoopSource = nil

        typedBuffer.removeAll()
        isTransforming = false

        print(
            "[DesktopCommandPrototype] Prototype stopped."
        )
    }

    // MARK: - CGEvent Callback

private func handleEventTap(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent
) -> Unmanaged<CGEvent>? {

    NSLog(
        "[DesktopCommandPrototype] EVENT TAP CALLBACK type=\(type.rawValue)"
    )

    if type == .tapDisabledByTimeout ||
        type == .tapDisabledByUserInput {

        NSLog(
            "[DesktopCommandPrototype] EVENT TAP DISABLED - re-enabling"
        )

        if let tap = eventTap {
            CGEvent.tapEnable(
                tap: tap,
                enable: true
            )
        }

        return Unmanaged.passRetained(event)
    }

    guard type == .keyDown else {
        return Unmanaged.passRetained(event)
    }

    let keyCode = Int(
        event.getIntegerValueField(
            .keyboardEventKeycode
        )
    )

    NSLog(
        "[DesktopCommandPrototype] KEY DOWN keyCode=\(keyCode)"
    )

    var actualLength = 0

    var unicodeChars = [UniChar](
        repeating: 0,
        count: 64
    )

    event.keyboardGetUnicodeString(
        maxStringLength: unicodeChars.count,
        actualStringLength: &actualLength,
        unicodeString: &unicodeChars
    )

    let characters: String?

    if actualLength > 0 {
        characters = String(
            utf16CodeUnits: unicodeChars,
            count: actualLength
        )
    } else {
        characters = nil
    }

    NSLog(
        "[DesktopCommandPrototype] Unicode='\(characters ?? "<nil>")'"
    )

    DispatchQueue.main.async { [weak self] in

        guard let self else {
            return
        }

        self.processCapturedKey(
            keyCode: keyCode,
            characters: characters
        )
    }

    return Unmanaged.passRetained(event)
}

    // MARK: - Key Processing

    private func processCapturedKey(
        keyCode: Int,
        characters: String?
    ) {

        // Re-entrancy guard: while a replacement is in flight, this
        // prototype itself posts synthetic keystrokes (see typeReplacement
        // below). Those synthetic events pass back through this SAME global
        // event tap, since it observes the whole session. This guard is
        // what prevents synthetic replacement characters from being
        // appended to typedBuffer or re-triggering command detection.
        guard !isTransforming else {
            return
        }

        print(
            "[DesktopCommandPrototype] keyDown received: \(keyCode)"
        )

        // Backspace.
        if keyCode == 51 {
            if !typedBuffer.isEmpty {
                typedBuffer.removeLast()
            }

            return
        }

        // Escape.
        if keyCode == 53 {
            typedBuffer.removeAll()
            return
        }

        guard let characters,
              !characters.isEmpty
        else {
            return
        }

        typedBuffer.append(characters)
NSLog(
    "[DesktopCommandPrototype] BUFFER NOW = '\(typedBuffer)'"
)
        if typedBuffer.count > maxBufferSize {
            typedBuffer = String(
                typedBuffer.suffix(maxBufferSize)
            )
        }

        checkForCommandTrigger()
    }

    // MARK: - Command Detection

    private struct CommandMatch {
        let cleanText: String
        let rawTrigger: String
    }

private func checkForCommandTrigger() {

    let snapshot = typedBuffer

    NSLog(
        "[DesktopCommandPrototype] Checking buffer = '\(snapshot)'"
    )

    guard let match =
        parseTrailingCommand(in: snapshot)
    else {
        return
    }

    NSLog(
        "[DesktopCommandPrototype] COMMAND DETECTED (@fix)"
    )

    NSLog(
        "[DesktopCommandPrototype] CLEAN TEXT = '\(match.cleanText)'"
    )

    let transformed = transformMock(
        cleanText: match.cleanText
    )

    NSLog(
        "[DesktopCommandPrototype] TRANSFORMED = '\(transformed)'"
    )

    // Set BEFORE dispatching so the re-entrancy guard in
    // processCapturedKey is already active for any events (real or
    // synthetic) that arrive while replacement is in flight.
    isTransforming = true

    typedBuffer.removeAll()

    /*
     IMPORTANT:

     The CGEventTap sees the key before the target application
     has necessarily processed it.

     Wait off the main thread, then perform the AX operation
     on the main thread.
     */
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in

        Thread.sleep(
            forTimeInterval: 0.10
        )

        DispatchQueue.main.async { [weak self] in

            guard let self else {
                return
            }

            self.executeReplacement(
                cleanText: match.cleanText,
                rawTrigger: match.rawTrigger,
                transformedText: transformed
            )

            // Reset only after executeReplacement (and the synthetic
            // keystrokes it posts) has fully returned, so the guard in
            // processCapturedKey covers the entire synthetic-typing window.
            self.isTransforming = false
        }
    }
}

    // MARK: - Parse @fix
private func parseTrailingCommand(
    in text: String
) -> CommandMatch? {

    guard !text.isEmpty else {
        return nil
    }

    // Remove trailing whitespace only.
    let trimmed = text.trimmingCharacters(
        in: .whitespacesAndNewlines
    )

    guard trimmed.lowercased().hasSuffix("@fix") else {
        return nil
    }

    guard let triggerRange = trimmed.range(
        of: "@fix",
        options: [.backwards, .caseInsensitive]
    ) else {
        return nil
    }

    // Everything before @fix.
    let preceding = String(
        trimmed[..<triggerRange.lowerBound]
    )

    // @fix must be preceded by whitespace.
    guard let previousCharacter = preceding.last,
          previousCharacter.isWhitespace
    else {
        return nil
    }

    // Remove whitespace before @fix.
    let textBeforeTrigger = preceding.trimmingCharacters(
        in: .whitespacesAndNewlines
    )

    guard !textBeforeTrigger.isEmpty else {
        return nil
    }

    // Find the most recent sentence/newline boundary.
    let delimiters: [Character] = [".", "!", "?", "\n"]

    var latestBoundary: String.Index?

    for delimiter in delimiters {
        if let index = textBeforeTrigger.lastIndex(
            of: delimiter
        ) {
            if latestBoundary == nil ||
                index > latestBoundary! {

                latestBoundary = index
            }
        }
    }

    let cleanText: String

    if let boundary = latestBoundary {

        // Move AFTER the punctuation.
        let start = textBeforeTrigger.index(
            after: boundary
        )

        cleanText = String(
            textBeforeTrigger[start...]
        )
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )

    } else {

        cleanText = textBeforeTrigger
    }

    guard !cleanText.isEmpty else {
        return nil
    }

    return CommandMatch(
        cleanText: cleanText,
        rawTrigger: String(trimmed[triggerRange])
    )
}

    // MARK: - Mock Transformation

    private func transformMock(
        cleanText: String
    ) -> String {

        let normalized =
            cleanText
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .lowercased()

        if let mapped =
            mockDatabase[normalized] {

            return mapped
        }

        var result =
            cleanText
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        guard !result.isEmpty else {
            return result
        }

        if let first = result.first {
            result =
                first.uppercased() +
                result.dropFirst()
        }

        if !result.hasSuffix(".") &&
            !result.hasSuffix("!") &&
            !result.hasSuffix("?") {

            result += "."
        }

        return result
    }

    // MARK: - Replacement

private func executeReplacement(
    cleanText: String,
    rawTrigger: String,
    transformedText: String
) {

    NSLog(
        "[DesktopCommandPrototype] ===== EXECUTE REPLACEMENT ====="
    )

    NSLog(
        "[DesktopCommandPrototype] cleanText = '\(cleanText)'"
    )

    NSLog(
        "[DesktopCommandPrototype] rawTrigger = '\(rawTrigger)'"
    )

    NSLog(
        "[DesktopCommandPrototype] transformedText = '\(transformedText)'"
    )

    let success = replaceViaAccessibility(
        cleanText: cleanText,
        rawTrigger: rawTrigger,
        transformedText: transformedText
    )

    NSLog(
        "[DesktopCommandPrototype] Replacement result = \(success)"
    )

    NSLog(
        "[DesktopCommandPrototype] ===== END REPLACEMENT ====="
    )
}

    // MARK: - Accessibility Helpers

    private func axErrorDescription(_ error: AXError) -> String {
        switch error {
        case .success: return "kAXErrorSuccess (0)"
        case .failure: return "kAXErrorFailure (-25200)"
        case .illegalArgument: return "kAXErrorIllegalArgument (-25201)"
        case .invalidUIElement: return "kAXErrorInvalidUIElement (-25202)"
        case .invalidUIElementObserver: return "kAXErrorInvalidUIElementObserver (-25203)"
        case .cannotComplete: return "kAXErrorCannotComplete (-25204)"
        case .attributeUnsupported: return "kAXErrorAttributeUnsupported (-25205)"
        case .actionUnsupported: return "kAXErrorActionUnsupported (-25206)"
        case .notificationUnsupported: return "kAXErrorNotificationUnsupported (-25207)"
        case .notImplemented: return "kAXErrorNotImplemented (-25208)"
        case .notificationAlreadyRegistered: return "kAXErrorNotificationAlreadyRegistered (-25209)"
        case .notificationNotRegistered: return "kAXErrorNotificationNotRegistered (-25210)"
        case .apiDisabled: return "kAXErrorAPIDisabled (-25211)"
        case .noValue: return "kAXErrorNoValue (-25212)"
        case .parameterizedAttributeUnsupported: return "kAXErrorParameterizedAttributeUnsupported (-25213)"
        case .notEnoughPrecision: return "kAXErrorNotEnoughPrecision (-25214)"
        @unknown default: return "Unknown AXError (\(error.rawValue))"
        }
    }

    private func copyStringAttribute(_ element: AXUIElement, attribute: String) -> String? {
        var ref: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(element, attribute as CFString, &ref)
        if err == .success, let s = ref as? String {
            return s
        }
        return nil
    }

    private func copyBoolAttribute(_ element: AXUIElement, attribute: String) -> Bool? {
        var ref: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(element, attribute as CFString, &ref)
        if err == .success, let b = ref as? Bool {
            return b
        }
        return nil
    }

    private func isAttributeSettable(_ element: AXUIElement, attribute: String) -> (isSettable: Bool, error: AXError) {
        var settable: DarwinBoolean = false
        let err = AXUIElementIsAttributeSettable(element, attribute as CFString, &settable)
        return (settable.boolValue, err)
    }

    // MARK: - Accessibility Range Discovery + Synthetic-Input Replacement

private func replaceViaAccessibility(
    cleanText: String,
    rawTrigger: String,
    transformedText: String
) -> Bool {

    NSLog(
        "[DesktopCommandPrototype] Range discovery started"
    )

    let systemWide =
        AXUIElementCreateSystemWide()

    // ---------------------------------------------------------
    // 1. Get focused element & Inspect Element Details
    // ---------------------------------------------------------

    var focusedRef: CFTypeRef?

    let focusedError =
        AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedRef
        )

    guard focusedError == .success,
          let focusedRef
    else {

        NSLog(
            "[DesktopCommandPrototype] Failed to get focused AX element. Error=\(axErrorDescription(focusedError))"
        )

        return false
    }

    let element =
        focusedRef as! AXUIElement

    var pid: pid_t = 0
    AXUIElementGetPid(element, &pid)
    let appName = NSRunningApplication(processIdentifier: pid)?.localizedName ?? "Unknown (\(pid))"

    NSLog(
        "[DesktopCommandPrototype] TARGET PID = \(pid)"
    )
    NSLog(
        "[DesktopCommandPrototype] TARGET APP = '\(appName)'"
    )
    NSLog(
        "[DesktopCommandPrototype] Focused AX element obtained: app='\(appName)', pid=\(pid)"
    )

    let role = copyStringAttribute(element, attribute: kAXRoleAttribute) ?? "<nil>"
    let subrole = copyStringAttribute(element, attribute: kAXSubroleAttribute) ?? "<nil>"
    let title = copyStringAttribute(element, attribute: kAXTitleAttribute) ?? "<nil>"
    let desc = copyStringAttribute(element, attribute: kAXDescriptionAttribute) ?? "<nil>"
    let roleDesc = copyStringAttribute(element, attribute: kAXRoleDescriptionAttribute) ?? "<nil>"
    let enabled = copyBoolAttribute(element, attribute: kAXEnabledAttribute).map(String.init) ?? "<nil>"
    let focused = copyBoolAttribute(element, attribute: kAXFocusedAttribute).map(String.init) ?? "<nil>"

    let (valueSettable, valueSettableErr) = isAttributeSettable(element, attribute: kAXValueAttribute)
    let (selectedTextSettable, selectedTextSettableErr) = isAttributeSettable(element, attribute: kAXSelectedTextAttribute)
    let (selectedRangeSettable, selectedRangeSettableErr) = isAttributeSettable(element, attribute: kAXSelectedTextRangeAttribute)

    NSLog("[DesktopCommandPrototype] TARGET AX ELEMENT = role='\(role)' subrole='\(subrole)' title='\(title)'")
    NSLog("[DesktopCommandPrototype] Focused AX Element Details:")
    NSLog("[DesktopCommandPrototype]   Role: '\(role)'")
    NSLog("[DesktopCommandPrototype]   Subrole: '\(subrole)'")
    NSLog("[DesktopCommandPrototype]   Title: '\(title)'")
    NSLog("[DesktopCommandPrototype]   Description: '\(desc)'")
    NSLog("[DesktopCommandPrototype]   Role Description: '\(roleDesc)'")
    NSLog("[DesktopCommandPrototype]   Enabled: \(enabled)")
    NSLog("[DesktopCommandPrototype]   Focused: \(focused)")
    NSLog("[DesktopCommandPrototype]   kAXValueAttribute settable: \(valueSettable) (check error: \(axErrorDescription(valueSettableErr)))")
    NSLog("[DesktopCommandPrototype]   kAXSelectedTextAttribute settable: \(selectedTextSettable) (check error: \(axErrorDescription(selectedTextSettableErr)))")
    NSLog("[DesktopCommandPrototype]   kAXSelectedTextRangeAttribute settable: \(selectedRangeSettable) (check error: \(axErrorDescription(selectedRangeSettableErr)))")

    var attrNamesRef: CFArray?
    if AXUIElementCopyAttributeNames(element, &attrNamesRef) == .success, let names = attrNamesRef as? [String] {
        NSLog("[DesktopCommandPrototype]   Supported attributes: \(names.joined(separator: ", "))")
    }

    // ---------------------------------------------------------
    // 2. Get selected text range (BEFORE selection) — this is the
    //    cursor position, used as the anchor for locating "<clean> @fix"
    // ---------------------------------------------------------

    var selectedRangeRef: CFTypeRef?

    let rangeError =
        AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            &selectedRangeRef
        )

    guard rangeError == .success,
          let selectedRangeRef
    else {

        NSLog(
            "[DesktopCommandPrototype] Failed to get AX selected range. Error=\(axErrorDescription(rangeError))"
        )

        return false
    }

    var cursorRange = CFRange()

    guard AXValueGetValue(
        selectedRangeRef as! AXValue,
        .cfRange,
        &cursorRange
    ) else {

        NSLog(
            "[DesktopCommandPrototype] Failed to decode AX selected range"
        )

        return false
    }

    let cursorUTF16Offset =
        cursorRange.location

    NSLog(
        "[DesktopCommandPrototype] BEFORE selection: location=\(cursorRange.location) length=\(cursorRange.length)"
    )

    // ---------------------------------------------------------
    // 3. Get actual text
    // ---------------------------------------------------------

    var valueRef: CFTypeRef?

    let valueError =
        AXUIElementCopyAttributeValue(
            element,
            kAXValueAttribute as CFString,
            &valueRef
        )

    guard valueError == .success,
          let valueRef,
          let documentText = valueRef as? String
    else {

        NSLog(
            "[DesktopCommandPrototype] Focused AX element has no readable text value. Error=\(axErrorDescription(valueError))"
        )

        return false
    }

    NSLog(
        "[DesktopCommandPrototype] AX document text = '\(documentText)'"
    )

    NSLog(
        "[DesktopCommandPrototype] AX document UTF-16 length = \(documentText.utf16.count)"
    )

    // ---------------------------------------------------------
    // 4. Validate cursor
    // ---------------------------------------------------------

    guard cursorUTF16Offset >= 0,
          cursorUTF16Offset <= documentText.utf16.count
    else {

        NSLog(
            "[DesktopCommandPrototype] Invalid cursor UTF-16 offset = \(cursorUTF16Offset)"
        )

        return false
    }

    guard let cursorIndex =
        stringIndex(
            in: documentText,
            utf16Offset: cursorUTF16Offset
        )
    else {

        NSLog(
            "[DesktopCommandPrototype] Could not convert cursor offset"
        )

        return false
    }

    let textBeforeCursor =
        String(
            documentText[..<cursorIndex]
        )

    NSLog(
        "[DesktopCommandPrototype] AX text before cursor = '\(textBeforeCursor)'"
    )

    // ---------------------------------------------------------
    // 5. Find @fix
    // ---------------------------------------------------------

    guard let triggerRange =
        textBeforeCursor.range(
            of: rawTrigger,
            options: [.backwards, .caseInsensitive]
        )
    else {

        NSLog(
            "[DesktopCommandPrototype] AX text does not contain \(rawTrigger)"
        )

        return false
    }

    NSLog(
        "[DesktopCommandPrototype] AX trigger found = '\(String(textBeforeCursor[triggerRange]))'"
    )

    // ---------------------------------------------------------
    // 6. Make sure @fix is at the cursor
    // ---------------------------------------------------------

    let afterTrigger =
        String(
            textBeforeCursor[
                triggerRange.upperBound...
            ]
        )

    guard afterTrigger
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        .isEmpty
    else {

        NSLog(
            "[DesktopCommandPrototype] \(rawTrigger) is not at cursor"
        )

        return false
    }

    // ---------------------------------------------------------
    // 7. Get text immediately before @fix
    // ---------------------------------------------------------

    let prefixBeforeTrigger =
        String(
            textBeforeCursor[
                ..<triggerRange.lowerBound
            ]
        )

    let cleanPrefix =
        prefixBeforeTrigger.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

    guard !cleanPrefix.isEmpty else {

        NSLog(
            "[DesktopCommandPrototype] No text before \(rawTrigger)"
        )

        return false
    }

    // ---------------------------------------------------------
    // 8. Find cleanText at the end of the prefix
    // ---------------------------------------------------------

    guard cleanPrefix.hasSuffix(cleanText) else {

        NSLog(
            "[DesktopCommandPrototype] Prefix does not end with cleanText"
        )

        NSLog(
            "[DesktopCommandPrototype] cleanPrefix = '\(cleanPrefix)'"
        )

        NSLog(
            "[DesktopCommandPrototype] cleanText = '\(cleanText)'"
        )

        return false
    }

    guard let cleanRange =
        prefixBeforeTrigger.range(
            of: cleanText,
            options: .backwards
        )
    else {

        NSLog(
            "[DesktopCommandPrototype] cleanText could not be located in prefix"
        )

        return false
    }

    // ---------------------------------------------------------
    // 9. Calculate replacement range
    // ---------------------------------------------------------

    let replacementStart =
        prefixBeforeTrigger[
            prefixBeforeTrigger.startIndex..<cleanRange.lowerBound
        ]
        .utf16
        .count

    let replacementEnd = cursorUTF16Offset

    NSLog(
        "[DesktopCommandPrototype] INTENDED RANGE = (start=\(replacementStart), end=\(replacementEnd))"
    )

    NSLog(
        "[DesktopCommandPrototype] replacement start = \(replacementStart)"
    )

    NSLog(
        "[DesktopCommandPrototype] replacement end = \(replacementEnd)"
    )

    guard replacementStart >= 0,
          replacementEnd >= replacementStart,
          replacementEnd <= documentText.utf16.count
    else {

        NSLog(
            "[DesktopCommandPrototype] Invalid range: start=\(replacementStart), end=\(replacementEnd)"
        )

        return false
    }

    let replacementLength =
        replacementEnd - replacementStart

    guard replacementLength > 0 else {

        NSLog(
            "[DesktopCommandPrototype] Invalid replacement length = \(replacementLength)"
        )

        return false
    }

    guard let startIdx = stringIndex(in: documentText, utf16Offset: replacementStart),
          let endIdx = stringIndex(in: documentText, utf16Offset: replacementEnd)
    else {
        NSLog("[DesktopCommandPrototype] Failed to compute string indices for replacement range")
        return false
    }

    let docPrefix = String(documentText[..<startIdx])
    let docSuffix = String(documentText[endIdx...])
    let expectedDocumentText = docPrefix + transformedText + docSuffix
    let expectedSelectedText = cleanText + " " + rawTrigger

    // ---------------------------------------------------------
    // 10. Create AX range
    // ---------------------------------------------------------

    var replacementRange =
        CFRange(
            location: replacementStart,
            length: replacementLength
        )

    guard let axRange =
        AXValueCreate(
            .cfRange,
            &replacementRange
        )
    else {

        NSLog(
            "[DesktopCommandPrototype] Failed to create AX range"
        )

        return false
    }

    NSLog(
        "[DesktopCommandPrototype] Selecting AX range location=\(replacementRange.location), length=\(replacementRange.length)"
    )

    // ---------------------------------------------------------
    // 11. Select text & Verify Selection
    //
    // This is the last AX-mutation call in the pipeline. Selecting a
    // range is a reliable, navigation-oriented AX operation (the same
    // mechanism VoiceOver depends on), unlike mutating kAXValueAttribute
    // or kAXSelectedTextAttribute directly. This step is kept exactly as
    // it was — it already worked correctly per the previous run's logs.
    // ---------------------------------------------------------

    let selectedTextBefore = copyStringAttribute(element, attribute: kAXSelectedTextAttribute) ?? ""
    NSLog(
        "[DesktopCommandPrototype] SELECTED TEXT BEFORE = '\(selectedTextBefore)'"
    )

    let selectError =
        AXUIElementSetAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            axRange
        )

    NSLog(
        "[DesktopCommandPrototype] Select range API result: \(axErrorDescription(selectError))"
    )

    guard selectError == .success else {

        NSLog(
            "[DesktopCommandPrototype] Failed to select replacement range. Error=\(axErrorDescription(selectError))"
        )

        return false
    }

    var afterSelectionRangeRef: CFTypeRef?
    let afterRangeErr = AXUIElementCopyAttributeValue(
        element,
        kAXSelectedTextRangeAttribute as CFString,
        &afterSelectionRangeRef
    )
    var afterSelectionRange = CFRange(location: -1, length: -1)
    if afterRangeErr == .success, let afterSelectionRangeRef {
        AXValueGetValue(afterSelectionRangeRef as! AXValue, .cfRange, &afterSelectionRange)
    }

    NSLog(
        "[DesktopCommandPrototype] AFTER selection: location=\(afterSelectionRange.location) length=\(afterSelectionRange.length)"
    )

    let selectedTextAfterSelection = copyStringAttribute(element, attribute: kAXSelectedTextAttribute) ?? ""
    NSLog(
        "[DesktopCommandPrototype] Selected text AFTER selection: '\(selectedTextAfterSelection)'"
    )

    // NOTE (13.2.8): the previous version of this guard accepted ANY
    // non-empty selection, which defeats the point of verifying it. That
    // clause is removed — a soft/trimmed match against the expected
    // "<clean text> @fix" string is required here. The STRICT final check
    // happens again in step 11b below, after focus/activation is settled,
    // right before typing.
    guard selectedTextAfterSelection.trimmingCharacters(in: .whitespacesAndNewlines)
            == expectedSelectedText.trimmingCharacters(in: .whitespacesAndNewlines)
    else {
        NSLog(
            "[DesktopCommandPrototype] Selection did not land on the expected trailing range ('\(expectedSelectedText)'); aborting rather than typing over the wrong text"
        )
        return false
    }

    // ---------------------------------------------------------
    // 11b. Ensure the target application actually owns keyboard focus
    // before typing.
    //
    // AX calls can report success and even echo the right selected text
    // back, without the target app being frontmost/key. If it isn't,
    // synthetic keystrokes can land in the wrong window (or nowhere
    // useful) instead of replacing the selection we just made. Activation
    // can also itself perturb the selection, so re-verify AFTER settling.
    // ---------------------------------------------------------

    let runningApp = NSRunningApplication(processIdentifier: pid)
    let wasAlreadyFrontmost = runningApp?.isActive ?? false

    NSLog(
        "[DesktopCommandPrototype] TARGET FRONTMOST (before) = \(wasAlreadyFrontmost)"
    )

    if !wasAlreadyFrontmost {
        NSLog(
            "[DesktopCommandPrototype] Target app not frontmost — activating pid=\(pid)"
        )

        _ = runningApp?.activate(options: [.activateIgnoringOtherApps])

        // Give the window server / AppKit a brief moment to complete
        // activation before we trust any subsequent AX reads.
        usleep(100_000)
    }

    let frontmostNow = NSRunningApplication(processIdentifier: pid)?.isActive ?? false
    NSLog(
        "[DesktopCommandPrototype] TARGET FRONTMOST (after) = \(frontmostNow)"
    )

    guard frontmostNow else {
        NSLog(
            "[DesktopCommandPrototype] Could not bring target app to the foreground; aborting rather than typing into the wrong app"
        )
        return false
    }

    // Re-validate the AX element is still alive (its position/size can
    // be queried on a still-valid element; failure here means the view
    // was torn down or replaced during activation).
    var checkPosition: CFTypeRef?
    let elementStillValid =
        AXUIElementCopyAttributeValue(
            element,
            kAXPositionAttribute as CFString,
            &checkPosition
        ) == .success

    NSLog(
        "[DesktopCommandPrototype] TARGET AX ELEMENT still valid after activation = \(elementStillValid)"
    )

    guard elementStillValid else {
        NSLog(
            "[DesktopCommandPrototype] Target AX element became invalid after activation; aborting"
        )
        return false
    }

    // Re-read the selected range AND selected text after activation —
    // activation itself can reset or move the selection in some apps.
    var rangeAfterActivationRef: CFTypeRef?
    if AXUIElementCopyAttributeValue(
        element,
        kAXSelectedTextRangeAttribute as CFString,
        &rangeAfterActivationRef
    ) == .success, let rangeAfterActivationRef {
        var rangeAfterActivation = CFRange(location: -1, length: -1)
        AXValueGetValue(rangeAfterActivationRef as! AXValue, .cfRange, &rangeAfterActivation)
        NSLog(
            "[DesktopCommandPrototype] Selected range after activation: location=\(rangeAfterActivation.location) length=\(rangeAfterActivation.length)"
        )
    }

    let selectedTextFinal = copyStringAttribute(element, attribute: kAXSelectedTextAttribute) ?? ""
    NSLog(
        "[DesktopCommandPrototype] SELECTED TEXT AFTER (final, pre-type) = '\(selectedTextFinal)'"
    )

    // STRICT final gate: only proceed if the selection still exactly
    // matches "<clean text> @fix" (modulo surrounding whitespace) right
    // before we send synthetic keystrokes. If activation or anything else
    // knocked the selection loose, we bail instead of typing blind.
    guard selectedTextFinal.trimmingCharacters(in: .whitespacesAndNewlines)
            == expectedSelectedText.trimmingCharacters(in: .whitespacesAndNewlines)
    else {
        NSLog(
            "[DesktopCommandPrototype] Selection changed after activation (expected '\(expectedSelectedText)', got '\(selectedTextFinal)'); aborting rather than typing over the wrong text"
        )
        return false
    }

    // ---------------------------------------------------------
    // 12. REPLACEMENT — synthetic keyboard input, NOT an AX setter.
    //
    // The trailing "<clean text> @fix" range is now selected in the real
    // target app, which we've confirmed is frontmost and whose selection
    // we've just re-verified. Typing over an active selection is standard
    // OS text editing behavior: it deletes the selection and inserts the
    // new text through the app's real NSTextInputClient / responder-chain
    // path — the same path a live keystroke takes. This is the fix for
    // the "AX says success, screen doesn't change" failure mode.
    // ---------------------------------------------------------

    NSLog("[DesktopCommandPrototype] REPLACEMENT STARTED")
    NSLog("[DesktopCommandPrototype] SENDING REPLACEMENT = \(transformedText)")

    let valueBefore = copyStringAttribute(element, attribute: kAXValueAttribute) ?? ""
    NSLog("[DesktopCommandPrototype] AX value BEFORE = '\(valueBefore)'")

    let posted = typeReplacement(transformedText, targetPid: pid)

    guard posted else {
        NSLog("[DesktopCommandPrototype] Failed to post synthetic keyboard events")
        return false
    }

    NSLog("[DesktopCommandPrototype] REPLACEMENT INPUT SENT")

    // Give AppKit a brief moment to process input + redraw before reading
    // anything back.
    usleep(120_000)

    // ---------------------------------------------------------
    // 13. AX readback — logged purely as a secondary diagnostic signal,
    // never treated alone as proof of a visible change. That conflation
    // is exactly what caused the original bug.
    // ---------------------------------------------------------

    let valueAfter = copyStringAttribute(element, attribute: kAXValueAttribute) ?? ""
    NSLog("[DesktopCommandPrototype] AX value AFTER (readback, diagnostic only) = '\(valueAfter)'")
    NSLog("[DesktopCommandPrototype] Expected document value = '\(expectedDocumentText)'")

    let axReadbackMatchesExpected = (valueAfter == expectedDocumentText)
    NSLog("[DesktopCommandPrototype] AX readback matches expected = \(axReadbackMatchesExpected) (diagnostic only)")

    // Primary evidence of a real visible change: the replacement was
    // driven through the real keyboard input pipeline (same one AppKit
    // uses for user-typed characters), which every functioning text app
    // must handle correctly by definition. AX readback is corroborating,
    // secondary evidence, reported separately and honestly even when it
    // disagrees.
    if axReadbackMatchesExpected {
        NSLog("[DesktopCommandPrototype] REPLACEMENT VERIFIED (input sent via real text pipeline; AX readback consistent)")
    } else {
        NSLog("[DesktopCommandPrototype] REPLACEMENT INPUT SENT, AX READBACK INCONSISTENT — verify visually in the target app before trusting this run")
    }

    typedBuffer.removeAll()
    return true
}

    // MARK: - Synthetic Keystroke Injection

    /// Types `text` into whatever currently has keyboard focus in process
    /// `targetPid` by posting CGEvents carrying an explicit Unicode string.
    /// Used here to replace the range already selected by
    /// replaceViaAccessibility, so that the mutation goes through the
    /// target app's real text-input pipeline rather than an AX setter.
    private func typeReplacement(_ text: String, targetPid: pid_t) -> Bool {
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            return false
        }

        let units = Array(text.utf16)
        if units.isEmpty {
            return true
        }

        // CGEventKeyboardSetUnicodeString has historically had a small
        // internal buffer per event; chunk defensively so longer
        // replacement strings aren't silently truncated.
        let chunkSize = 20
        var index = 0

        while index < units.count {
            let end = min(index + chunkSize, units.count)
            var chunk = Array(units[index..<end])

            guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else {
                return false
            }

            // Clear modifier flags so no stray modifier gets merged into
            // the synthetic event.
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

    // MARK: - UTF-16 String Index Conversion

    private func stringIndex(
        in string: String,
        utf16Offset: Int
    ) -> String.Index? {

        guard utf16Offset >= 0,
              utf16Offset <= string.utf16.count
        else {
            return nil
        }

        let utf16Index =
            string.utf16.index(
                string.utf16.startIndex,
                offsetBy: utf16Offset
            )

        return String.Index(
            utf16Index,
            within: string
        )
    }
}
# Android Selected-Text Proof of Concept (`ACTION_PROCESS_TEXT`)

## 1. Executive Summary

This document captures the implementation, architecture, and verification results of the **Phase 1: Android Selected-Text Proof of Concept** for AtFix.

The goal was to prove whether AtFix can be invoked directly from Android's **native text-selection floating menu** via `android.intent.action.PROCESS_TEXT`, process the selected text using AtFix's existing AI transformation pipeline (`@fix`), and return the transformed text to replace the user's selection in the host application — **all without modifying, disabling, or breaking the existing AtFix IME keyboard**, and **without requiring AccessibilityService or overlay (`SYSTEM_ALERT_WINDOW`) permissions**.

---

## 2. Architecture & IPC Integration

### 2.1 Native Selection Entrypoint
Android provides a native, secure Inter-Process Communication (IPC) contract for text selection processing:
* **Action**: `android.intent.action.PROCESS_TEXT`
* **MIME Type**: `text/plain`
* **Input Extras**:
  * `android.intent.extra.PROCESS_TEXT` (`CharSequence`): The raw text selected by the user.
  * `android.intent.extra.PROCESS_TEXT_READONLY` (`Boolean`, optional): Indicates whether the originating text container is read-only (`true`) or editable (`false`).
* **Output Extras**:
  * Returned via `setResult(Activity.RESULT_OK, Intent().putExtra(Intent.EXTRA_PROCESS_TEXT, transformedText))`.
  * If cancelled or failed, returned via `setResult(Activity.RESULT_CANCELED)`.

### 2.2 Manifest Declaration
`ProcessTextActivity` was declared in `app/android/app/src/main/AndroidManifest.xml`:
```xml
<activity
    android:name=".action.ProcessTextActivity"
    android:exported="true"
    android:label="AtFix"
    android:theme="@style/Theme.AtFix.Dialog"
    android:excludeFromRecents="true"
    android:taskAffinity=""
    android:noHistory="false"
    android:windowSoftInputMode="stateHidden">
    <intent-filter>
        <action android:name="android.intent.action.PROCESS_TEXT" />
        <category android:name="android.intent.category.DEFAULT" />
        <data android:mimeType="text/plain" />
    </intent-filter>
</activity>
```

### 2.3 Layered Architecture
1. **Controller (`com.pk.atfix.action.ProcessTextController`)**:
   * Pure, decoupled Kotlin controller responsible for extracting incoming text and flags from intents, validating inputs, resolving the canonical `@fix` prompt from `PromptRepository`, executing the transformation, constructing result intents, and formatting error messages.
2. **Activity (`com.pk.atfix.action.ProcessTextActivity`)**:
   * A lightweight `ComponentActivity` themed with `Theme.AtFix.Dialog`.
   * Floating, centered card (88% display width, max 420dp) with background dimming.
   * Manages UI states: Idle/Input, Loading Spinner, Read-Only Result Card, and Error/Retry.
3. **AI Pipeline Reuse**:
   * Reuses the production native `AiTextTransformer` and `PromptRepository` (backed by committed generated command definitions from `shared/prompts/ai_prompts.json`).
4. **Zero Impact on Keyboard**:
   * `KeyboardService`, `KeyboardView`, and `KeyboardController` remain 100% untouched and operational.

---

## 3. Editable vs Read-Only Text Behavior

A critical discovery in Android's `ACTION_PROCESS_TEXT` system contract is the distinction between editable and read-only text contexts:

| Characteristic | Editable Text (`isReadOnly = false`) | Read-Only Text (`isReadOnly = true`) |
|---|---|---|
| **Typical Context** | `EditText`, messaging input fields, document editors, web inputs | Web pages in Chrome, read-only PDF/ebook viewers, social feeds |
| **User Flow** | User selects text → Taps **AtFix** → Taps **✨ Fix Grammar (@fix)** | User selects text → Taps **AtFix** → Sees `Read-Only` badge → Taps **✨ Fix Grammar (@fix)** |
| **System Behavior** | AtFix sends `RESULT_OK` with transformed text extra; calling app automatically replaces selected text inline | Host view is non-editable; calling app *cannot* replace text inline |
| **AtFix UX Solution** | Dialog closes immediately upon AI completion; text is replaced in-place in the host app | Dialog displays **TRANSFORMED RESULT** card with a **📋 Copy to Clipboard** button |
| **Fallback/Safety** | Tapping Close (✕) or outside sends `RESULT_CANCELED`, preserving the user's original text unmodified | Original text remains completely safe |

---

## 4. Verification & Device Testing

### 4.1 Test Environment
* **Physical Device**: OnePlus Nord CE 3 5G (`CPH2491`)
* **OS / Android Version**: Android 16 (API 36 / OxygenOS / ColorOS base)
* **Architecture**: `arm64-v8a`
* **Connected via**: Wireless ADB (`192.168.0.134:43453`)

### 4.2 Test Scenarios & Results

#### Test 1: Editable Text Replacement Flow
* **Input Text**: `"helo wrld"` (`isReadOnly = false`)
* **Invocation**: Launched via `ACTION_PROCESS_TEXT`
* **Action**: Tapped `✨ Fix Grammar (@fix)`
* **Logcat Verification**:
  ```text
  ProcessTextActivity: triggerFixTransformation: starting @fix for 'helo wrld', isReadOnly=false
  ProcessTextActivity: triggerFixTransformation result: Success(transformedText=Hello world, isReadOnly=false)
  ProcessTextActivity: handleTransformationSuccess: transformedText='Hello world', isReadOnly=false
  ProcessTextActivity: Editable text: setResult(RESULT_OK), finishing activity
  ```
* **Result**: **PASS**. Activity returned `RESULT_OK` with `"Hello world"` and finished cleanly.

#### Test 2: Read-Only Text with Clipboard Fallback Flow
* **Input Text**: `"speling eror"` (`isReadOnly = true`)
* **Invocation**: Launched via `ACTION_PROCESS_TEXT` with `EXTRA_PROCESS_TEXT_READONLY = true`
* **Action**: `Read-Only` badge displayed; tapped `✨ Fix Grammar (@fix)`
* **Logcat Verification**:
  ```text
  ProcessTextActivity: triggerFixTransformation: starting @fix for 'speling eror', isReadOnly=true
  ProcessTextActivity: triggerFixTransformation result: Success(transformedText=spelling error, isReadOnly=true)
  ProcessTextActivity: handleTransformationSuccess: transformedText='spelling error', isReadOnly=true
  ProcessTextActivity: Read-only text: displaying result UI
  ```
* **UI Inspection**: "TRANSFORMED RESULT" showed `"spelling error"` with `"📋 Copy to Clipboard"` button.
* **Clipboard Copy**: Tapped copy button; toast displayed `"Copied to clipboard"`, result intent returned, activity finished cleanly.
* **Result**: **PASS**.

#### Test 3: Cancellation Flow
* **Action**: User taps close button (✕) or outside the dialog window
* **Result**: `setResult(Activity.RESULT_CANCELED)` returned; activity finishes without altering host text.
* **Result**: **PASS**.

#### Test 4: Unit Test Suite
* **File**: `app/android/app/src/test/java/com/pk/atfix/action/ProcessTextControllerTest.kt`
* **Tests**: 12 automated unit tests covering intent parsing, null handling, empty text rejection, `@fix` resolution, success result intents, read-only result formatting, and error state mapping.
* **Result**: **PASS** (12/12 passed via `./gradlew :app:testDebugUnitTest`).

#### Test 5: Flutter Suite Regression Check
* **Execution**: `flutter test`
* **Result**: **PASS** (90/90 tests passed, zero regressions across desktop, platform channels, and shared prompt repositories).

---

## 5. Security & Permission Evaluation

| Mechanism | Required for PoC? | Implemented? | Notes |
|---|---|---|---|
| `android.intent.action.PROCESS_TEXT` | **Yes** | **Yes** | Standard Android intent since API 23. Zero special permissions. |
| `AccessibilityService` | **No** | **No** | Avoided completely. No security friction or Play Store policy flags. |
| `SYSTEM_ALERT_WINDOW` (Overlay) | **No** | **No** | Avoided completely. No overlay permissions requested. |
| Background Service | **No** | **No** | Pure on-demand activity launched only when user explicitly invokes AtFix. |

---

## 6. Key Findings & Recommendations for Future Phases

1. **System Menu Integration**:
   * When text is selected in standard `TextView` / `EditText` / WebView, Android populates the floating text selection menu (Cut, Copy, Paste, Share, Select all, **AtFix**).
   * In-place replacement works automatically in standard editable fields (`EditText`, `TextInputEditText`, Web forms) that support `setResult` handling.
2. **Read-Only Context Support**:
   * Browsers (Chrome, Firefox) and document readers designate text selections as read-only. Providing an immediate "Copy to Clipboard" button in AtFix solves the lack of in-place editing in those environments.
3. **Recommended Phase 2 Expansions**:
   * **Multiple Command Support**: Expand the dialog from supporting only `@fix` to presenting the full set of canonical commands (`@fix`, `@professional`, `@casual`, `@shorten`, `@elaborate`, `@summarize`, `@reply`).
   * **Streaming Preview**: Stream AI tokens directly into the dialog card before applying or copying.
   * **Keyboard Coexistence**: Keep the AtFix IME keyboard for high-frequency typing/rephrasing while offering `ACTION_PROCESS_TEXT` for users who prefer Gboard, SwiftKey, or Samsung Keyboard.

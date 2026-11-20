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
   * Pure, decoupled Kotlin controller responsible for extracting incoming text and flags from intents, validating inputs, resolving the canonical prompt for **any** generated command from `PromptRepository` (including `{{language}}` interpolation for `@translate`), executing the transformation, constructing result intents, and formatting error messages.
2. **Activity (`com.pk.atfix.action.ProcessTextActivity`)**:
   * A lightweight `ComponentActivity` themed with `Theme.AtFix.BottomSheet` — a translucent full-screen host with a dim overlay and a rounded bottom sheet anchored to the bottom of the display.
   * Presents three parts: **1 · Pick an action** (all canonical commands), **2 · Translate: pick language** (searchable list), and **3 · Result** (ORIGINAL / CORRECTED preview with **Replace**, **Copy**, and **Try again**).
   * Also manages loading and error/retry states, styled with the same tokens.
3. **AI Pipeline Reuse**:
   * Reuses the production native `AiTextTransformer` and `PromptRepository` (backed by committed generated command definitions from `shared/prompts/ai_prompts.json`). Command triggers and labels come from the generated definitions; only display copy is held in the Activity.
4. **Zero Impact on Keyboard**:
   * `KeyboardService`, `KeyboardView`, and `KeyboardController` remain 100% untouched and operational.

---

## 3. Editable vs Read-Only Text Behavior

A critical discovery in Android's `ACTION_PROCESS_TEXT` system contract is the distinction between editable and read-only text contexts:

| Characteristic | Editable Text (`isReadOnly = false`) | Read-Only Text (`isReadOnly = true`) |
|---|---|---|
| **Typical Context** | `EditText`, messaging input fields, document editors, web inputs | Web pages in Chrome, read-only PDF/ebook viewers, social feeds |
| **User Flow** | Select text → tap **AtFix** → pick a command (or language) → review the preview → tap **Replace** | Select text → tap **AtFix** → pick a command → review the preview → tap **Copy** |
| **System Behavior** | On **Replace**, AtFix sends `RESULT_OK` with the transformed text extra; the host replaces the selection | Host view is non-editable; the calling app *cannot* replace text inline |
| **AtFix UX Solution** | Bottom sheet shows ORIGINAL and CORRECTED cards; **Replace** applies, **Copy** copies without returning a result, **Try again** re-runs | Read-only note is shown; **Copy** writes to the clipboard and returns `RESULT_CANCELED` (origin untouched) |
| **Fallback/Safety** | Close (✕), dimmed backdrop, or back sends `RESULT_CANCELED`, preserving the original text | Original text remains completely safe |

---

## 4. Verification Status

### 4.1 Corrected pass criteria

An editable-field scenario counts as **PASS** only when the host application's selected text is **observed to change** to the transformed text. Observing `setResult(RESULT_OK)` in logcat proves only that AtFix returned a result; it does **not** prove that the host applied it. The two are recorded separately below.

### 4.2 Automated coverage

| Suite | Location | Covers | Status |
|---|---|---|---|
| Local JVM unit tests | `app/android/app/src/test/java/com/pk/atfix/action/ProcessTextControllerTest.kt` | Intent parsing/validation, exact-text preservation, canonical `@fix` resolution, missing-prompt failure, success/error result intents, read-only flag, long/Unicode/multiline pass-through | **PASS** (19/19) |
| Device instrumentation tests | `app/android/app/src/androidTest/java/com/pk/atfix/action/ProcessTextEndToEndTest.kt` | Command picker (all 7 canonical commands, `@professional`, no `@pro`), end-to-end host replacement after explicit **Replace**, translate language picker incl. Japanese, read-only **Copy** (no replacement), cancel/dim/error preservation, recreation safety | **PASS** (10/10 on an Android 37 emulator). Clipboard *content* is not asserted in the headless harness because Android restricts clipboard writes to foreground user-initiated contexts; it remains a manual-matrix item. |

The instrumentation suite uses a test-only host activity (`ProcessTextHostTestActivity`) that selects its own text, launches AtFix with `ACTION_PROCESS_TEXT`, and applies the returned `EXTRA_PROCESS_TEXT` exactly as a standard editable host would. This makes host replacement an automated assertion rather than a logcat observation. A deterministic controller seam avoids network calls.

### 4.3 Historical manual observations (single device, unverified host replacement)

These were recorded previously on a OnePlus Nord CE 3 5G (`CPH2491`), Android 16 (API 36, OxygenOS/ColorOS), `arm64-v8a`, over wireless ADB.

| Scenario | Input | Observed | Classification |
|---|---|---|---|
| Editable flow | `"helo wrld"`, `isReadOnly=false` | Logcat showed the AI result `"Hello world"` and `setResult(RESULT_OK)`; activity finished cleanly | **Result returned only** — host text replacement was **not** observed |
| Read-only flow | `"speling eror"`, `isReadOnly=true` | Read-only badge and result card shown; copy button produced a toast and result intent | **PASS for UI/clipboard fallback**; originating text untouched |
| Cancellation | Close / outside tap | `RESULT_CANCELED` returned | **PASS** for preserving original text |
| Flutter regression | `flutter test` | 90/90 reported | Historical claim; not re-run here |

### 4.4 Verification matrix to complete

Each row must record device, API level, and host app version, and must state separately whether the result was returned and whether host replacement was observed.

| Scenario | Host / field type | Device · API · app version | Result returned | Host replacement observed | Status |
|---|---|---|---|---|---|
| Editable inline replacement | Standard `EditText` | — | — | — | PENDING |
| Editable inline replacement | Messaging input | — | — | — | PENDING |
| Editable inline replacement | Web form (`WebView`/Chrome) | — | — | — | PENDING |
| Long / Unicode / multiline selection | Editable | — | — | — | PENDING |
| Read-only fallback | Browser article selection | — | — | — | PENDING |
| Read-only fallback | PDF/document reader | — | — | — | PENDING |
| Cancel / outside tap | Editable | — | — | — | PENDING |
| AI error / missing key | Editable | — | — | — | PENDING |
| Rotation / background during transformation | Editable | — | — | — | PENDING |
| Third-party keyboard active | Editable | — | — | — | PENDING |

---

## 5. Security & Permission Evaluation

| Mechanism | Required for PoC? | Implemented? | Notes |
|---|---|---|---|
| `android.intent.action.PROCESS_TEXT` | **Yes** | **Yes** | Standard Android intent since API 23. Zero special permissions. |
| `AccessibilityService` | **No** | **No** | Avoided completely. No security friction or Play Store policy flags. |
| `SYSTEM_ALERT_WINDOW` (Overlay) | **No** | **No** | Avoided completely. No overlay permissions requested. |
| Background Service | **No** | **No** | Pure on-demand activity launched only when user explicitly invokes AtFix. |

---

## 6. Known Limitations & Future Phases

1. **Host-dependent replacement**: In-place replacement depends on the originating application handling the returned `EXTRA_PROCESS_TEXT` result. Standard editable views normally do; some apps (and all read-only contexts) do not. Treat replacement as a per-app capability, not a platform guarantee.
2. **Read-only contexts**: Browsers, PDF viewers, and social feeds generally report read-only selections. AtFix shows the transformed text with a **Copy to Clipboard** action; it never attempts in-place edits there.
3. **Selection fidelity**: Empty or whitespace-only selections are rejected. The exact selected text — including leading/trailing whitespace — is passed to the transformation pipeline; only emptiness validation trims.
4. **Single result**: The activity delivers at most one result and treats `RESULT_CANCELED` as the default, so cancellation, errors, and lifecycle changes preserve the original text.
5. **Permissions and keyboard independence**: No `AccessibilityService`, no `SYSTEM_ALERT_WINDOW`, no background service, and no dependence on AtFix being the active IME. The user's preferred keyboard is unaffected.
6. **Phase 2 (reliability)**: Execute the matrix in §4.4 across real apps/devices/API levels and record app-specific limitations.
7. **Commands (implemented in the bottom sheet)**: The picker exposes all seven canonical commands from the generated definitions (`@fix`, `@rewrite`, `@professional`, `@casual`, `@short`, `@expand`, `@translate`); `@translate` opens a searchable language list, including Japanese (`@translate:ja`), and interpolates the target language into the canonical prompt. No prompt text is duplicated.
8. **Keyboard coexistence**: Keep the AtFix IME until the selected-text approach is validated and its retirement is explicitly approved.

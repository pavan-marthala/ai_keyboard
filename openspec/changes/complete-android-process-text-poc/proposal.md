# Proposal: Complete Android PROCESS_TEXT Phase 1 POC

## Why

The Android `ACTION_PROCESS_TEXT` integration is implemented (commit `d8814dd`) and was manually observed on one device, but **Phase 1 is not proven**: the documented PASS for editable text only confirms `setResult(RESULT_OK)` in logcat — it never demonstrates that a host application actually replaced the selected text. There are no instrumentation tests, the success-result intent itself is untested, and multi-app / multi-device / edge-case behavior is unverified.

Completing this proof of concept is the prerequisite for the product decision to one day retire the existing AtFix IME. Until result delivery is proven across real applications, the keyboard must remain untouched and operational.

## What Changes

- **Verify end-to-end result delivery** — prove that editable host fields actually replace the selected text with the transformed result, and that read-only selections get a working clipboard fallback. Distinguish "dialog invoked / AI returned" from "text replaced".
- **Add automated coverage** — unit test the success/error result-intent construction; add Activity/UI behavior tests and an on-device instrumentation test matrix for the `ACTION_PROCESS_TEXT` flow.
- **Harden Phase 1 edge cases** — long selections, Unicode / multiline / special-character text, leading/trailing whitespace, cancellation and AI errors preserving the original text, read-only flag handling, and activity lifecycle (rotation, backgrounding, process death).
- **Document a repeatable verification matrix and app-specific limitations** — update `docs/android-process-text-poc.md` with actual results per app/device/API level, replacing claims of PASS that are not backed by observed replacement.
- **Preserve existing behavior** — the keyboard IME, the native AI transformation pipeline, the shared generated command definitions, and all other platforms are unchanged.

Out of scope for this change (deferred to a follow-up): macOS/Windows method-channel mismatches, Windows silent mock fallback, stale-response/cancellation hardening on desktop, and stale documentation outside the Android PROCESS_TEXT doc.

## Capabilities

### New Capabilities

- `android-selected-text-processing`: Invoking AtFix from Android's native text-selection menu, receiving the selected text and read-only flag, transforming it via the existing command/AI pipeline, and delivering the result to the host application — including in-place replacement for editable fields, clipboard fallback for read-only fields, and cancellation/error safety that preserves the original text.

### Modified Capabilities

- None (no capabilities are registered in `openspec/specs/` yet).

## Impact

- **Code**: `app/android/app/src/main/kotlin/com/pk/atfix/action/{ProcessTextActivity,ProcessTextController}.kt`, `app/android/app/src/main/AndroidManifest.xml`, `res/layout/activity_process_text.xml`, dialog theme/drawables.
- **Tests**: `app/android/app/src/test/java/com/pk/atfix/action/ProcessTextControllerTest.kt`; new instrumentation tests under `app/android/app/src/androidTest/` (test-only Gradle dependencies may be required — add only what the tests actually need).
- **Docs**: `docs/android-process-text-poc.md`.
- **Unchanged**: `shared/prompts/ai_prompts.json`, `tools/command_definitions_generator/`, Flutter shell, keyboard IME, macOS, Windows, iOS.
- **Build toolchain (additional, needed to run the app on a device)**: `app/android/settings.gradle.kts` and `app/android/gradle/wrapper/gradle-wrapper.properties` are bumped to AGP 9.3.1, Kotlin Gradle Plugin 2.4.20, and Gradle 9.5.0 to satisfy the installed Flutter 3.50.0 minimums. This is a pre-existing incompatibility unrelated to PROCESS_TEXT behavior.

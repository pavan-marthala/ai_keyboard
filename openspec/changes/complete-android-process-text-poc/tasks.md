# Tasks

## 1. Test infrastructure and unit coverage

- [x] 1.1 Add the minimal `androidTest` source-set configuration and test-only dependencies required by the instrumentation tests, and verify `./gradlew :app:assembleDebugAndroidTest` succeeds.
- [x] 1.2 Extend `ProcessTextControllerTest.kt` with tests for result-intent construction (success extra and value, canceled/no-result path, error mapping) and verify all local tests pass with `./gradlew :app:testDebugUnitTest`.
- [x] 1.3 Add controller unit tests for null/blank/wrong-action input, read-only flag propagation, prompt-unavailable failure, and long/Unicode/multiline text passed through the injected executor, and verify the suite passes.

## 2. Input fidelity and result-safety hardening

- [x] 2.1 Change selected-text extraction to validate emptiness with a trimmed copy while passing the original text into `@fix`, and verify a unit test asserts exact leading/trailing whitespace is preserved in the payload.
- [x] 2.2 Add single-delivery and cancellation guards so at most one result is delivered, `RESULT_CANCELED` remains the default, and no `RESULT_OK` is returned without transformed text; verify with an instrumented test that a canceled flow leaves the host field unchanged.
- [x] 2.3 Cancel any in-flight transformation when the activity is destroyed, and verify an instrumented test shows no result is delivered after destruction.

## 3. Instrumentation: end-to-end host replacement

- [x] 3.1 Add a test-only host activity that holds editable text, selects it, launches AtFix with an `ACTION_PROCESS_TEXT` intent via `startActivityForResult`, and applies the returned extra as a standard host would; it lives in the app source set and manifest (no intent filter, not exported) because `ActivityScenario` cannot monitor an activity in the test APK's package; verify it compiles in `assembleDebugAndroidTest`.
- [x] 3.2 Add a test seam that lets instrumentation supply a deterministic transformation result without a network call, and verify an instrumented test drives a successful transformation through it.
- [x] 3.3 Add the end-to-end assertion that an editable host field contains the transformed text after AtFix returns, and verify the connected instrumentation test passes on a device or emulator.

## 4. Instrumentation: dialog states, read-only, and lifecycle

- [x] 4.1 Add instrumented tests for idle/loading/result/error dialog states and the read-only badge, and verify they pass on a device or emulator.
- [x] 4.2 Add instrumented tests for the read-only clipboard fallback and for cancel/touch-outside/AI-error paths preserving the original text, and verify they pass.
- [x] 4.3 Add an instrumented test for rotation or recreation during transformation and verify no duplicate or stale result reaches the host field.

## 5. Verification matrix and documentation

- [ ] 5.1 Run the manual matrix on the available devices, API levels, and host applications covering editable and read-only fields, long/Unicode/multiline/special-character text, network failure, and a non-AtFix keyboard, and verify each row is recorded with device, API level, and app version.
- [x] 5.2 Rewrite the PASS criteria in `docs/android-process-text-poc.md` so editable success requires observed host-side replacement rather than a `setResult(RESULT_OK)` log line, and verify no remaining claim relies on logcat alone.
- [x] 5.3 Document per-app compatibility limitations and confirm the workflow works without Accessibility or overlay permissions, and verify the doc states these explicitly.

## 6. Integration verification

- [x] 6.1 Run the Android local unit suite, the connected instrumentation suite, and the Flutter regression suite, and verify all pass with no regressions.
- [x] 6.2 Confirm via `git diff` that changes are limited to the PROCESS_TEXT action code, Android tests/Gradle config, and the POC doc, and verify the keyboard IME, shared prompts, generator, and other platforms are untouched.
- [x] 6.3 Run `openspec validate complete-android-process-text-poc` (and `--strict` if available) and verify the change validates cleanly.

## 7. Build toolchain compatibility (additional)

- [x] 7.1 Upgrade Android build pins to satisfy Flutter 3.50.0 (AGP 9.3.1, Kotlin Gradle Plugin 2.4.20, Gradle wrapper 9.5.0) and verify the app builds with `./gradlew :app:testDebugUnitTest` without any dependency-validation bypass flag.

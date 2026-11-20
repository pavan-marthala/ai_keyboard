# Design: Complete Android PROCESS_TEXT Phase 1 POC

## Context

See `proposal.md` for motivation. Current state of the code:

- `ProcessTextActivity` (Kotlin `ComponentActivity`) and `ProcessTextController` (pure Kotlin) implement the `ACTION_PROCESS_TEXT` flow; registration, dialog UI, `@fix` resolution, and result intents exist (`app/android/app/src/main/kotlin/com/pk/atfix/action/`).
- The controller delegates transformation to the same `AiTextTransformer` / `PromptRepository` used by the keyboard, backed by committed generated command definitions.
- Coverage today: 12 local unit tests in `ProcessTextControllerTest.kt` covering parsing, prompt resolution, success/failure, and error mapping. `createSuccessResultIntent`, the Activity UI/lifecycle, clipboard fallback, and any on-device result delivery are untested. No `androidTest` source set exists.
- `docs/android-process-text-poc.md` records manual PASS results, but the editable-field "PASS" only evidences `setResult(RESULT_OK)` in logcat, not host-side replacement.

Constraints: do not use `AccessibilityService` or overlay permissions, do not disturb the user's keyboard, do not remove or modify the keyboard IME, reuse the existing AI pipeline and shared command definitions, and avoid unnecessary dependencies.

## Goals / Non-Goals

**Goals:**
- Make end-to-end result delivery observable and testable, especially actual in-place text replacement in an editable host.
- Close the automated-coverage gaps around result intents, dialog states, and lifecycle.
- Define and harden Phase 1 edge cases (input fidelity, read-only, cancellation/error, lifecycle).
- Produce a repeatable, evidence-backed verification matrix and update the POC doc to match reality.

**Non-Goals:**
- Adding commands beyond canonical `@fix`, changing prompt text, or regenerating artifacts.
- Modifying the keyboard IME, Flutter shell, AI provider implementations, or any other platform.
- Introducing Accessibility/overlay permissions, background services, or continuous text monitoring.
- Fixing the unrelated desktop/mobile issues listed as out of scope in the proposal.

## Decisions

### 1. Prove result delivery with an in-repo test host, not logcat
Add an instrumentation test that acts as a **host application**: a test-only activity with an editable text field that starts AtFix with an `ACTION_PROCESS_TEXT` intent via `startActivityForResult`, applies the returned `EXTRA_PROCESS_TEXT` the way a standard host would, and asserts its own field contains the transformed text. This turns "the host actually replaced the text" into an automated assertion instead of a log line.

- **Alternatives considered:** (a) Rely on manual third-party-app testing only — rejected because it is exactly the gap being closed. (b) Robolectric Activity tests — rejected for this purpose: slower to trust for platform intent semantics than a real device/emulator, and would add a dependency. Local JVM unit tests remain for pure controller logic.
- **Trade-off:** instrumentation tests need a device/emulator and are slower than unit tests; keep them focused on the single end-to-end delivery path.

### 2. Split coverage into fast unit tests and focused instrumentation tests
- Extend `ProcessTextControllerTest.kt` with result-intent construction (success extras, cancellation/no-result, error mapping) and input-validation edge cases.
- Add instrumentation tests for: dialog states (idle/loading/result/error), read-only clipboard fallback, cancel/touch-outside preserving text, and the host-replacement flow from Decision 1.
- **Rationale:** pure logic is cheap to test on the JVM; only behavior that genuinely depends on Android platform semantics goes to instrumentation.

### 3. Preserve the exact selected text for transformation
Keep the current blank-input check, but stop trimming the text payload itself: validate with a trimmed copy for emptiness while passing the original selection into `@fix`.

- **Rationale:** trimming silently drops intentional leading/trailing whitespace and is invisible to the user; a text-transformation assistant should transform exactly what was selected. This is a low-risk behavior refinement with documented semantics.
- **Alternative considered:** keep trimming and only document it — rejected because it leaves a fidelity defect in the Phase 1 contract.

### 4. Single-delivery and cancellation guards
Ensure the activity can deliver at most one result, keeps `RESULT_CANCELED` as the default, and cancels any in-flight transformation when it is destroyed (rotation, backgrounding, process death). No `RESULT_OK` without transformed text.

- **Rationale:** prevents stale or duplicate replacement when the activity is recreated, a concrete Phase 1 lifecycle requirement.

### 5. Treat the AI pipeline and generated definitions as stable dependencies
Do not edit the native transformer, provider code, `ai_prompts.json`, or generated artifacts. Tests use the existing controller seam (`TextTransformExecutor`) to inject deterministic success/failure responses.

- **Rationale:** keeps this change scoped to verification and hardening; reusing the pipeline is a product constraint.

### 6. Verification matrix lives in the existing POC document
Record app/device/API-level results, editable vs. read-only fields, text kinds (long, Unicode, multiline, special characters), network failure, and lifecycle observations in `docs/android-process-text-poc.md`, explicitly separating "observed host replacement" from "result returned".

## Risks / Trade-offs

- **Host apps differ in `PROCESS_TEXT` support** → document per-app limitations; do not claim universal replacement. Automated host test proves the contract; manual matrix proves real-world adoption.
- **Automation cannot reproduce every OEM/browser behavior** → keep the manual matrix explicit and mark each result with device/API/app version.
- **Instrumentation test flakiness (timing, focus)** → use `ActivityScenario`/`InstrumentationRegistry` idioms, avoid fixed sleeps where possible, and keep the matrix small.
- **Existing POC doc overstates verification** → rewrite PASS criteria to require observed replacement, preventing future agents from treating unverified behavior as done.
- **No prior `androidTest` source set** → adding it introduces test-only Gradle configuration; add only dependencies the tests actually need.

## Migration Plan

This is an additive, test-and-harden change with no user-data migration.

1. Land unit tests and result-intent/edge-case hardening.
2. Land instrumentation host harness and Activity/lifecycle tests.
3. Run the manual app/device matrix and update the POC doc with evidence.
4. Keep the keyboard IME unchanged and active throughout; the migration decision to retire it remains a separate, later approval.

Rollback: revert this change. Because the PROCESS_TEXT activity is additive, disabling or removing its intent filter while keeping the keyboard restores the prior state without affecting users' typing.

## Open Questions

- Which physical devices, API levels, and host applications will be available for the manual matrix? The previously documented device was a OnePlus Nord CE 3 5G on Android 16; the matrix can be written generically, but the executed rows depend on available hardware.

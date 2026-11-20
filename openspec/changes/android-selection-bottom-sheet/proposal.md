# Proposal: Android Selection Bottom Sheet + All Commands

## Why

The ACTION_PROCESS_TEXT entrypoint currently shows a small centered dialog offering only `@fix`. The supplied "Text Correction Sheet" design specifies a native bottom sheet with three parts — a full command picker, a searchable translate language picker, and a result preview with Replace / Copy / Try again — so users can choose any canonical command and review the transformation before applying it.

## What Changes

- Replace the floating dialog with a native bottom sheet following the supplied design tokens (colors, radii, spacing, typography).
- Part 1: list every canonical command from the generated definitions (`@fix`, `@rewrite`, `@professional`, `@casual`, `@short`, `@expand`, `@translate`). The design's `@pro` is shown as `@professional`, the canonical trigger.
- Part 2: searchable language picker for `@translate`, including Japanese (`@translate:ja`), with `{{language}}` interpolation from the canonical prompt.
- Part 3: ORIGINAL / CORRECTED preview with **Replace** (returns `RESULT_OK`), **Copy** (clipboard only, no replacement), **Try again**, and back navigation.
- Generalize `ProcessTextController` to run any command while preserving single-delivery and cancellation safety.
- Update instrumentation tests and `docs/android-process-text-poc.md`.

Out of scope: macOS/Windows/iOS UI, keyboard IME, generated prompts, other platform language maps.

## Capabilities

### New Capabilities

- `android-text-selection-bottom-sheet`: The bottom-sheet UI and command-selection behavior of AtFix's Android selected-text workflow, including command listing, translate language selection, result preview, and result actions.

### Modified Capabilities

- None (no capabilities are registered in `openspec/specs/` yet).

## Impact

- `app/android/app/src/main/kotlin/com/pk/atfix/action/{ProcessTextActivity,ProcessTextController}.kt`, `command/NativeCommandRegistry.kt`
- Android resources: new `sheet_*` layouts, `bg_atfix_*` / `ic_atfix_*` drawables, sheet color tokens, bottom-sheet theme/animation, manifest theme
- Android unit + instrumentation tests; `docs/android-process-text-poc.md`

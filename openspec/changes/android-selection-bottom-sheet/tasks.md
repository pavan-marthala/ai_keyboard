# Tasks

## 1. Bottom sheet shell and design tokens

- [x] 1.1 Replace the dialog theme with a translucent bottom-sheet theme, add slide animations, and verify `assembleDebug` succeeds.
- [x] 1.2 Add sheet color tokens, rounded/card/pill/chip drawables, command icons, and the three sheet content layouts plus row layouts.

## 2. Command and language behavior

- [x] 2.1 Generalize `ProcessTextController` with `executeCommand` / `resolvePrompt`, keeping `executeFix` as a wrapper, and add unit tests for `@rewrite`, `@translate`, Japanese interpolation, and unsupported languages.
- [x] 2.2 Add Japanese (`ja`) to Android's supported languages and render the full generated command list with `@professional` in place of `@pro`.
- [x] 2.3 Implement the searchable language picker and wire selection to a `@translate:<code>` request.

## 3. Result preview and safety

- [x] 3.1 Implement the ORIGINAL/CORRECTED preview with Replace, Copy, Try again, and back navigation.
- [x] 3.2 Preserve single-delivery, cancellation, and recreation safety; Copy and read-only Replace return a canceled result.

## 4. Verification and documentation

- [x] 4.1 Update instrumentation tests for the new UI, including host replacement after Replace, all-commands listing, translate language selection, read-only Copy, and cancellation paths; verify 10/10 pass on an emulator.
- [x] 4.2 Run Android unit tests and Flutter regression tests and verify all pass with no regressions.
- [x] 4.3 Update `docs/android-process-text-poc.md` for the bottom sheet and expanded commands.

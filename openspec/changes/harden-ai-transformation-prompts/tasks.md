# Tasks

## 1. Rewrite canonical prompts

- [x] 1.1 Add the explicit output-only contract to the `system` prompt of all seven commands in `shared/prompts/ai_prompts.json`, preserving each command's transformation semantics, the version 2 schema, and `{{language}}` interpolation; verify the JSON parses and the generator validator passes.
- [x] 1.2 Document the output contract in `shared/prompts/README.md` and verify it states that responses must contain only the transformed text.

## 2. Regenerate platform artifacts

- [x] 2.1 Run `dart run tools/command_definitions_generator/bin/generate.dart --input=shared/prompts/ai_prompts.json` and verify the four prompt-bearing artifacts (Dart, Kotlin, Swift, C++ source) contain the new contract in all 7 commands; the C++ header holds only a struct declaration and is unchanged by design.
- [x] 2.2 Run `dart test` in `tools/command_definitions_generator` and verify the committed-artifact consistency test passes with the regenerated files.

## 3. Verification

- [x] 3.1 Run `flutter test` from `app/` and verify all tests pass with no regressions.
- [x] 3.2 Review `git diff` and verify the JSON, README, and generated artifacts are the only files changed by this change, with no new commands or `@pro`; also verify generated prompt text is intact and Android Kotlin compiles.

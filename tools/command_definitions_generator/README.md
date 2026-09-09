# Command Definitions Generator

A standalone Dart code generator that reads the canonical command-definition JSON and compiles deterministic, strongly typed models and repositories for Flutter (Dart), Android (Kotlin), macOS (Swift), and Windows (C++).

## Core Principles

1. **Single Source of Truth**:
   - `shared/prompts/ai_prompts.json` is the sole canonical source of AI command definitions, ordering, and system prompts.
2. **Committed Generated Artifacts**:
   - Generated platform source files are checked into Git and tracked as version-controlled source files.
   - Developers do **NOT** need to run the generator for normal application builds or tests (`flutter run`, `flutter test`, `flutter build`, Android Gradle, macOS Xcode, Windows CMake).
3. **Manual Regeneration When Changing Prompts**:
   - The generator is executed manually whenever `shared/prompts/ai_prompts.json` is modified.
   - Both the canonical JSON and the updated generated platform source files must be reviewed, tested, and committed together in Git.
4. **Deterministic Output**:
   - Identical JSON input always produces byte-identical generated output across platforms.
   - A suite consistency test (`generator_test.dart`) validates that committed files exactly match `ai_prompts.json`.
5. **No Manual Editing**:
   - The generated source files must never be edited manually. Any changes must originate from `shared/prompts/ai_prompts.json`.

---

## Generated File Targets

| Platform | Language | Generated File Path |
| :--- | :--- | :--- |
| **Flutter** | Dart | `app/lib/features/commands/data/generated/generated_command_definitions.dart` |
| **Android** | Kotlin | `app/android/app/src/main/kotlin/com/pk/atfix/generated/GeneratedCommandDefinitions.kt` |
| **macOS** | Swift | `app/macos/Runner/Generated/GeneratedCommandDefinitions.swift` |
| **Windows** | C++ | `app/windows/runner/generated/generated_command_definitions.h`<br>`app/windows/runner/generated/generated_command_definitions.cpp` |

---

## How to Regenerate

From the repository root:

```bash
dart run tools/command_definitions_generator/bin/generate.dart --input=shared/prompts/ai_prompts.json
```

### CLI Options

```text
-i, --input     Path to canonical ai_prompts.json input file.
                (defaults to "<repo_root>/shared/prompts/ai_prompts.json")
-o, --output    Optional isolated output directory override (defaults to platform-local paths).
-h, --help      Display usage instructions.
```

---

## Running Tests

From the `tools/command_definitions_generator/` directory:

```bash
dart test
```

This runs:

- Schema validation tests (`validator_test.dart`).
- Platform code generator tests (`generator_test.dart`).
- The consistency check verifying that committed files match `shared/prompts/ai_prompts.json`.

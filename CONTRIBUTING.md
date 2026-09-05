# Contributing to AtFix

Thank you for your interest in contributing to AtFix. This guide explains how to set up your environment, follow project conventions, develop features, and submit pull requests.

---

## Code of Conduct

All contributors and maintainers are expected to follow our [Code of Conduct](CODE_OF_CONDUCT.md). Please report unacceptable behavior to **`mgpavank@gmail.com`**.

---

## Development Prerequisites

Before beginning development, verify that your machine has the necessary toolchains installed:

- **Flutter SDK:** Version 3.13.2+ (Dart SDK `^3.13.2`)
- **Android SDK:** `compileSdk 37`, Android NDK, and CMake `3.22.1`
- **JDK:** Java 17
- **Xcode:** 15+ (for iOS development on macOS)

---

## Local Development Workflow

Follow this step-by-step workflow when making contributions:

1. **Fork & Clone:**

   ```bash
   git clone https://github.com/<your-username>/atfix.git
   cd atfix
   ```

2. **Install Dependencies:**

   ```bash
   cd app
   flutter pub get
   ```

3. **Run Code Generation:**

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Create a Feature Branch:**
   Create a focused branch from `master` using the standard naming conventions below.
5. **Implement Changes:**
   Keep changes modular, focused, and aligned with existing architectural layers.
6. **Static Analysis & Formatting:**

   ```bash
   cd app
   flutter analyze
   dart format --set-exit-if-changed .
   ```

7. **Execute Tests:**
   Ensure all existing and newly added tests pass:

   ```bash
   # Flutter tests
   cd app && flutter test

   # Android native unit tests
   cd app/android && ./gradlew test
   ```

8. **Test on Hardware:**
   Whenever possible, test input method changes on actual Android or iOS devices to verify touch response, IME window tokens, and lifecycle transitions.
9. **Update Documentation:**
   Update relevant Markdown documents in `docs/` and `README.md` whenever adding commands, modifying APIs, or altering behavior.
10. **Submit a Pull Request:**
    Push your branch and submit a PR using the [Pull Request Template](.github/pull_request_template.md).

---

## Branch Naming Conventions

Branch names must be lowercase, concise, and structured with a category prefix:

| Prefix | Use Case | Example |
| :--- | :--- | :--- |
| `feature/<description>` | Adding new capabilities or enhancements | `feature/clipboard-search` |
| `fix/<description>` | Resolving bugs or unexpected behaviors | `fix/cursor-position-shift` |
| `docs/<description>` | Documentation additions or updates | `docs/update-ai-endpoints` |
| `refactor/<description>` | Non-functional code cleanup or restructuring | `refactor/text-editor-methods` |
| `test/<description>` | Adding or updating unit/widget/native tests | `test/add-command-parser-cases` |
| `chore/<description>` | Tooling, metadata, or dependency adjustments | `chore/update-gitignore` |

---

## Commit Message Guidelines

We enforce the [Conventional Commits](https://www.conventionalcommits.org/) specification. Messages must be concise, written in the imperative mood, and lowercase after the type:

- `feat:` Adds a new user-facing feature or capability.
- `fix:` Patches a bug or defect.
- `docs:` Documentation-only changes.
- `refactor:` Code refactoring that neither fixes a bug nor adds a feature.
- `test:` Adding missing tests or correcting existing tests.
- `chore:` Routine repository maintenance, gitignore, or metadata changes.
- `build:` Build system changes (Gradle, CMake, CocoaPods).
- `ci:` Continuous integration configuration.
- `perf:` Performance improvements.

**Example Commit Messages:**

```text
feat: Add Kannada language support to @translate command
fix: Handle null textDocumentProxy gracefully on iOS extension launch
docs: Document Giphy analytics pingback requirements in security.md
test: Add unit tests for AospSuggestionAdapter geometry bounds
```

---

## Guidelines for Native AOSP Components

Portions of the suggestion infrastructure in `app/android/app/src/main/kotlin/com/pk/atfix/suggestion/aosp/` and `app/android/app/src/main/cpp/aosp_latinime/` are derived from the Android Open Source Project (AOSP) LatinIME implementation (Copyright (C) 2010–2014 The Android Open Source Project, Apache 2.0).

When modifying or adding to these components, contributors must strictly adhere to the following rules:

1. **Retain Copyright Headers:** Existing AOSP Apache 2.0 copyright and license headers in source files must remain intact. Never delete or alter upstream copyright statements.
2. **Document Modifications:** If you modify an AOSP-derived file, add a prominent comment indicating that changes have been made to the original AOSP source code.
3. **Preserve Attribution:** Verify that any structural or algorithmic additions comply with the terms of the Apache 2.0 license and are noted in the repository [NOTICE](NOTICE) file.
4. **No Incompatible Source Merges:** Do not copy code from third-party repositories with restrictive or incompatible licenses (e.g. GPL-licensed keyboards) into the AOSP suggestion engine.

---

## Security & Secrets Policy

> [!CAUTION]
> **Zero Secrets Policy:** Never commit API keys, personal access tokens, passwords, keystore binaries (`*.jks`, `*.keystore`), signing property files, private keys (`*.pem`, `*.key`), or local environment variables (`.env`) to the repository.

- Always verify `git status` and `git diff` before committing to ensure no credentials or local configuration files are tracked.
- If you discover that a sensitive key has been committed, notify the project maintainers immediately at **`mgpavank@gmail.com`**.

---

## Contact & Questions

If you have questions regarding architecture or contributions, open an issue using the relevant issue template or reach out to **`mgpavank@gmail.com`**.

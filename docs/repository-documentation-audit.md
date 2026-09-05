# Repository Documentation Audit

## Audit Date

2026-09-03

## Repository Commit

`0412672e7dc839345f7dc8ce6d4cdb52d3f0471d`

## Scope

Comprehensive repository audit, documentation hardening, and governance alignment for the `atfix` repository (`https://github.com/pavan-marthala/atfix`). The audit covered root governance files, in-depth architectural guides, issue and pull request templates, and technical specifications, comparing every statement against the authoritative source code across Flutter (`app/lib/`), native Android (`app/android/`), native iOS (`app/ios/`), and native C++ AOSP (`app/android/app/src/main/cpp/`).

---

## Files Reviewed

The following Markdown, template, and configuration files were reviewed during the audit:

- `README.md`
- `app/README.md`
- `docs/architecture.md`
- `docs/android-keyboard.md`
- `docs/ai-providers.md`
- `docs/development.md`
- `docs/security.md`
- `SECURITY.md`
- `CONTRIBUTING.md`
- `CODE_OF_CONDUCT.md`
- `LICENSE`
- `NOTICE`
- `.github/pull_request_template.md`
- `.github/ISSUE_TEMPLATE/bug_report.md`
- `.github/ISSUE_TEMPLATE/feature_request.md`
- `.github/ISSUE_TEMPLATE/improvement.md`
- `.gitignore`
- `app/.gitignore`
- `app/pubspec.yaml`
- `app/android/app/build.gradle.kts`
- `app/android/app/src/main/cpp/CMakeLists.txt`

---

## Changes Made

| File | Nature of Changes | Rationale |
| :--- | :--- | :--- |
| `README.md` | Complete overhaul | Corrected command syntax from slash commands (`/fix`) to inline `@` commands (`@fix`). Replaced erroneous Jetpack Compose claims with accurate Android View hierarchy documentation. Added explicit `## Project Status` section with granular component maturity breakdown. Updated setup, testing, and prerequisite instructions. |
| `app/README.md` | Architecture rewrite | Updated Mermaid system architecture diagram to eliminate Compose and slash commands. Detailed actual component interactions (`KeyboardService`, `KeyboardController`, `KeyboardView`, `TextEditor`, `AospSuggestionAdapter`). Clarified direct native HTTP calls from keyboards to AI providers. Added accurate build runner code generation commands. |
| `docs/architecture.md` | In-depth technical specification | Documented concrete architectural boundaries between Flutter host shell, native Android IME, native iOS extension, and AOSP C++ engine. Documented exact MethodChannel signatures (`com.pk.atfix/credentials` and `com.pk.atfix/keyboard`). Detailed JNI bridge execution path and dictionary cache extraction. |
| `docs/android-keyboard.md` | Android subsystem specification | Removed all references to Jetpack Compose. Documented `KeyboardView` as an Android `LinearLayout` with custom Views, AndroidX `EmojiPickerView`, and `RecyclerView`. Detailed the 7 keyboard modes (`MAIN`, `MORE`, `EMOJI`, `CLIPBOARD`, `GIF`, `STICKERS`, `RESIZE`), double-tap shift behavior, `TextEditor` `InputConnection` lifecycle, Giphy API search and onsend pingbacks, transparent voice permission activity, and KeyStore AES-256-GCM. |
| `docs/ai-providers.md` | AI integration reference | Verified and documented exact REST endpoints, headers, default models (`gemini-1.5-flash`, `gpt-4o-mini`, `llama-3.3-70b-versatile`, `openai/gpt-4o-mini`), parameter values (`temperature: 0.0`, `max_tokens: 1024`), custom base URL overrides, and credential storage partitioning across all 4 providers. |
| `docs/development.md` | Setup & workflow guide | Standardized command execution contexts (`cd app`), documented prerequisites (Flutter, Android SDK, NDK, CMake 3.22.1, Xcode), explained code generation, testing, building debug/release APKs, and troubleshooting common issues. |
| `docs/security.md` | Cryptography & privacy specification | Documented cryptographic implementations (Android KeyStore AES-256-GCM with 128-bit tag, iOS Keychain `kSecClassGenericPassword`), network transport security (strict HTTPS), transparent data transmission disclosure (including Giphy onsend analytics pingback), and verified the absence of app telemetry/crash analytics. |
| `SECURITY.md` | Vulnerability disclosure policy | Aligned version support with active pre-release development status on `master`. Documented private disclosure email (`mgpavank@gmail.com`), required report details, response expectations, and responsible disclosure guidelines. |
| `CONTRIBUTING.md` | Developer guide alignment | Specified branch naming conventions (`feature/`, `fix/`, `docs/`, `refactor/`, `test/`, `chore/`), Conventional Commits specification, development workflow steps, strict AOSP attribution and license retention requirements, and zero-secrets commitment rules. |
| `NOTICE` | Third-party attribution compliance | Refined Apache 2.0 Section 4(d) attribution for AOSP LatinIME native C++ and Kotlin source code (Copyright 2010–2014 The Android Open Source Project) and Contributor Covenant Code of Conduct v2.0. |
| `.github/pull_request_template.md` | PR checklist expansion | Added structured sections for summary, motivation, changes, type, testing, platforms, screenshots, documentation, security, AOSP licensing, and breaking change disclosure. |
| `.github/ISSUE_TEMPLATE/bug_report.md` | Keyboard-tailored bug reporting | Replaced generic web templates with mobile/keyboard-specific fields (device model, Android/iOS version, IME context, AI provider, model, `@` command used, and log redaction warnings). |
| `.github/ISSUE_TEMPLATE/feature_request.md` | Enhancement template update | Added sections for target platform, AI provider relevance, and `@` command syntax proposals. |
| `.github/ISSUE_TEMPLATE/improvement.md` | Optimization template | Created focused template for component-level refinements across keyboard UI, AOSP suggestions, AI transformations, and tooling. |

---

## Source-of-Truth Verification

Every technical claim made in the revised documentation was verified directly against the codebase:

1. **Command Syntax:**
   - Flutter: `app/lib/features/commands/domain/parser/command_parser.dart` and `command_registry.dart`.
   - Android: `app/android/app/src/main/kotlin/com/pk/atfix/command/CommandParser.kt` and `NativeCommandRegistry.kt`.
   - iOS: `app/ios/KeyboardExtension/CommandParser.swift`.
   - *Verification Result:* Commands are strictly trailing tokens starting with `@` (`@fix`, `@rewrite`, `@pro`, `@casual`, `@short`, `@expand`, `@translate:<lang>`). Not slash commands.
2. **Android UI Implementation:**
   - Source: `app/android/app/src/main/kotlin/com/pk/atfix/ui/KeyboardView.kt` and `app/android/app/build.gradle.kts`.
   - *Verification Result:* `KeyboardView` extends `android.widget.LinearLayout`. Uses custom Views, `androidx.emoji2.emojipicker.EmojiPickerView`, and `RecyclerView`. Jetpack Compose is not imported or used.
3. **AOSP Suggestion Engine & Dictionary:**
   - Source: `app/android/app/src/main/cpp/CMakeLists.txt`, `format_utils.cpp`, `v4_dict_buffers.cpp`, `NativeBinaryDictionary.kt`, `BinaryDictionary.kt`, and `main_en.dict`.
   - *Verification Result:* Compiles `liblatinime.so` via CMake from AOSP LatinIME C++ source (Copyright 2010–2014 AOSP, Apache 2.0). Bundled asset `main_en.dict` has magic header `0x9BC13AFE` (~1.07MB).
4. **AI Providers & Parameters:**
   - Source: Native and Flutter provider classes across `app/lib/`, `app/android/`, and `app/ios/`.
   - *Verification Result:* All 4 providers use `temperature: 0.0` and `max_tokens: 1024`. KeyStore AES-256-GCM is used on Android; Keychain on iOS.
5. **Telemetry & Network Calls:**
   - Source: Grep across repository for analytics, crashlytics, telemetry, and tracking SDKs.
   - *Verification Result:* No application telemetry or tracking libraries exist. Giphy API queries trigger silent onsend pingbacks (`GifInserter.kt`) per Giphy API terms.

---

## Architecture Documentation

The system architecture is structured as follows:

- **Layer 1 (Flutter Host):** Settings, provider management, and testing playground utilizing BLoC, Freezed, and Injectable. Communicates with native platforms via MethodChannels `com.pk.atfix/credentials` and `com.pk.atfix/keyboard`.
- **Layer 2 (Android Native Keyboard):** Kotlin `InputMethodService` (`KeyboardService`), `KeyboardController`, `KeyboardView` (Android Views), and direct HTTPS calls (`HttpURLConnection`) to AI providers.
- **Layer 3 (iOS Native Keyboard):** Swift `UIInputViewController` (`KeyboardViewController`), UIKit `KeyboardView`, and direct HTTPS calls (`URLSession`) to AI providers.
- **Layer 4 (AOSP C++ Engine):** Native C++ LatinIME library compiled via CMake and bound via JNI (`latinime_jni.cpp`) for Patricia trie word suggestions against `main_en.dict`.

---

## Command Documentation

The verified command syntax consists of 7 trailing commands:

- `@fix`: Corrects grammar, spelling, punctuation, and capitalization.
- `@rewrite`: Rewrites text while preserving meaning.
- `@pro`: Adjusts tone to professional and formal.
- `@casual`: Adjusts tone to friendly and conversational.
- `@short`: Condenses text into concise wording.
- `@expand`: Expands text for clarity and completeness.
- `@translate:<lang>`: Translates text into target language code (`en`, `es`, `fr`, `de`, `it`, `pt`, `hi`, `te`, `kn`, `ta`).

Rules: Commands must appear at the end of input text separated by whitespace, with non-empty preceding text.

---

## AOSP Documentation

- **Source:** Android Open Source Project (AOSP) LatinIME (`packages/inputmethods/LatinIME`).
- **Copyright:** Copyright (C) 2010–2014 The Android Open Source Project.
- **License:** Apache License, Version 2.0.
- **Components Derived from AOSP:**
  - C++ source files in `app/android/app/src/main/cpp/aosp_latinime/`.
  - C++ JNI bridge files in `app/android/app/src/main/cpp/latinime/`.
  - Kotlin adapter classes in `app/android/app/src/main/kotlin/com/pk/atfix/suggestion/aosp/` (19 files).
  - Bundled binary dictionary `app/android/app/src/main/assets/dictionaries/main_en.dict`.
- **Attribution Status:** Fully documented in `NOTICE`, `README.md`, `app/README.md`, `docs/architecture.md`, `docs/android-keyboard.md`, and `CONTRIBUTING.md`.

---

## Security Documentation

- **API Keys:** Never committed to source control. Stored in hardware-backed Android KeyStore (AES-256-GCM, alias `AtFIxKeyStoreKey`) and iOS Keychain (`com.pk.atfix.apiKey`).
- **Data Transmission:** Only text preceded by an `@` command is transmitted over HTTPS to user-configured AI providers. Standard keystrokes are processed locally.
- **Third-Party Requests:** Giphy API queries for GIF search; silent onsend pingbacks upon GIF insertion.
- **Telemetry:** Zero application telemetry, analytics, keystroke recording, or crash reporting.

---

## GitHub Repository Setup

### Suggested Repository Description
>
> "AI-powered keyboard for Android and iOS with native keyboard features, AI text transformation, and Android AOSP-based suggestions."

### Recommended Repository Topics

`ai`, `keyboard`, `flutter`, `android`, `ios`, `aosp`, `latinime`, `kotlin`, `swift`, `dart`, `ai-keyboard`, `ime`

### Templates & Workflows

- Issue Templates: `bug_report.md`, `feature_request.md`, `improvement.md` in `.github/ISSUE_TEMPLATE/`.
- Pull Request Template: `pull_request_template.md` in `.github/`.
- Contact Information: `mgpavank@gmail.com` consistently used across `SECURITY.md`, `CODE_OF_CONDUCT.md`, and `CONTRIBUTING.md`.

---

## Inconsistencies Corrected

1. **Slash Commands vs. `@` Commands:** Removed all references to slash commands (`/fix`, `/translate`, `/rewrite`, `/summarize`) across all documentation; replaced with verified `@` command syntax.
2. **Jetpack Compose vs. Android Views:** Removed all claims that the Android keyboard uses Jetpack Compose; accurately documented the native `LinearLayout` View hierarchy.
3. **Experimental Claims vs. Reality:** Clarified that the Android keyboard and AOSP suggestion integration are functional implementations with specific bounds (English only, bundled dictionary, session learning), while the iOS keyboard extension is experimental (no word suggestions).
4. **Command List Inaccuracies:** Removed non-existent commands like `/summarize` and added missing commands (`@casual`, `@short`, `@expand`).
5. **AI Defaults:** Documented exact verified parameters (`temperature: 0.0`, `max_tokens: 1024`, default models per provider).
6. **Fake Versioning in Security Policy:** Replaced boilerplate version matrices with accurate pre-release status documentation.
7. **Directory Inconsistencies in Commands:** Standardized all setup, build, and test command examples to explicitly state whether they run from repository root or the `app/` directory.

---

## Remaining Limitations

The following limitations exist in the application implementation and are transparently documented:

1. **Suggestion Engine Language Support:** The suggestion engine currently bundles and loads a single English dictionary (`main_en.dict`). Multi-language suggestions are not supported.
2. **User Dictionary Persistence:** Custom learned words in the AOSP engine are currently held in memory during the active session and do not persist across device restarts.
3. **iOS Keyboard Extension:** Lacks predictive word suggestions; provides basic typing and AI text transformations only.
4. **Release Signing:** Build scripts currently use debug signing for development; production signing must be configured before store distribution.

---

## Validation Results

- **Markdown Lint & Link Integrity:** All relative Markdown links (`docs/*.md`, `README.md`, `app/README.md`, `NOTICE`, `SECURITY.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`) were validated and verified to resolve to existing files.
- **Git Diff Review:** Verified that modifications are strictly limited to documentation (`.md`), repository governance, and `.github/` templates.
- **Consistency Verification:** Performed repository-wide grep checks confirming zero occurrences of erroneous terms ("slash command", "Jetpack Compose", "/fix", "/summarize") in active documentation.

---

## Application Code Changes

**No application source code was modified during this documentation phase.**

All `.dart`, `.kt`, `.java`, `.swift`, `.cpp`, `.h`, `.xml`, `.gradle`, `.kts`, and dictionary files remain completely untouched.

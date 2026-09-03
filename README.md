# AI Keyboard

![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)

An AI-powered keyboard application for Android and iOS. It combines a Flutter application shell for configuration and settings with native on-device keyboard implementations. The keyboard integrates multiple AI providers to offer on-the-fly text transformations—such as grammar correction, rewriting, tone adjustments, conciseness, expansion, and translation—directly from your keyboard using inline `@` commands.

> [!NOTE]
> This project is under active development as an open-source milestone and is not yet packaged or signed for production release.

---

## Table of Contents

- [Features](#features)
- [Command System](#command-system)
- [Supported AI Providers](#supported-ai-providers)
- [Project Status](#project-status)
- [Architecture Overview](#architecture-overview)
- [Repository Structure](#repository-structure)
- [Development Prerequisites](#development-prerequisites)
- [Setup & Installation](#setup--installation)
- [Running the App](#running-the-app)
- [Testing](#testing)
- [Security & Privacy](#security--privacy)
- [Contributing](#contributing)
- [License & Third-Party Attribution](#license--third-party-attribution)

---

## Features

- **Native Android Keyboard (`InputMethodService`):**
  - Custom Android View hierarchy (`LinearLayout`, custom key views, `keyboard_view.xml`).
  - Text input with QWERTY and symbol layouts.
  - Optional customizable number row toggle (`NumberRowRepository`).
  - Adjustable keyboard height (`KeyboardHeightRepository`).
  - Full Emoji picker via AndroidX Emoji2 (`EmojiPickerView`).
  - Clipboard history manager with persistent recents (`ClipboardHistoryManager`).
  - Animated GIF search and insertion via Giphy API (`GifInserter` using `InputConnection.commitContent()`).
  - Voice dictation via Android `SpeechRecognizer` (`VoiceInputController`).
  - AOSP-derived word suggestion engine using native C++ LatinIME.
- **Native iOS Keyboard (`UIInputViewController`):**
  - Custom Swift keyboard extension built with UIKit (`KeyboardView`, `KeyboardKeyButton`).
  - Standard QWERTY layout with shift and caps lock state management.
  - Native AI text transformation using iOS `URLSession`.
  - Shared credentials and configuration with Flutter host via iOS Keychain and App Group.
- **On-Device AI Text Transformation:**
  - Fast, context-aware text transformations triggered by typing trailing `@` commands.
  - Direct HTTP communication from native keyboards to AI providers with zero Flutter overhead during typing.
- **Multi-Provider AI Architecture:**
  - Switch between Google Gemini, OpenAI, Groq, and OpenRouter at runtime.
  - Configurable custom base URLs for enterprise or reverse-proxy setups.
  - Deterministic generation settings (`temperature: 0.0`, `max_tokens: 1024`).
- **Hardware-Backed Credential Security:**
  - API keys stored in Android KeyStore (AES-256-GCM) and iOS Keychain (`kSecClassGenericPassword`).
  - Users supply their own API keys; keys are never hardcoded or tracked in version control.

---

## Command System

AI Keyboard uses an inline, trailing command syntax prefixed with `@`. Commands are recognized when entered at the **end** of input text, preceded by whitespace:

| Command | Action | Description |
| :--- | :--- | :--- |
| `@fix` | Fix Grammar | Corrects grammar, spelling, punctuation, and capitalization while preserving original meaning. |
| `@rewrite` | Rewrite | Paraphrases and rewrites input text cleanly without altering facts. |
| `@pro` | Professional Tone | Adapts text into a formal, clear, and professional tone suitable for workplace communication. |
| `@casual` | Casual Tone | Rewrites text in a friendly, conversational, and natural tone. |
| `@short` | Shorten | Condenses text into a concise format while retaining key information. |
| `@expand` | Expand | Elaborates and adds clarity to the input text without inventing unsupported facts. |
| `@translate:<lang>` | Translate | Translates preceding text into the specified language code (e.g. `@translate:es`). |

### Supported Language Codes for `@translate`

`en` (English), `es` (Spanish), `fr` (French), `de` (German), `it` (Italian), `pt` (Portuguese), `hi` (Hindi), `te` (Telugu), `kn` (Kannada), `ta` (Tamil).

### Command Recognition Rules

- Commands must appear at the end of the text string before the cursor.
- Non-empty text must precede the command (e.g. `"Can we meet tomorrow @pro"`).
- Trailing sentence punctuation (`.`, `,`, `!`, `?`) is automatically stripped from the command token.
- Tokens containing URL schemes (`://`) are ignored to avoid false positives.

---

## Supported AI Providers

Users bring their own API keys for the providers they wish to use. Keys are entered once in the Settings page and stored securely in on-device hardware keystores:

| Provider | Supported Platforms | API Protocol | Default Model | Key Acquisition |
| :--- | :--- | :--- | :--- | :--- |
| **Google Gemini** | Android, iOS, Flutter | REST (`generateContent`) | `gemini-1.5-flash` | [Google AI Studio](https://aistudio.google.com/app/apikey) |
| **OpenAI** | Android, iOS, Flutter | REST (`chat/completions`) | `gpt-4o-mini` | [OpenAI Platform](https://platform.openai.com/api-keys) |
| **Groq** | Android, iOS, Flutter | REST (`chat/completions`) | `llama-3.3-70b-versatile` | [Groq Console](https://console.groq.com/keys) |
| **OpenRouter** | Android, iOS, Flutter | REST (`chat/completions`) | `openai/gpt-4o-mini` | [OpenRouter](https://openrouter.ai/keys) |

For detailed information on authentication headers, endpoints, and custom base URL overrides, see [docs/ai-providers.md](docs/ai-providers.md).

---

## Project Status

The project is currently at a functional development milestone:

- **Android Keyboard:** Functional. Implements full keyboard layout, text manipulation, `@` command transformations, AOSP word suggestions, GIF search, voice dictation, and clipboard history. Uses debug signing during development.
- **iOS Keyboard Extension:** Experimental. Basic keyboard layout, shift states, and native AI text transformations via `@` commands are functional. Word suggestions are not implemented on iOS.
- **AOSP Suggestion Engine:** Functional on Android. Integrates native AOSP LatinIME C++ source compiled via CMake and JNI with a bundled English dictionary (`main_en.dict`). Dynamic user vocabulary learning is limited to the active session.
- **AI Providers:** All 4 providers (Gemini, OpenAI, Groq, OpenRouter) are implemented across Android, iOS, and the Flutter app shell.
- **Production Readiness:** Pre-release. The repository does not currently include release signing configurations, automated CI pipelines, or distribution store metadata.

---

## Architecture Overview

The system is organized into three distinct layers:

1. **Flutter App Shell (`app/lib/`):** Clean architecture with BLoC state management (`flutter_bloc`), dependency injection (`get_it`, `injectable`), routing (`go_router`), and secure settings management (`flutter_secure_storage`).
2. **Android Native Keyboard (`app/android/`):** Kotlin `InputMethodService` (`KeyboardService`) driving `KeyboardController`, `KeyboardView` (Android Views), `TextEditor`, native AI clients (`HttpURLConnection`), and the AOSP suggestion engine via JNI.
3. **iOS Keyboard Extension (`app/ios/`):** Swift `UIInputViewController` (`KeyboardViewController`), UIKit-based `KeyboardView`, `KeyboardController`, and native AI clients (`URLSession`), sharing configuration via App Group and credentials via Keychain.

For deep architectural diagrams and data-flow specifications, see [app/README.md](app/README.md) and [docs/architecture.md](docs/architecture.md).

---

## Repository Structure

```text
/
├── README.md                           # Main repository documentation
├── CONTRIBUTING.md                     # Contribution guidelines and coding conventions
├── SECURITY.md                         # Security policy and vulnerability disclosure
├── CODE_OF_CONDUCT.md                  # Contributor Covenant Code of Conduct
├── LICENSE                             # Apache License 2.0
├── NOTICE                              # Third-party attribution notices (AOSP LatinIME)
├── docs/                               # In-depth architectural and technical guides
│   ├── ai-providers.md                 # AI provider setup, endpoints, and authentication
│   ├── android-keyboard.md             # Android InputMethodService & view architecture
│   ├── architecture.md                 # Cross-platform system architecture & data flows
│   ├── development.md                  # Development setup, building, and troubleshooting
│   ├── repository-documentation-audit.md # Complete documentation audit and verification report
│   └── security.md                     # Cryptographic storage, data transmission, and privacy
├── .github/                            # GitHub templates and workflows
│   ├── ISSUE_TEMPLATE/                 # Bug report, feature request, improvement templates
│   └── pull_request_template.md        # Pull request template
└── app/                                # Application codebase
    ├── lib/                            # Flutter app shell (Dart, BLoC, Freezed)
    ├── android/                        # Android native project (Kotlin, C++ AOSP, CMake)
    ├── ios/                            # iOS native project (Swift, UIKit, App Group)
    ├── test/                           # Flutter unit and contract tests
    └── pubspec.yaml                    # Flutter dependencies and configuration
```

---

## Development Prerequisites

- **Flutter SDK:** Version 3.13.2+ (Dart SDK `^3.13.2`)
- **Android SDK:** `compileSdk 37`, Android NDK, CMake `3.22.1`
- **Xcode:** 15+ (for iOS builds and macOS development)
- **API Key:** An API key from at least one supported AI provider (Gemini, OpenAI, Groq, or OpenRouter)
- **Giphy API Key (Optional):** Required for GIF search functionality (configured via `GIPHY_API_KEY` or `local.properties`)

---

## Setup & Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/pavan-marthala/ai_keyboard.git
   cd ai_keyboard/app
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run code generation (Freezed & Injectable):**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

---

## Running the App

### Running the Flutter App Shell

From the `app/` directory:

```bash
flutter run
```

### Enabling the Keyboard on Device

After installing the application, enable the keyboard through system settings:

- **Android:** *Settings > System > Languages & Input > On-screen keyboard > Manage on-screen keyboards > Toggle AI Keyboard on.*
- **iOS:** *Settings > General > Keyboard > Keyboards > Add New Keyboard... > Select AI Keyboard.*

---

## Testing

Run tests from the repository root:

```bash
# Run Flutter unit and contract tests
cd app && flutter test

# Run Android native unit tests
cd app/android && ./gradlew test
```

For complete development, building, and debugging workflows, refer to [docs/development.md](docs/development.md).

---

## Security & Privacy

- **On-Device Storage:** Sensitive credentials (API keys) are stored in hardware-backed storage (Android KeyStore with AES-256-GCM; iOS Keychain with `kSecClassGenericPassword`).
- **Data Transmission:** Only text explicitly targeted by an `@` command is sent over HTTPS to the user's chosen AI provider. No text is transmitted during ordinary typing.
- **Zero App Telemetry:** The AI Keyboard does not collect, record, or transmit keystrokes, personal information, analytics, or crash reports.
- **External Pings:** When a GIF is inserted, Giphy's API requires an HTTP ping to an `onsend` analytics URL to comply with Giphy's API terms.

For full cryptographic and privacy details, see [docs/security.md](docs/security.md). To report vulnerabilities, review [SECURITY.md](SECURITY.md).

---

## Contributing

Contributions are welcome! Please review [CONTRIBUTING.md](CONTRIBUTING.md) for branch naming conventions, Conventional Commit standards, and guidelines on preserving AOSP licensing when touching native code.

All participants are expected to adhere to our [Code of Conduct](CODE_OF_CONDUCT.md).

---

## License & Third-Party Attribution

This project is licensed under the [Apache License, Version 2.0](LICENSE).

- **Android Open Source Project (AOSP) LatinIME:** Portions of the Android suggestion engine and native C++ code are derived from AOSP LatinIME under the Apache License 2.0 (Copyright (C) 2010–2014 The Android Open Source Project).
- See the [NOTICE](NOTICE) file for complete third-party attribution notices.

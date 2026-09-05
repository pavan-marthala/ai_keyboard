# AtFix

![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)

AtFix is an open-source, multi-platform AI writing assistant and keyboard available on macOS, Android, and iOS. It combines a Flutter application shell for configuration, credential management, and testing with high-performance native implementations tailored for each operating system:

- **macOS Desktop Assistant:** A system-wide shortcut assistant. Select text in any desktop application, press <kbd>Control</kbd> + <kbd>Option</kbd> + <kbd>Space</kbd>, choose an AI command (`@fix`, `@rewrite`, `@short`, `@expand`), and AtFix transforms and inserts the replacement text directly in place.
- **Android Native Keyboard:** An `InputMethodService` implementation providing a full QWERTY keyboard, trailing `@` command transformations, AOSP-derived word suggestions, clipboard history, voice dictation, and GIF insertion.
- **iOS Native Keyboard:** A `UIInputViewController` extension providing a native UIKit QWERTY keyboard with on-device AI text transformations via trailing `@` commands.

> [!NOTE]
> This project is under active development as an open-source milestone and is distributed as an unnotarized application without an Apple Developer subscription. See [docs/macos-installation.md](docs/macos-installation.md) for first-launch instructions.

---

## Table of Contents

- [Workflows & Capabilities](#workflows--capabilities)
- [macOS Desktop Workflow](#macos-desktop-workflow)
- [Mobile Keyboard Workflow](#mobile-keyboard-workflow)
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

## Workflows & Capabilities

### macOS Desktop Assistant
- **Global Hotkey:** Triggered from any macOS application via <kbd>Control</kbd> + <kbd>Option</kbd> + <kbd>Space</kbd>.
- **Active Context Acquisition:** Utilizes macOS Accessibility APIs (`AXUIElement`) to detect the active window, focused UI element, and selected text across native applications (TextEdit, Mail, Safari, Slack, Notes, Chrome).
- **Floating Command Panel:** Displays a cursor-anchored native panel presenting quick-action command chips (`@fix`, `@rewrite`, `@short`, `@expand`), active selection preview, and live progress indicators.
- **In-Place Replacement:** Reactivates the originating application and executes synthetic text replacement directly into the active field.

### Android Native Keyboard (`InputMethodService`)
- Custom Android View hierarchy (`LinearLayout`, custom key views, `keyboard_view.xml`).
- Standard QWERTY layout with symbol layers, adjustable height, and optional number row.
- Word suggestions powered by native C++ LatinIME engine compiled via CMake and JNI.
- Full Emoji picker via AndroidX Emoji2 (`EmojiPickerView`).
- Persistent clipboard history manager (`ClipboardHistoryManager`).
- Animated GIF search and insertion via Giphy API (`GifInserter`).
- Voice dictation via Android `SpeechRecognizer` (`VoiceInputController`).

### iOS Native Keyboard (`UIInputViewController`)
- Native UIKit keyboard extension (`KeyboardView`, `KeyboardKeyButton`).
- Standard layout with shift and caps lock state management.
- Native AI text transformations using iOS `URLSession`.
- Shared configuration and credentials with Flutter host via iOS Keychain and App Group.

---

## macOS Desktop Workflow

The macOS shortcut assistant workflow follows this sequence:

```text
Select text in any app
→ Press Control + Option + Space
→ Choose an @command (@fix, @rewrite, @short, @expand)
→ AtFix transforms the text via your configured AI provider
→ Transformed text is inserted directly into the original application
```

### Verified macOS Desktop Commands

| Command | Action | Description |
| :--- | :--- | :--- |
| `@fix` | Fix Grammar | Corrects grammar, spelling, punctuation, and capitalization while preserving original meaning. |
| `@rewrite` | Rewrite | Paraphrases and polishes input text cleanly without altering facts. |
| `@short` | Shorten | Condenses text into concise phrasing while retaining essential information. |
| `@expand` | Expand | Elaborates and adds clarity to the input text with helpful detail. |

---

## Mobile Keyboard Workflow

On Android and iOS, AtFix operates as a system keyboard. Commands are typed directly at the end of input text, prefixed with `@`:

```text
Type text followed by @command (e.g. "Drafting the proposal @fix")
→ Press space or trigger key
→ Native keyboard sends text to the active AI provider
→ Transformed text replaces the prompt and preceding text in the input field
```

### Mobile Inline Commands

| Command | Action | Description |
| :--- | :--- | :--- |
| `@fix` | Fix Grammar | Corrects grammar, spelling, punctuation, and capitalization. |
| `@rewrite` | Rewrite | Paraphrases input text while maintaining meaning. |
| `@pro` | Professional Tone | Adapts text into a formal, clear workplace tone. |
| `@casual` | Casual Tone | Rewrites text into friendly, conversational phrasing. |
| `@short` | Shorten | Condenses text into concise format. |
| `@expand` | Expand | Elaborates and adds clarity without unsupported claims. |
| `@translate:<lang>` | Translate | Translates text into the specified language code (e.g. `@translate:es`). |

Supported translation languages: `en` (English), `es` (Spanish), `fr` (French), `de` (German), `it` (Italian), `pt` (Portuguese), `hi` (Hindi), `te` (Telugu), `kn` (Kannada), `ta` (Tamil).

---

## Supported AI Providers

AtFix operates on a Bring Your Own Key (BYOK) model. Users supply their own API keys in Settings. Keys are encrypted in platform hardware keystores (Android KeyStore, iOS Keychain, macOS Keychain):

| Provider | Supported Platforms | API Protocol | Default Model | Key Acquisition |
| :--- | :--- | :--- | :--- | :--- |
| **Google Gemini** | Android, iOS, Flutter | REST (`generateContent`) | `gemini-1.5-flash` | [Google AI Studio](https://aistudio.google.com/app/apikey) |
| **OpenAI** | macOS, Android, iOS, Flutter | REST (`chat/completions`) | `gpt-4o-mini` | [OpenAI Platform](https://platform.openai.com/api-keys) |
| **Groq** | macOS, Android, iOS, Flutter | REST (`chat/completions`) | `llama-3.3-70b-versatile` | [Groq Console](https://console.groq.com/keys) |
| **OpenRouter** | macOS, Android, iOS, Flutter | REST (`chat/completions`) | `openai/gpt-4o-mini` | [OpenRouter](https://openrouter.ai/keys) |

For authentication headers, endpoints, and custom reverse-proxy URLs, see [docs/ai-providers.md](docs/ai-providers.md).

---

## Project Status

- **macOS Desktop Assistant:** Functional. Implements global shortcut, Accessibility selection reading, native floating prompt, and text replacement. Open-source distribution without Developer ID.
- **Android Keyboard:** Functional. Full keyboard layout, trailing `@` transformations, AOSP word suggestions, GIF search, voice dictation, and clipboard history.
- **iOS Keyboard Extension:** Experimental. Basic keyboard layout, shift states, and native AI text transformations via `@` commands. Word suggestions are not implemented on iOS.
- **AOSP Suggestion Engine:** Functional on Android. Integrates native AOSP LatinIME C++ compiled via CMake with bundled English dictionary (`main_en.dict`).
- **AI Providers:** OpenAI, Groq, OpenRouter supported across desktop and mobile; Gemini supported on mobile and Flutter shell.

---

## Architecture Overview

1. **Flutter App Shell (`app/lib/`):** Clean architecture with BLoC state management (`flutter_bloc`), dependency injection (`get_it`, `injectable`), declarative routing (`go_router`), and secure settings management.
2. **macOS Native Layer (`app/macos/Runner/`):** Native Swift subsystem encompassing `Command/` (shortcut manager, Accessibility reader, floating prompt, text replacement), `AI/` (direct REST transformer), and `Security/` (Keychain credential store).
3. **Android Native Layer (`app/android/`):** Kotlin `InputMethodService` (`KeyboardService`) driving `KeyboardController`, `KeyboardView` (Android Views), `TextEditor`, native AI clients (`HttpURLConnection`), and AOSP LatinIME via JNI.
4. **iOS Native Layer (`app/ios/`):** Swift `UIInputViewController` (`KeyboardViewController`), UIKit-based `KeyboardView`, `KeyboardController`, and native AI clients (`URLSession`), sharing configuration via App Group and credentials via Keychain.

For architectural diagrams and data flows, see [app/README.md](app/README.md) and [docs/architecture.md](docs/architecture.md).

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
│   ├── macos-installation.md           # macOS installation, Gatekeeper resolution & permissions
│   ├── repository-documentation-audit.md # Complete documentation audit and verification report
│   └── security.md                     # Cryptographic storage, data transmission, and privacy
├── .github/                            # GitHub templates and workflows
└── app/                                # Application codebase
    ├── lib/                            # Flutter app shell (Dart, BLoC, Freezed)
    ├── android/                        # Android native project (Kotlin, C++ AOSP, CMake)
    ├── ios/                            # iOS native project (Swift, UIKit, App Group)
    ├── macos/                          # macOS native project (Swift, Cocoa, Accessibility)
    ├── test/                           # Flutter unit and contract tests
    └── pubspec.yaml                    # Flutter dependencies and configuration
```

---

## Development Prerequisites

- **Flutter SDK:** Version 3.13.2+ (Dart SDK `^3.13.2`)
- **macOS:** macOS 12+ and Xcode 15+ (for macOS & iOS builds)
- **Android SDK:** `compileSdk 37`, Android NDK, CMake `3.22.1`
- **AI Credentials:** An API key from at least one supported provider (Gemini, OpenAI, Groq, or OpenRouter)

---

## Setup & Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/pavan-marthala/atfix.git
   cd atfix/app
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

### Enabling AtFix on Device

- **macOS:** Launch the app to complete the onboarding verification for Accessibility and Input Monitoring permissions. Then select text in any application and press <kbd>Control</kbd> + <kbd>Option</kbd> + <kbd>Space</kbd>.
- **Android:** *Settings > System > Languages & Input > On-screen keyboard > Manage on-screen keyboards > Toggle AtFix on.*
- **iOS:** *Settings > General > Keyboard > Keyboards > Add New Keyboard... > Select AtFix.*

---

## Testing

Run tests from the repository root:

```bash
# Run Flutter unit and contract tests
cd app && flutter test

# Run Android native unit tests
cd app/android && ./gradlew test
```

For complete build and debugging workflows, refer to [docs/development.md](docs/development.md).

---

## Security & Privacy

- **On-Device Storage:** Sensitive credentials (API keys) are stored in hardware-backed storage (Android KeyStore with AES-256-GCM; iOS/macOS Keychain with `kSecClassGenericPassword`).
- **Data Transmission:** Only text explicitly targeted by a shortcut command or `@` prompt is sent over HTTPS to the user's chosen AI provider. No text is transmitted during ordinary typing.
- **Zero App Telemetry:** AtFix does not collect, record, or transmit keystrokes, personal information, analytics, or crash reports.
- **External Pings:** When a GIF is inserted on Android, Giphy's API requires an HTTP ping to an `onsend` analytics URL to comply with Giphy's API terms.

For cryptographic and privacy details, see [docs/security.md](docs/security.md). To report vulnerabilities, review [SECURITY.md](SECURITY.md).

---

## Contributing

Contributions are welcome! Please review [CONTRIBUTING.md](CONTRIBUTING.md) for branch naming conventions, Conventional Commit standards, and guidelines on preserving AOSP licensing when touching native code.

All participants are expected to adhere to our [Code of Conduct](CODE_OF_CONDUCT.md).

---

## License & Third-Party Attribution

This project is licensed under the [Apache License, Version 2.0](LICENSE).

- **Android Open Source Project (AOSP) LatinIME:** Portions of the Android suggestion engine and native C++ code are derived from AOSP LatinIME under the Apache License 2.0 (Copyright (C) 2010–2014 The Android Open Source Project).
- See the [NOTICE](NOTICE) file for complete third-party attribution notices.

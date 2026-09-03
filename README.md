# AI Keyboard

![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)

An AI-powered keyboard application for Android and iOS.
It features a Flutter application shell for managing settings and configuration, coupled with native keyboard implementations. The keyboard integrates various AI providers to offer real-time text transformations like rewriting, fixing grammar, translating, and summarizing directly from your keyboard using a slash command system.

⚠️ **Note:** This project is in early/active development and is not yet production-ready.

## Table of Contents
- [Features](#features)
- [Supported AI Providers](#supported-ai-providers)
- [Prerequisites](#prerequisites)
- [Setup & Installation](#setup--installation)
- [Testing](#testing)
- [Architecture & Implementation Details](#architecture--implementation-details)
- [Project Structure](#project-structure)
- [Security & API Keys](#security--api-keys)
- [Known Limitations & Experimental Features](#known-limitations--experimental-features)
- [Contributing](#contributing)
- [License & Attribution](#license--attribution)

## Features

- **Custom Native Keyboards:**
  - Android: `InputMethodService` with modern Compose UI.
  - iOS: Swift keyboard extension.
- **AI Text Transformation:** Use built-in slash commands (e.g., `/fix`, `/translate`, `/rewrite`, `/summarize`) to leverage AI directly as you type.
- **Multi-Provider AI Support:** Switch seamlessly between multiple AI providers at runtime.
- **AOSP Suggestion Engine:** Native word predictions for Android derived from AOSP LatinIME.
- **GIF Search:** Integrated Giphy API support for finding and sending GIFs.
- **Voice Input:** Built-in voice dictation support.
- **Clipboard History:** Manage and paste recently copied items.
- **Customizable Layout:** Optional number row toggle.
- **Secure Storage:** API keys and credentials are encrypted using Android KeyStore (AES-256-GCM) and iOS Keychain.

## Supported AI Providers

Users must provide their own API keys for the AI providers they wish to use:
- **Google Gemini** (via REST API)
- **OpenAI** (via REST API)
- **Groq** (via REST API)
- **OpenRouter** (via REST API)

## Prerequisites

To build and run the project, ensure you have the following installed:
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (`^3.13.2` Dart SDK)
- Android SDK with NDK (`compileSdk 37`)
- CMake `3.22.1` (required for AOSP native compilation)
- Xcode (for iOS and macOS builds)
- An API key from at least one supported AI provider
- A Giphy API key (for GIF search functionality)

## Setup & Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/pavan-marthala/ai_keyboard.git
   cd ai_keyboard/app
   ```

2. **Fetch dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app (shell/settings):**
   ```bash
   flutter run
   ```

## Testing

The project includes comprehensive test coverage across the Flutter and native layers.
- **Flutter Unit Tests:** Covers DI setup, AI model entities, transformation prompts, command parser, iOS contract tests, keyboard controller, and settings.
  ```bash
  cd app && flutter test
  ```
- **Android Native Tests:** Located in `app/android/app/src/test/`.

## Architecture & Implementation Details

For in-depth architecture details—including the clean architecture approach, BLoC state management, and the interaction between the Flutter shell and native keyboard implementations—please see the [App README](app/README.md).

## Project Structure

```text
/
├── README.md
├── CONTRIBUTING.md
├── SECURITY.md
├── CODE_OF_CONDUCT.md
├── LICENSE
├── NOTICE
├── docs/
├── .github/
└── app/
    ├── lib/                    # Flutter/Dart source (app shell, settings, BLoC)
    ├── android/
    │   └── app/src/main/
    │       ├── kotlin/         # Native Android keyboard, AI integration, suggestions
    │       ├── cpp/            # AOSP LatinIME C/C++ via JNI
    │       ├── res/            # Layouts, drawables, icons
    │       └── assets/         # Dictionary files
    ├── ios/
    │   ├── Runner/             # Flutter host app
    │   ├── KeyboardExtension/  # iOS keyboard extension (Swift)
    │   └── Shared/             # Keychain and config storage
    ├── test/                   # Unit & contract tests
    └── pubspec.yaml
```

## Security & API Keys

- **Bring Your Own Keys:** Users enter their AI and API keys directly in the app's Settings page.
- **Secure Storage:** All keys are stored securely using `flutter_secure_storage` (backed by Android KeyStore and iOS Keychain).
- **No Hardcoded Keys:** Keys are **never** committed to source control. Use dummy/placeholder keys (e.g., `your-api-key-here`) during local development if necessary.

## Known Limitations & Experimental Features

⚠️ **iOS Keyboard:** The iOS keyboard extension is experimental. The basic layout and AI commands function correctly, but native word suggestions are not yet implemented.
⚠️ **Suggestion Engine:** The AOSP-based word suggestion engine is currently experimental. It supports only English with a single main dictionary. User dictionary persistence across sessions is not yet supported.
⚠️ **Production Signing:** No production signing is currently configured; the app builds using debug keys.
⚠️ **Microphone Permission:** Voice input requires explicit microphone permissions.

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md) for details on how to get started.

## License & Attribution

This project is licensed under the [Apache 2.0 License](LICENSE).

- The AOSP LatinIME components are also licensed under Apache 2.0 (Copyright The Android Open Source Project).
- See the [NOTICE](NOTICE) file for additional third-party attribution.

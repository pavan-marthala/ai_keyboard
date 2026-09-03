# Contributing to AI Keyboard

Welcome! We appreciate your interest in contributing to the AI-powered keyboard for Android and iOS. This document outlines the process for contributing to the project.

## Code of Conduct
By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md). Please read it to understand what behavior is expected.

## Prerequisites
Before you begin, ensure you have the following installed:
- Flutter SDK (^3.13.2 Dart SDK)
- Android SDK with NDK (compileSdk 37)
- CMake 3.22.1
- Xcode (for iOS development)

## Local Setup
To set up the project locally, run the following commands:
```bash
git clone https://github.com/pavan-marthala/ai_keyboard.git
cd ai_keyboard/app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Development Workflow
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Make your changes
4. Run tests: `cd app && flutter test`
5. Submit a Pull Request

## Branch Naming Conventions
Please use the following prefixes for your branches:
- `feature/description`
- `fix/description`
- `docs/description`
- `refactor/description`

## Commit Messages
We use conventional commits. Please use the following prefixes:
- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation changes
- `refactor:` for code refactoring
- `test:` for adding or updating tests
- `chore:` for maintenance tasks

## Testing Expectations
- Add tests for new features to ensure they work as expected.
- Existing tests must pass before a PR is accepted.
- Run `flutter test` locally before submitting your PR.
- Android native tests are located in `app/android/app/src/test/`.

## Pull Request Expectations
- Fill out the PR template when submitting.
- Link to any related issues.
- Include screenshots or videos for UI changes.
- Keep PRs focused and reasonably sized for easier review.

## Security Requirements
- **NEVER** commit API keys, tokens, passwords, or secrets.
- Use environment variables or secure storage for sensitive data.
- If you accidentally commit a secret, notify maintainers immediately at mgpavank@gmail.com.
- Redact sensitive information from logs in bug reports.

## Guidance for Native Code
- Android Kotlin code is in `app/android/app/src/main/kotlin/`.
- iOS Swift code is in `app/ios/KeyboardExtension/` and `app/ios/Shared/`.
- AOSP C/C++ code is in `app/android/app/src/main/cpp/`.
- Test native changes on actual devices when possible.

## Guidance for AOSP Suggestion Engine
- Files in `suggestion/aosp/` and `cpp/aosp_latinime/` are derived from AOSP LatinIME.
- Preserve existing Apache 2.0 copyright headers.
- Do not remove or alter upstream license notices.
- When modifying AOSP-derived code, add a comment noting the modification.

## Documentation
Please update documentation (`.md` files) if your changes affect the behavior of the application.

## Issues
Before creating a new issue, please search existing issues to avoid duplicates. When creating a new issue, use the provided issue templates.

## Contact
If you have any questions, feel free to reach out at mgpavank@gmail.com.

---
This contributing guide is specific to the AI Keyboard project.

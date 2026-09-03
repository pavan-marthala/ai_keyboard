# Security and Privacy

Security and user privacy are core tenets of the AI Keyboard project. This document outlines how sensitive data is handled and our development practices.

## 1. API Key Storage

API keys are treated as highly sensitive user credentials and are stored using industry-standard secure storage mechanisms on each platform:

*   **Android**: Utilizes the Android KeyStore with AES-256-GCM encryption via `NativeSecureStorage.kt`. Keys are hardware-backed on supported devices.
*   **iOS**: Utilizes the iOS Keychain with `kSecClassGenericPassword` via `KeychainCredentialStore.swift`.
*   **Flutter (App Shell)**: Uses the `flutter_secure_storage` package, which acts as a secure wrapper around the aforementioned platform-specific stores.
*   **Encryption at Rest**: All API keys are encrypted at rest and only decrypted in memory when an API call is required.

## 2. Data Flow

When a user invokes an AI text transformation:

1.  **Input**: User types text (e.g., "rewrite this: hello world").
2.  **Request Construction**: The native keyboard constructs an HTTP request containing the selected text and the system prompt.
3.  **Authentication**: The API key is injected into the request (as a query parameter for Gemini, or as a Bearer token for OpenAI/Groq/OpenRouter).
4.  **Transmission**: The request is sent directly to the configured AI provider.
5.  **Encryption in Transit**: All API communication is strictly conducted over HTTPS.

## 3. What Data Leaves the Device

We believe in complete transparency regarding network activity. The following data leaves the device:

*   **Text Content**: Only the specific text being transformed by a command is sent to the selected AI provider.
*   **API Key**: Sent solely to authenticate with the respective provider.
*   **GIF Queries**: Search terms for GIFs are sent to Giphy.
*   **Voice Audio**: Audio data is sent to the device's default speech recognition service (which may be processed on-device depending on OS capabilities).

> [!IMPORTANT]
> **No Telemetry**: The AI Keyboard does not collect any telemetry, analytics, keystroke logs, or crash reporting data.

## 4. Development Security Practices

Contributors must adhere to the following practices:

*   **No Secrets in Source**: Never commit API keys, signing certificates, or other secrets to the repository.
*   **Build Configurations**: Use environment variables for build-time secrets (e.g., `GIPHY_API_KEY`).
*   **Ignored Files**: Ensure `local.properties`, `.env` files, keystores, and certificate files remain in `.gitignore`.
*   Always review changes against the root `.gitignore` before committing.

## 5. Third-Party Dependencies

*   **Direct API Access**: AI providers are accessed directly via their public REST APIs to minimize third-party SDK footprint.
*   **No Tracking SDKs**: No Firebase, analytics, or tracking SDKs are included in the project.
*   **Dependency Management**: Dependencies are strictly managed and audited via `pubspec.yaml` (Flutter) and `build.gradle.kts` (Android).

## 6. Reporting Security Issues

If you discover a security vulnerability, we appreciate your help in disclosing it responsibly.

*   **Contact**: Please email mgpavank@gmail.com directly.
*   **Do Not Use Public Issues**: Do not create public GitHub issues for unpatched security vulnerabilities.
*   For full details on our disclosure policy, please see the `SECURITY.md` file in the root directory.

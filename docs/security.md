# Security, Cryptography & Privacy Specification

This document details the security architecture, cryptographic implementations, network transmission characteristics, and privacy posture of AtFix.

---

## 1. Credential Management & Storage Architecture

AtFix operates on a **Bring Your Own Key (BYOK)** model. Users supply their own API keys for the AI providers they choose to enable. No default or shared API credentials are baked into the repository or release binaries.

### Storage Implementations by Platform

```text
┌─────────────────────────────────────────────────────────────┐
│                       Flutter App Shell                     │
│               (flutter_secure_storage)                      │
└──────────────┬───────────────────────────────┬──────────────┘
               │                               │
       MethodChannel                   MethodChannel
 (com.pk.atfix/credentials) (com.pk.atfix/credentials)
               │                               │
               ▼                               ▼
┌─────────────────────────────┐ ┌─────────────────────────────┐
│       Android Native        │ │         iOS Native          │
│    (NativeSecureStorage)    │ │   (KeychainCredentialStore) │
│                             │ │                             │
│ • Android KeyStore provider │ │ • iOS Keychain Services     │
│ • AES-256-GCM cipher        │ │ • kSecClassGenericPassword  │
│ • Hardware-backed on device │ │ • Service: com.pk.atfix│
│ • Key alias:                │ │   .apiKey                   │
│   AtFIxKeyStoreKey     │ │ • Accessible by host and   │
│ • IV + ciphertext stored in │ │   keyboard extension        │
│   private SharedPreferences │ └─────────────────────────────┘
└─────────────────────────────┘
```

#### Android Native Storage (`NativeSecureStorage.kt`)

- **Key Generation & Storage:** Keys are generated within the Android KeyStore (`AndroidKeyStore`) under the alias `AtFIxKeyStoreKey`.
- **Cipher Transformation:** `AES/GCM/NoPadding` with a 256-bit key and 128-bit authentication tag (`GCMParameterSpec`).
- **Encrypted Payload Format:** A byte array containing `[1 byte IV length] + [IV bytes] + [GCM ciphertext with auth tag]` is encoded with `Base64.NO_WRAP` and saved in private SharedPreferences (`atfix_secure_prefs`).
- **Decryption Access:** Credentials are only decrypted in memory during the execution of an explicit `@` text transformation command and are immediately discarded after the request completes.

#### iOS Native Storage (`KeychainCredentialStore.swift`)

- **Storage Subsystem:** Apple Keychain Services using the `kSecClassGenericPassword` item class.
- **Service Identifier:** `com.pk.atfix.apiKey`.
- **Account Key:** Stored per provider (`provider.lowercased()`).
- **Accessibility:** Configured for access by both the main container application and the keyboard extension target.

#### Non-Sensitive Configuration Separation

Non-sensitive configuration items—such as active provider selection, model identifiers, custom base URLs, and disabled command triggers—are deliberately separated from secrets:

- Android: Stored in unencrypted SharedPreferences (`atfix_config_prefs`).
- iOS: Stored in shared `UserDefaults` using the App Group suite `group.com.pk.atfix.shared`.

---

## 2. Network Data Transmission

AtFix establishes external network connections strictly for user-requested features:

| Traffic Category | Destination Endpoint | Trigger Mechanism | Data Transmitted |
| :--- | :--- | :--- | :--- |
| **AI Text Transformation** | Selected Provider API (Google, OpenAI, Groq, OpenRouter) | Entering a trailing `@` command (e.g. `@fix`) | Preceding user text, system prompt, and API key. |
| **GIF Search** | `api.giphy.com` | Entering search queries in GIF mode | User-entered search query string and Giphy API key. |
| **GIF Analytics Pingback** | Giphy analytics endpoint (`onsend` URL) | Tapping a GIF item to insert it | An HTTP ping is sent to Giphy's `sendAnalyticsUrl` to comply with Giphy API attribution terms. |
| **Voice Recognition** | Android System `SpeechRecognizer` | Tapping the microphone toolbar icon | Audio captured from device microphone, processed on-device or via the user's configured system speech engine. |

### What Never Leaves the Device

- **Ordinary Typing:** Keystrokes, words, sentences, and composition events that do not invoke an explicit `@` command are handled strictly on-device by the keyboard view and AOSP suggestion engine.
- **Keystroke Logging:** The keyboard does not log keystrokes to disk or external servers.
- **Telemetry & Crash Tracking:** The AtFix project bundles **no** telemetry SDKs, analytics tracking libraries (Firebase, Mixpanel, Amplitude), or crash reporting frameworks (Crashlytics, Sentry).

---

## 3. Network Security & Transport Encryption

- **Mandatory HTTPS:** All communication with AI providers and Giphy uses HTTPS (TLS 1.2+).
- **No Plaintext Transmissions:** Plaintext HTTP endpoints are disallowed by default on modern Android (`usesCleartextTraffic=false`) and iOS (App Transport Security).
- **Custom Base URLs:** If a user specifies a custom base URL for private or self-hosted LLM endpoints, HTTPS remains strongly recommended.

---

## 4. Source Control & Secret Hygiene

To ensure no sensitive materials are accidentally committed to the repository:

1. **Pre-Configured `.gitignore`:**
   - Secrets files: `.env`, `.env.*`
   - Key material: `*.jks`, `*.keystore`, `*.p12`, `*.pem`, `*.key`
   - Build environment: `app/android/local.properties`
   - Firebase & cloud configs: `google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`, `service-account*.json`
2. **Build-Time Key Injection:**
   - Keys such as `GIPHY_API_KEY` are read from environment variables or ignored `local.properties` files during Gradle builds.
   - The fallback key in `build.gradle.kts` (`dc6zaTOxFJmzC`) is Giphy's public demo/test key intended solely for development validation.
3. **Commit Scrutiny:**
   - All pull requests and commits are verified to ensure no developer keys or tokens are introduced.

---

## 5. Security Disclosure & Contact

If you discover a vulnerability or security flaw, please review [SECURITY.md](../SECURITY.md) for reporting instructions. Do not disclose vulnerabilities in public GitHub issues.

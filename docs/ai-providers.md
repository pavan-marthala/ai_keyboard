# AI Provider Integration Reference

This document provides a detailed specification for the AI providers integrated into the AtFIx, covering network protocols, authentication mechanisms, default models, runtime parameters, and storage locations across Android, iOS, and Flutter.

---

## 1. Supported Providers Overview

The AtFIx supports four AI providers. All four providers are implemented natively across Android and iOS, as well as within the Flutter application shell:

| Provider | Platform Support | API Protocol | Default Model | Authentication Style |
| :--- | :--- | :--- | :--- | :--- |
| **Google Gemini** | Android, iOS, Flutter | REST (`generateContent`) | `gemini-1.5-flash` | Query parameter: `?key={apiKey}` |
| **OpenAI** | Android, iOS, Flutter | REST (`chat/completions`) | `gpt-4o-mini` | Header: `Authorization: Bearer {apiKey}` |
| **Groq** | Android, iOS, Flutter | REST (`chat/completions`) | `llama-3.3-70b-versatile` | Header: `Authorization: Bearer {apiKey}` |
| **OpenRouter** | Android, iOS, Flutter | REST (`chat/completions`) | `openai/gpt-4o-mini` | Header: `Authorization: Bearer {apiKey}` |

---

## 2. Execution Architecture & Direct Native Calls

A critical architectural design of the AtFIx is that **native keyboards invoke AI provider endpoints directly without routing through the Flutter runtime**:

- **Android Native Keyboard:** Invokes AI endpoints using `java.net.HttpURLConnection` inside Kotlin coroutines on `Dispatchers.IO` (`GeminiProvider.kt`, `OpenAiProvider.kt`, `GroqProvider.kt`, `OpenRouterProvider.kt`).
- **iOS Native Keyboard:** Invokes AI endpoints using Swift's `URLSession` async APIs (`GeminiProvider.swift`, `OpenAiProvider.swift`, `GroqProvider.swift`, `OpenRouterProvider.swift`).
- **Flutter App Shell:** Uses `Dio` for model discovery and sandbox playground testing (`gemini_provider.dart`, `openai_provider.dart`, etc.).

---

## 3. Detailed Provider Specifications

### Google Gemini

- **Default Endpoint:** `https://generativelanguage.googleapis.com/v1beta/models/{cleanModelId}:generateContent?key={apiKey}`
- **Model ID Sanitization:** Automatically removes any preceding `"models/"` prefix (e.g. `models/gemini-1.5-flash` becomes `gemini-1.5-flash`).
- **Default Model:** `gemini-1.5-flash`
- **Custom Base URL Override:** Supported. If configured, endpoint becomes `{customBaseUrl}/models/{cleanModelId}:generateContent?key={apiKey}`.
- **Request Payload Structure:**

  ```json
  {
    "systemInstruction": {
      "parts": [{ "text": "<system_prompt>" }]
    },
    "contents": [
      {
        "parts": [{ "text": "<input_text>" }]
      }
    ],
    "generationConfig": {
      "temperature": 0.0,
      "maxOutputTokens": 1024
    }
  }
  ```

- **Response Extraction:** Reads `candidates[0].content.parts[0].text`.
- **Key Registration:** [Google AI Studio](https://aistudio.google.com/app/apikey).

---

### OpenAI

- **Default Endpoint:** `https://api.openai.com/v1/chat/completions`
- **Default Model:** `gpt-4o-mini`
- **Custom Base URL Override:** Supported. If configured, endpoint becomes `{customBaseUrl}/chat/completions`.
- **Authentication:** `Authorization: Bearer {apiKey}` header.
- **Request Payload Structure:**

  ```json
  {
    "model": "gpt-4o-mini",
    "temperature": 0.0,
    "max_tokens": 1024,
    "messages": [
      { "role": "system", "content": "<system_prompt>" },
      { "role": "user", "content": "<system_prompt>\n\nText:\n<input_text>" }
    ]
  }
  ```

- **Response Extraction:** Reads `choices[0].message.content`.
- **Key Registration:** [OpenAI Platform](https://platform.openai.com/api-keys).

---

### Groq

- **Default Endpoint:** `https://api.groq.com/openai/v1/chat/completions`
- **Default Model:** `llama-3.3-70b-versatile`
- **Custom Base URL Override:** Supported. If configured, endpoint becomes `{customBaseUrl}/chat/completions`.
- **Authentication:** `Authorization: Bearer {apiKey}` header.
- **Request Payload Structure:** Matches the OpenAI-compatible chat completion payload with `temperature: 0.0` and `max_tokens: 1024`.
- **Response Extraction:** Reads `choices[0].message.content`.
- **Key Registration:** [Groq Console](https://console.groq.com/keys).

---

### OpenRouter

- **Default Endpoint:** `https://openrouter.ai/api/v1/chat/completions`
- **Default Model:** `openai/gpt-4o-mini`
- **Custom Base URL Override:** Supported. If configured, endpoint becomes `{customBaseUrl}/chat/completions`.
- **Authentication:** `Authorization: Bearer {apiKey}` header.
- **Request Payload Structure:** Matches the OpenAI-compatible chat completion payload with `temperature: 0.0` and `max_tokens: 1024`.
- **Response Extraction:** Reads `choices[0].message.content`.
- **Key Registration:** [OpenRouter](https://openrouter.ai/keys).

---

## 4. Configuration Storage Locations

Provider configurations and API credentials are saved separately to guarantee security:

### Non-Sensitive Settings (Active Provider, Active Model, Base URL)

- **Android:** Stored in `SharedPreferences` under `atfix_config_prefs` via `NativeSecureStorage.saveConfig(...)`.
- **iOS:** Stored in `UserDefaults(suiteName: "group.com.pk.atfix.shared")` via `SharedConfigurationStore.saveConfig(...)`.
- **Flutter:** Persisted in `SharedPreferences` via `SettingsRepositoryImpl.dart`.

### Sensitive Credentials (API Keys)

- **Android:** Encrypted using Android KeyStore AES-256-GCM (`AtFIxKeyStoreKey`) and stored as Base64 ciphertext in `atfix_secure_prefs`.
- **iOS:** Stored in the iOS Keychain under service identifier `com.pk.atfix.apiKey`.
- **Flutter:** Managed through `FlutterSecureStorage`.

---

## 5. Security & Privacy Considerations

- **User-Supplied Keys Only:** No shared, bundled, or developer API keys are included in the repository or application binaries.
- **Strict HTTPS:** All endpoints default to HTTPS and require valid TLS certificates.
- **Targeted Data Transmission:** Only text preceding an `@` command is sent to the selected AI provider. Standard keystrokes typed without an `@` command are never transmitted over the network.

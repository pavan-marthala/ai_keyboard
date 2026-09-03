# AI Providers

The AI Keyboard supports multiple AI providers for text transformation. This document details the supported providers, configuration, and internal architecture.

## 1. Supported Providers

| Provider | Platforms | API Style | Key URL |
|----------|-----------|-----------|----------|
| **Google Gemini** | Android, iOS, Flutter | REST (`generateContent`) | [Get Key](https://aistudio.google.com/app/apikey) |
| **OpenAI** | Android, iOS, Flutter | REST (`chat/completions`) | [Get Key](https://platform.openai.com/api-keys) |
| **Groq** | Android, iOS, Flutter | REST (`chat/completions`, OpenAI-compatible) | [Get Key](https://console.groq.com/keys) |
| **OpenRouter** | Android, iOS, Flutter | REST (`chat/completions`, OpenAI-compatible) | [Get Key](https://openrouter.ai/keys) |

## 2. Configuring API Keys

Users must provide their own API keys to use the AI transformation features.

1.  Open the AI Keyboard app.
2.  Go to **Settings**.
3.  Select a provider from the list.
4.  Enter your API key (e.g., `your-api-key-here`).

**Key Storage**: Keys are stored securely on the device using platform-native secure storage (Android KeyStore / iOS Keychain). Keys *never* leave the device except when making direct API calls to the chosen provider.

## 3. How AI Transformation Works

1.  **Invocation**: The user types text and invokes a command (e.g., using a slash command or UI button).
2.  **Request**: The native keyboard reads the input text, constructs a prompt, and sends it directly to the selected provider's API.
3.  **Response**: The generated response is returned and replaces or augments the input text in the text editor.

**Default Parameters**:
*   Temperature: `0.0` (for deterministic, predictable outputs).
*   Max tokens: `1024`.

## 4. Provider Architecture

The AI layer is designed with a consistent interface across platforms.

*   **Interface**: `AiProvider` defines a common `transform()` method.
*   **Factory**: `AiProviderFactory` is responsible for selecting and instantiating the provider based on user configuration.
*   **Implementation**: Each provider implements its own HTTP communication independently without relying on heavy SDKs.
    *   **Android**: Uses `HttpURLConnection` for lightweight, native networking.
    *   **iOS**: Uses `URLSession`.
    *   **Flutter (App Shell)**: Uses the `Dio` HTTP client for testing and configuration.

## 5. Security Considerations

*   **User-Provided Keys**: API keys are supplied by the user. The app does not bundle or provide shared API keys.
*   **Data Transmission**: Text input is sent to third-party APIs. Users should be aware that content transformed by the AI is sent to the selected provider.
*   **Source Control**: No API keys are stored in source control.
*   **Encryption**: All API communication is conducted over HTTPS to ensure data in transit is encrypted.

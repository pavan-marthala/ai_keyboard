# Android Keyboard Implementation

This document details the architecture and implementation of the Android native keyboard component of the AI Keyboard.

## 1. Overview

The Android keyboard is implemented as a custom `InputMethodService` that leverages Jetpack Compose for rendering its modern, declarative UI.

## 2. Key Components

*   **KeyboardService**: The entry point for the Android keyboard. It extends `InputMethodService` and manages the overarching lifecycle and input connection.
*   **KeyboardController**: Handles core logic including event routing, mode switching, and orchestrating the AI text transformation pipeline.
*   **KeyboardView**: The UI layer built entirely with Jetpack Compose.
*   **TextEditor**: A wrapper around the `InputConnection` to safely handle text manipulation, selection, and insertion.

## 3. AOSP Suggestion Engine

The keyboard features a predictive text engine adapted from the Android Open Source Project (AOSP).

*   **Origin**: Derived from AOSP LatinIME.
*   **Native Code**: C/C++ native library compiled via CMake and the Android NDK.
*   **Bridge**: JNI (Java Native Interface) bridge connects the Kotlin frontend to the native backend.
*   **Dictionary**: Utilizes a single English dictionary (`main_en.dict`, ~1MB).
*   **Status**: Currently marked as *Experimental*. It provides basic word prediction but lacks advanced auto-correction tuning.
*   **Licensing**: These specific files are Apache 2.0 licensed (Copyright The Android Open Source Project).

## 4. Keyboard Modes

The keyboard supports several distinct operational modes:

1.  **Text Input**: The primary alphanumeric keyboard layout.
2.  **AI Command Mode**: Interface for interacting with AI features and prompts.
3.  **GIF Search**: Integration for finding and inserting animated GIFs.
4.  **Voice Input**: Speech-to-text functionality.
5.  **Clipboard History**: Access to recently copied text.

## 5. AI Command Flow

The process of executing an AI command involves several steps:

1.  **Parsing**: `CommandParser` continuously monitors input for trigger patterns (e.g., slash commands).
2.  **Mapping**: `NativeCommandRegistry` maps the detected command alias to a specific system prompt or action.
3.  **Execution**: `AiTextTransformer` takes the user's text and the associated prompt, orchestrating the API call to the configured provider.
4.  **Insertion**: Upon success, the result is inserted back into the application via the `TextEditor`.

## 6. GIF Support

*   **Provider**: Powered by the Giphy API.
*   **Configuration**: The API key is configured at build time via the `GIPHY_API_KEY` environment variable or defined in `local.properties`.
*   **Insertion Mechanism**: Uses `InputConnection.commitContent()` to securely insert media into supported target applications.

## 7. Secure Storage

*   **Implementation**: `NativeSecureStorage` handles sensitive data (like API keys) on the Android side.
*   **Technology**: Backed by the Android KeyStore system.
*   **Encryption**: Utilizes AES-256-GCM encryption.
*   **Hardware Security**: Keys are hardware-backed on supported Android devices, providing robust protection against extraction.

# Android Keyboard Architecture & Implementation

This document provides an exhaustive technical reference for the native Android keyboard implementation in `app/android/`.

---

## 1. Overview & Service Lifecycle

The Android keyboard is implemented as a native input method engine (IME) using the standard Android `InputMethodService` framework.

### Service Entry Point: `KeyboardService.kt`
Located in `app/android/app/src/main/kotlin/com/pk/ai_keyboard/keyboard/KeyboardService.kt`.

- **Inheritance:** Extends `android.inputmethodservice.InputMethodService`.
- **Active Singleton Reference:** Maintains `activeInstance: KeyboardService?` in companion object, allowing companion components (such as `MainActivity` via MethodChannel) to notify the active keyboard instance of dynamic preference updates (e.g. number row toggling).
- **Lifecycle Implementation:**
  - `onCreate()`: Instantiates `KeyboardController(applicationContext)`.
  - `onCreateInputView()`: Inflates and returns `KeyboardView(this)` and calls `keyboardView.init(controller)`.
  - `onStartInput(attribute, restarting)`: Calls `controller.invalidateInputContext()` and `controller.onEditorInfoChanged(attribute)`.
  - `onStartInputView(info, restarting)`: Connects `currentInputConnection` to `controller.onInputConnectionChanged(...)`, resets active mode to `KeyboardMode.MAIN`, and propagates `EditorInfo` to the view.
  - `onFinishInputView(finishingInput)`: Calls `controller.invalidateInputContext()`.
  - `onFinishInput()`: Disconnects the `InputConnection` reference and cleans up active transformation jobs.
  - `onDestroy()`: Nulls `activeInstance` and triggers `controller.onDestroy()`.

---

## 2. Core Controller: `KeyboardController.kt`

The `KeyboardController` coordinates state, UI events, hardware feedback, AI transformations, and text editing operations.

### Dependencies
- `TextEditor`: Abstraction over `android.view.inputmethod.InputConnection`.
- `AiTextTransformer`: Coordinates AI API invocations.
- `SuggestionEngine`: Interface fulfilled by `AospSuggestionAdapter`.
- `VoiceInputController`: Manages voice recognition states and listeners.
- `ClipboardHistoryManager`: Interacts with system clipboard and caches history.
- `GifProvider` (`GiphyGifProvider`): Searches for animated GIFs.
- `RecentGifManager`: Manages recently used GIFs.
- `GifInserter`: Inserts GIF content via `commitContent`.
- `KeyboardHeightRepository`: Manages custom keyboard height in dp.
- `NumberRowRepository`: Manages number row visibility.

### Keyboard Modes (`KeyboardMode.kt`)
The controller manages keyboard mode transitions using the `KeyboardMode` enum:
1. `MAIN`: Primary QWERTY alphanumeric layout.
2. `MORE`: Secondary symbol and special character layout.
3. `EMOJI`: Emoji selection surface powered by AndroidX Emoji2.
4. `CLIPBOARD`: History panel displaying recently copied text clips.
5. `GIF`: Animated GIF search and preview surface.
6. `STICKERS`: Reserved sticker selection mode.
7. `RESIZE`: On-screen keyboard height adjustment mode.

### Shift State Handling
- `ShiftState` enum: `LOWERCASE`, `SHIFT_ON`, `CAPS_LOCK`.
- Double-tap detection on the Shift key within 300ms locks the state to `CAPS_LOCK`.

---

## 3. UI Hierarchy: `KeyboardView.kt`

The keyboard UI is constructed entirely with standard Android Views (not Jetpack Compose).

### View Architecture
- **Root Class:** `class KeyboardView : LinearLayout`.
- **Layout & Structure:**
  - Toolbar container with action buttons (AI commands, mic, emoji, clipboard, GIF, number row, settings).
  - Main keyboard view container dynamically populated according to active `KeyboardMode`.
  - Emoji picker: Embeds `androidx.emoji2.emojipicker.EmojiPickerView` for full native emoji support.
  - Clipboard & GIF lists: Built using `androidx.recyclerview.widget.RecyclerView` with `GridLayoutManager`.
  - Dynamic key rendering: Uses custom programmatic view creation for key buttons, labels, and feedback popups.
- **Theming:** Configured through `KeyboardTheme.kt`, supporting dynamic light/dark mode and customizable accent palettes.

---

## 4. Text Manipulation: `TextEditor.kt`

`TextEditor` encapsulates all operations performed on Android's `InputConnection`:

- **Text Extraction:**
  - `getTextBeforeCursor(length)`: Reads up to 1000 characters before the cursor.
  - `getTextAfterCursor(length)`: Reads up to 1000 characters after the cursor.
  - `getSelectedText()`: Returns actively highlighted text if present.
  - `getCurrentWordBeforeCursor()`: Computes the current incomplete word boundary.
- **Text Modification:**
  - `commitText(text, newCursorPosition)`: Inserts characters or strings.
  - `commitClipboardText(text)`: Pastes clipboard items at the current cursor position.
  - `commitRecognizedText(recognizedText)`: Commits voice transcriptions, automatically prefixing a space if preceded by non-whitespace.
  - `deleteSurroundingText(beforeLength, afterLength)`: Deletes specified character spans.

---

## 5. AOSP Suggestion Engine Integration

The Android keyboard integrates an AOSP LatinIME-derived suggestion engine:

### Components & Architecture
- **Adapter:** `AospSuggestionAdapter.kt` implements the `SuggestionEngine` interface.
- **Suggest Controller:** `Suggest.kt` delegates to `DictionaryFacilitatorImpl.kt`.
- **Dictionary Implementation:** `BinaryDictionary.kt` manages dictionary assets.
- **Native JNI Layer:**
  - `NativeBinaryDictionary.kt` loads `liblatinime.so`.
  - Native library compiled via `app/android/app/src/main/cpp/CMakeLists.txt` using C++17.
  - JNI bindings in `app/android/app/src/main/cpp/latinime/latinime_jni.cpp`.
- **Asset Deployment:**
  - `main_en.dict` (~1.07MB binary dictionary) is extracted from Android assets to `context.cacheDir`.
  - Opened via `NativeBinaryDictionary.openNative(cachedPath, 0L, 0L)`.
- **Proximity Calculation:**
  - `KeyboardGeometryBuilder.kt` calculates key coordinates and generates `ProximityInfo` based on keyboard dimensions and number row state.
- **Fallback Behavior:**
  - If the native binary fails to load, `BinaryDictionary` populates an in-memory word map of ~100 common English words to provide baseline suggestions.

---

## 6. AI Command Pipeline

The keyboard detects and processes inline `@` commands as follows:

```text
User types text ending in @command
               │
               ▼
CommandParser.parse(context, textBeforeCursor)
  • Checks last whitespace-delimited token for '@' prefix
  • Rejects URLs ("://") and emails
  • Strips trailing punctuation (.,!?)
  • Separates base trigger (e.g. '@translate') and arguments (e.g. 'es')
  • Validates trigger against NativeCommandRegistry
               │
               ▼
AiTextTransformer.transformText(cleanText, prompt)
  • Reads active provider, model, custom baseUrl, and API key from NativeSecureStorage
  • Dispatches coroutine on Dispatchers.IO
               │
               ▼
AiProvider.transform(...)
  • Android implementation uses java.net.HttpURLConnection directly
  • Formats JSON payload with temperature=0.0 and maxTokens=1024
  • Parses response and extracts transformed text
               │
               ▼
TextEditor.deleteSurroundingText(fullMatchLength, 0)
TextEditor.commitText(transformedText, 1)
```

---

## 7. Media & Supporting Features

### GIF Search & Insertion
- **Provider:** `GiphyGifProvider.kt` queries `https://api.giphy.com/v1/gifs/search`.
- **Configuration:** Uses `BuildConfig.GIPHY_API_KEY` (configured via `GIPHY_API_KEY` environment variable or `local.properties`).
- **Insertion:** `GifInserter.kt` uses `InputConnection.commitContent(...)` with `InputContentInfo` to send image URIs to supported target apps.
- **Analytics:** Silently pings Giphy's `onsend` analytics URL as required by Giphy API usage terms.

### Voice Input
- **Controller:** `VoiceInputController.kt` interfaces with Android's `SpeechRecognizer`.
- **Permission Flow:** An invisible transparent activity (`PermissionRequestActivity.kt`) requests `Manifest.permission.RECORD_AUDIO` on behalf of the IME service.
- **State Machine:** `VoiceState` (`IDLE`, `LISTENING`, `SPEAK_NOW`, `PROCESSING`, `ERROR`).
- **Timeouts:** 3000ms initial silence timeout, 7000ms long idle timeout.

### Clipboard History
- **Manager:** `ClipboardHistoryManager.kt` monitors system clipboard changes using `ClipboardManager.OnPrimaryClipChangedListener`.
- **Persistence:** Recent clips are stored in `SharedPreferences` under `ai_keyboard_clipboard_prefs`.

---

## 8. Secure Storage Implementation

- **Class:** `NativeSecureStorage.kt`.
- **Hardware Protection:** Uses Android KeyStore with alias `AiKeyboardKeyStoreKey`.
- **Cryptographic Details:** AES-256-GCM (`AES/GCM/NoPadding`) with a 128-bit authentication tag.
- **Storage Layout:** Ciphertext prepended with a 1-byte IV length and the IV bytes, Base64-encoded, and stored in `ai_keyboard_secure_prefs`.

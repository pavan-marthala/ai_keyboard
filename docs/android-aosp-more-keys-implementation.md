# AOSP More Keys & Multi-Alternative Long Press Implementation

This document describes the production implementation of AOSP LatinIME More Keys / long-press infrastructure in the AI Keyboard project (`pavan-marthala/ai_keyboard`).

## 1. Overview

The implementation integrates the core mathematical layout, hit detection, and popup presentation of AOSP LatinIME More Keys while preserving:

- Custom `KeyboardView.kt` architecture and layout
- Existing suggestions pipeline and native AOSP C++ dictionary engine
- Toolbar controls, AI features, voice typing, emoji, clipboard, GIF, and resizing
- Single-alternative auto-commit behavior (`Q -> 1`) when the number row is disabled

## 2. Package Architecture

All imported and adapted AOSP More Keys components reside in an isolated package:

```
com.pk.ai_keyboard.ui.aosp.morekeys/
├── MoreKeysPanel.kt            # Core interface defining the popup lifecycle contract
├── KeyboardActionListener.kt   # Interface for delivering code/text input to controller
├── MoreKeySpec.kt              # Parser for comma-delimited more-keys specifications
├── AospKey.kt                  # Lightweight key geometry and state representation
├── AospKeyboard.kt             # Lightweight keyboard container
├── MoreKeysKeyboard.kt         # Multi-column/row layout calculator and boundary clamper
├── MoreKeysDetector.kt         # Sliding hit detector with customizable slide allowance
└── MoreKeysKeyboardView.kt     # Canvas-based popup view with real-time drag highlight

> [!NOTE]
> All AOSP interface definitions were authored in Kotlin (`.kt`) rather than Java (`.java`) to ensure the Android Gradle Plugin's Kotlin compiler (`compileDebugKotlin`) packages them directly into `classes.dex`, preventing `NoClassDefFoundError` at runtime.
```

## 3. Key Model Decoupling

The key model is defined in `com.pk.ai_keyboard.ui.KeyDef.kt`:

```kotlin
data class KeyDef(
    val label: String,
    val hint: String? = null,
    val moreKeysSpec: String? = null,
    val weight: Float = 1.0f,
    val isSpecial: Boolean = false,
    val isSpace: Boolean = false
)
```

- **`label`**: Primary label displayed on the key.
- **`hint`**: Small top-right hint label (e.g. `"1"` for key `Q` when number row is disabled). If `null`, no hint view is created.
- **`moreKeysSpec`**: Comma-separated alternative characters available on long-press.

## 4. Single vs Multi-Alternative Behavior

### Single-Alternative Auto-Commit (`!noPanelAutoMoreKey!`)

- When a key is configured with a single alternative marked with `!noPanelAutoMoreKey!` (e.g. `"!noPanelAutoMoreKey!,2"` on `W`):
  - Touching down starts the long-press detection.
  - When the long-press timer expires, haptic feedback triggers and the character is directly committed without displaying any popup.
  - Normal release does not re-type the primary letter.

### Multi-Alternative Drag-Selection

- When a key is configured with multiple alternatives (e.g. `"1,¹,₁"` on `Q`, or 34 special characters on `,`):
  - Long-press timer expires -> `MoreKeysKeyboardView` popup opens immediately above the parent key.
  - Active pointer is transferred to the popup panel.
  - User drags finger across alternatives -> `MoreKeysDetector` updates the hit key and highlights the selected alternative in real-time.
  - User releases finger -> the highlighted alternative is committed via `controller.onKeyTyped(char)` and the popup dismisses.
  - User drags outside the slide allowance -> popup cancels without inserting unintended characters.

## 5. Comma Key Configuration

The comma key `,` (located immediately before the Enter key on the bottom row) provides 34 commonly used special characters and currency symbols:

```kotlin
val commaMoreKeys = ". , ? , ! , : , ; , ' , \" , - , _ , ( , ) , [ , ] , { , } , / , \\\\ , @ , # , $ , % , & , * , + , = , < , > , ~ , ^ , | , € , £ , ¥ , ₹"
```

- **No top-right hint**: The comma key displays only `,` and has no top-right hint label.
- **Multi-row layout**: The 34 alternatives are laid out in a compact 5x8 grid.
- **Edge clamping**: Because the comma key is near the right edge of the keyboard, `MoreKeysKeyboard.Builder` clamps the popup horizontally so it never extends past the screen boundary.

## 6. Verification and Test Results

- **Unit Tests**:
  - `MoreKeySpecTest`: 5 unit tests pass.
  - `MoreKeysKeyboardTest`: 4 unit tests pass.
  - Gradle test command: `./gradlew testDebugUnitTest` (55 total tests pass).
- **APK Compilation**:
  - Gradle build command: `./gradlew assembleDebug` (BUILD SUCCESSFUL).
  - Output: `app/build/app/outputs/apk/debug/app-debug.apk`.

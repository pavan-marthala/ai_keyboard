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

## 4. Single vs Multi-Alternative Behavior (Phase 9.3)

### Case A — No More Keys

- Touching down and releasing performs normal key tap. Long-pressing does nothing extra.

### Case B — One Unique Automatic Alternative (`!noPanelAutoMoreKey!`)

- When a key has a single unique alternative (e.g. Row 1 keys `Q` through `P` with numbers `1` through `0` when the number row is disabled):
  - Long-press timer expires -> haptic feedback fires and the alternative is directly committed to `controller.onKeyTyped(...)`.
  - No popup is opened. No duplicate alternatives (e.g. `Q` commits `1` directly).
  - Releasing finger does not re-type the primary letter.

### Case C — Multiple Unique Alternatives (Pointer Handoff & Drag Selection)

- When a key has multiple unique alternatives (e.g. Comma key `,` with 34 special characters):
  - Original finger is **STILL DOWN** when the long-press timer expires.
  - The More Keys popup opens above the key, and the existing pointer ID is immediately handed off to `MoreKeysKeyboardView.onDownEvent(...)`.
  - **Below-Popup Touch Projection**: `MoreKeysDetector` projects touch from the parent key onto the bottom row of the popup, so the alternative directly above the finger is immediately selected and highlighted with haptic feedback.
  - **Drag Selection**: As the user drags (`ACTION_MOVE`), `MoreKeysDetector` updates the highlighted alternative in real-time with haptic feedback on change. Moving horizontally navigates columns; moving vertically up navigates higher rows.
  - **Commit on Release**: When the user releases (`ACTION_UP`), the highlighted alternative is committed via `controller.onKeyTyped(char)` and the popup dismisses cleanly.
  - **Cancellation**: Dragging far outside the allowable bounds cancels the selection without committing.

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
  - `MoreKeySpecTest`: 6 unit tests pass (including duplicate alternative deduplication).
  - `MoreKeysKeyboardTest`: 4 unit tests pass (single-row, grid layout, edge clamping).
  - `MoreKeysDetectorTest`: 5 unit tests pass (direct hit, below-popup projection, horizontal drag, vertical row navigation, out-of-bounds cancellation).
  - Full suite `./gradlew testDebugUnitTest`: **BUILD SUCCESSFUL** (all 61 tests pass).
- **APK Compilation**:
  - Gradle build command: `./gradlew assembleDebug`: **BUILD SUCCESSFUL**.
  - Output APK: `app/build/app/outputs/apk/debug/app-debug.apk`.

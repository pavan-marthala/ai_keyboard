# Phase 9.1 — Android AOSP More-Keys / Long-Press Forensic Audit Report

## 1. Executive Summary

This forensic audit investigates the Android keyboard codebase (`pavan-marthala/ai_keyboard`) to determine the exact technical strategy for integrating the Android Open Source Project (AOSP) LatinIME **More Keys / long-press infrastructure** into the existing keyboard without rebuilding the feature from scratch or replacing the custom keyboard UI.

### Key Audit Findings

1. **Current UI Architecture**:
   - The Android keyboard UI in `app/android/app/src/main/kotlin/com/pk/ai_keyboard/ui/KeyboardView.kt` is a custom Android `LinearLayout`.
   - Keys are procedurally built as nested `LinearLayout`, `FrameLayout`, and `TextView` views.
   - The repository currently contains **zero** AOSP LatinIME keyboard UI classes. Only the AOSP LatinIME **suggestion engine** (native C++ trie and Kotlin wrappers in `com.pk.ai_keyboard.suggestion.aosp.*`) is present.

2. **Current Long-Press / Number-Alternative Mechanism**:
   - In `KeyboardView.kt:1930-1964`, long-press detection is implemented via an inline `Handler(Looper.getMainLooper()).postDelayed(longPressRunnable, ViewConfiguration.getLongPressTimeout().toLong())`.
   - It is attached **only** to Row 1 letter keys (`q`, `w`, `e`, `r`, `t`, `y`, `u`, `i`, `o`, `p`) when `numberRowEnabled == false` (`useNumbers == false`).
   - When the long-press timeout expires, it **directly commits the hint number** (`controller.onKeyTyped(hintNumber)`) without displaying any popup (`Option A`).
   - There is **no `ACTION_MOVE` tracking**, no multi-alternative popup, no drag selection, and no key preview.
   - When `numberRowEnabled == true`, long-pressing letter keys does nothing.

3. **AOSP LatinIME More Keys Alignment**:
   - In AOSP LatinIME (`packages/inputmethods/LatinIME`, Apache 2.0), the More Keys system is composed of:
     - `MoreKeySpec`: Parses string specifications (e.g. `"1,¹,₁"` or `"!noPanelAutoMoreKey!,1"`).
     - `Key`: Encapsulates character codes, labels, and an array of `MoreKeySpec`.
     - `MoreKeysKeyboard`: Calculates multi-column/multi-row popup layout and coordinates relative to the touched parent key.
     - `MoreKeysKeyboardView`: Canvas-based view implementing `MoreKeysPanel` that detects hit keys during touch movements (`ACTION_MOVE`) and handles highlighting and key input.
     - `MoreKeysDetector`: Sliding hit detector with customizable slide allowance.
     - `PointerTracker`: Orchestrates touch down, long-press timer, popup display, drag movement forwarding, and finger release commit.
   - AOSP LatinIME natively contains the `!noPanelAutoMoreKey!` flag: when a key has a single alternative marked with this flag, it skips showing a panel and directly commits the character upon long-press timeout. This means the project's existing behavior (`Q -> 1`) can be cleanly expressed as a special case within the standard AOSP mechanism.

4. **Integration Approach**:
   - **Do NOT replace the existing `KeyboardView` with AOSP `MainKeyboardView`**.
   - Import the self-contained AOSP More Keys sub-system (`MoreKeysPanel`, `MoreKeysKeyboardView`, `MoreKeysKeyboard`, `MoreKeysDetector`, `MoreKeySpec`, and minimal `Key`/`Keyboard` support classes).
   - Place a lightweight overlay container in `KeyboardView` to host the canvas-rendered `MoreKeysKeyboardView`.
   - Connect the selected character output from AOSP's `KeyboardActionListener` directly into `KeyboardController.onKeyTyped(char)`.

---

## 2. Current Keyboard Architecture

The Android keyboard consists of three primary layers:

```
┌─────────────────────────────────────────────────────────────┐
│                 KeyboardService (IME Lifecycle)             │
│                 InputMethodService + VoiceImeSwitcher        │
└──────────────┬───────────────────────────────┬──────────────┘
               │                               │
               ▼                               ▼
┌──────────────────────────────┐ ┌────────────────────────────┐
│      KeyboardController      │ │        KeyboardView        │
│  - Shift / Caps Lock state   │ │  - Custom LinearLayout     │
│  - TextEditor (InputConn)    │ │  - Toolbar (icons/chips)   │
│  - SuggestionEngine (AOSP)   │ │  - Main panel container    │
│  - VoiceInputController      │ │  - Procedural key rows     │
│  - NumberRowRepository       │ │  - Touch listeners         │
└──────────────────────────────┘ └────────────────────────────┘
```

### Exact Class & File Relationships

| Component | File Path | Responsibilities |
| --- | --- | --- |
| `KeyboardService` | `app/android/app/src/main/kotlin/com/pk/ai_keyboard/keyboard/KeyboardService.kt` | `InputMethodService` entry point, lifecycle management, window creation, IME switching. |
| `KeyboardController` | `app/android/app/src/main/kotlin/com/pk/ai_keyboard/keyboard/KeyboardController.kt` | Orchestrates shift state, text commits, AI triggers, suggestions, voice input, modes. |
| `KeyboardView` | `app/android/app/src/main/kotlin/com/pk/ai_keyboard/ui/KeyboardView.kt` | View hierarchy, layout rendering (QWERTY, symbols, emoji, clipboard, GIF), touch events. |
| `NumberRowRepository` | `app/android/app/src/main/kotlin/com/pk/ai_keyboard/keyboard/NumberRowRepository.kt` | SharedPreferences storage (`"use_numbers"`) determining number row presence. |
| `TextEditor` | `app/android/app/src/main/kotlin/com/pk/ai_keyboard/text/TextEditor.kt` | Wrapper around `InputConnection` for committing text, deletions, selections, cursor context. |
| `AospSuggestionAdapter` | `app/android/app/src/main/kotlin/com/pk/ai_keyboard/suggestion/aosp/AospSuggestionAdapter.kt` | Bridge between `KeyboardController` and the native C++ LatinIME suggestion engine. |

---

## 3. Current Key Press Flow

### Normal Key Press Flow

```
Physical Touch on Key View (TextView / FrameLayout)
    │
    ▼
onTouchListener: MotionEvent.ACTION_DOWN (KeyboardView.kt:1939, 1984)
    ├── View background set to shapePressed
    ├── Elevation lowered from 1.5dp to 0.5dp
    ├── Scale animation triggered (animatePress, 0.93x scale over 70ms)
    └── Haptic tap executed (HapticFeedbackConstants.KEYBOARD_TAP)
    │
    ▼
User lifts finger: MotionEvent.ACTION_UP (KeyboardView.kt:1947, 1990)
    ├── Handler callbacks removed
    ├── View background restored to shapeNormal
    ├── Elevation restored to 1.5dp
    ├── Scale animation released (animateRelease, 1.0x scale over 120ms)
    └── If !isLongPressed: onClick() invoked
    │
    ▼
onClick() lambda (KeyboardView.kt:1744, 1863)
    └── controller.onKeyTyped(char)
    │
    ▼
KeyboardController.onKeyTyped(char: String) (KeyboardController.kt:271)
    ├── Applies ShiftState (LOWERCASE, SHIFT_ON -> resets to LOWERCASE, CAPS_LOCK)
    ├── Produces charToCommit (e.g. "q" or "Q")
    ├── Calls textEditor.commitText(charToCommit, 1)
    ├── Calls checkForCommandTrigger()
    └── Calls requestSuggestions()
    │
    ▼
TextEditor.commitText(text: String, newCursorPosition: Int) (TextEditor.kt:38)
    └── inputConnection?.commitText(text, newCursorPosition)
    │
    ▼
Host Application Editor
    └── Character inserted into active input field
```

---

## 4. Current Long-Press Flow

Long-press behavior is implemented **exclusively** on keys created with `hintNumber != null` (Row 1 letter keys when `numberRowEnabled == false`):

```
Physical Touch on Row 1 Key (e.g. 'q')
    │
    ▼
MotionEvent.ACTION_DOWN (KeyboardView.kt:1939)
    ├── isLongPressed = false
    ├── Background / elevation / animation / haptic applied
    └── handler.postDelayed(longPressRunnable, ViewConfiguration.getLongPressTimeout().toLong())
    │
    ▼ (User holds finger past timeout, ~400ms)
longPressRunnable.run() on Main UI Thread (KeyboardView.kt:1931)
    ├── isLongPressed = true
    ├── container.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
    └── controller.onKeyTyped(hintNumber)  // e.g. "1"
    │
    ▼
KeyboardController.onKeyTyped("1")
    └── textEditor.commitText("1", 1) -> inputConnection?.commitText("1", 1)
        (Number is inserted into editor immediately while finger is still held down)
    │
    ▼ (User releases finger)
MotionEvent.ACTION_UP (KeyboardView.kt:1947)
    ├── handler.removeCallbacks(longPressRunnable)
    ├── Visual state restored to shapeNormal
    ├── Check: if (!isLongPressed) { onClick() }
    └── Since isLongPressed == true, onClick() is SKIPPED (letter "q" is NOT typed)
```

---

## 5. Current Number-Alternative Implementation

### Code Location & Key Mechanism

- **Source File**: `app/android/app/src/main/kotlin/com/pk/ai_keyboard/ui/KeyboardView.kt`
- **Lines**: `1712–1725` and `1873–1966`
- **Method**: `renderQwertyLayout()` and `createKeyView()`

```kotlin
// KeyboardView.kt:1712-1724
val useNumbers = ::controller.isInitialized && controller.numberRowRepository.getUseNumbers()

if (useNumbers) {
    val numberRow = listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "0")
    mainPanelContainer.addView(createKeyRow(numberRow))
}

val row1 = listOf("q", "w", "e", "r", "t", "y", "u", "i", "o", "p")
val row1Hints = if (useNumbers) null else listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "0")
...
mainPanelContainer.addView(createKeyRow(row1, hints = row1Hints))
```

```kotlin
// KeyboardView.kt:1930-1935
var isLongPressed = false
val longPressRunnable = Runnable {
    isLongPressed = true
    container.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
    controller.onKeyTyped(hintNumber)
}
```

### Forensic Determination on Mechanism

- **Result**: **A. Directly commits the number after the long-press timeout.**
- Evidence:
  - There is no popup window, view inflation, or dialog.
  - The number character is dispatched directly to `controller.onKeyTyped(hintNumber)` from the timer callback.
  - Finger movement during the hold is ignored because there is no `ACTION_MOVE` handler.

---

## 6. Current Key Model

The repository currently possesses **no object-oriented key model** in the UI layer.

### Current Representation

- **Key Labels**: Plain Kotlin `String` literals stored in ad-hoc `List<String>` collections inside layout rendering functions (`row1`, `row2`, `row3`).
- **Key Codes**: Not modeled. Key identification is performed by string value.
- **Primary Output**: The label string itself.
- **Alternative Characters**: Represented solely by the optional parameter `hintNumber: String? = null` in `createKeyView()`.
- **Multiple Alternatives Supported**: **NO**.
- **Long-Press Metadata**: Restricted to a single optional string.
- **Popup Metadata**: None.

### Extensibility Without Redesign

The UI layer can be extended without redesign by introducing an explicit key definition structure (e.g. `KeyDef` or an AOSP-compatible `Key` data object) that encapsulates:

```kotlin
data class KeyDef(
    val label: String,
    val primaryCode: Int = label.firstOrNull()?.code ?: 0,
    val hintLabel: String? = null,
    val moreKeysSpec: String? = null, // e.g. "1,¹,₁"
    val weight: Float = 1.0f,
    val isSpecial: Boolean = false
)
```

This enables multiple alternatives to be defined per key while preserving the existing layout structure.

---

## 7. Current Touch / Long-Press System

### Audit of `KeyboardView.kt` Touch Handling

| MotionEvent Action | Implemented Behavior | Notes |
| --- | --- | --- |
| `ACTION_DOWN` | Visual pressed state, elevation decrease, press scale animation, tap haptic. For hint keys: schedules `longPressRunnable` via `handler.postDelayed()`. | Only attached to individual key views, not parent container. |
| `ACTION_MOVE` | **UNHANDLED** | No motion tracking. Moving finger off the key does not cancel the long press timer or change the target key. |
| `ACTION_UP` | Cancels `longPressRunnable`. Restores normal visuals. Calls `onClick()` if `!isLongPressed`. | Normal release path. |
| `ACTION_CANCEL` | Cancels `longPressRunnable`. Restores normal visuals. | Window focus loss or gesture abort. |
| `ACTION_POINTER_DOWN / UP` | **UNHANDLED** | No multi-touch tracking or pointer ID routing. |

### Classification

**100% custom Kotlin implementation** using basic Android framework `View.OnTouchListener` and `android.os.Handler`. It does not use `android.inputmethodservice.KeyboardView`, AOSP `PointerTracker`, or Android gesture detectors.

---

## 8. Existing AOSP LatinIME Keyboard Code in Repository

A complete search of the repository for AOSP keyboard UI classes yields the following results:

| AOSP Class | Present in Repo? | Original / Modified | Reachable at Runtime? |
| --- | --- | --- | --- |
| `Keyboard` | **NO** | N/A | N/A |
| `Key` | **NO** (`KeyRect` in `ProximityInfo.kt` is unrelated) | N/A | N/A |
| `KeyDetector` | **NO** | N/A | N/A |
| `PointerTracker` | **NO** | N/A | N/A |
| `MainKeyboardView` | **NO** | N/A | N/A |
| `KeyboardView` | **NO** (Project has custom `ui.KeyboardView : LinearLayout`) | N/A | N/A |
| `MoreKeysKeyboard` | **NO** | N/A | N/A |
| `MoreKeysKeyboardView` | **NO** | N/A | N/A |
| `MoreKeysDetector` | **NO** | N/A | N/A |
| `MoreKeysPanel` | **NO** | N/A | N/A |
| `MoreKeySpec` | **NO** | N/A | N/A |
| `KeySpec` / `KeySpecParser` | **NO** | N/A | N/A |
| `KeyVisualAttributes` | **NO** | N/A | N/A |
| `KeyboardActionListener` | **NO** | N/A | N/A |

### Conclusion

None of the AOSP keyboard rendering, touch tracking, or popup classes are currently in the repository. The only AOSP LatinIME code in this project is the **native dictionary suggestion engine** under `app/android/app/src/main/cpp/` and `app/android/app/src/main/kotlin/com/pk/ai_keyboard/suggestion/aosp/`.

---

## 9. AOSP More-Keys Source Audit

From the canonical AOSP LatinIME source tree (`packages/inputmethods/LatinIME/java/src/com/android/inputmethod/keyboard/`), the More Keys system operates through the following specialized classes:

### 1. `MoreKeysPanel.java` (Interface)

- **Role**: Contract for any popup panel showing alternative keys.
- **Key Methods**:
  - `showMoreKeysPanel(parentView, controller, pointX, pointY, listener)`
  - `dismissMoreKeysPanel()`
  - `onDownEvent(x, y, pointerId, eventTime)`
  - `onMoveEvent(x, y, pointerId, eventTime)`
  - `onUpEvent(x, y, pointerId, eventTime)`
  - `translateX(x)`, `translateY(y)`
- **Dependencies**: None (pure interface).
- **Can integrate independently?**: **YES**.

### 2. `MoreKeysKeyboardView.java` (Class)

- **Role**: Custom view implementing `MoreKeysPanel` that renders virtual keys onto a Canvas and handles touch hit-testing during dragging.
- **Key Methods**:
  - `detectKey(x, y)`: Hit-tests coordinates against `MoreKeysDetector`.
  - `onMoveEvent()`: Updates pressed graphics on the newly hovered key and redraws.
  - `onUpEvent()`: Determines key under release point, calls `onKeyInput()`, and emits text/code via `KeyboardActionListener`.
- **Dependencies**: `KeyboardView`, `MoreKeysKeyboard`, `MoreKeysDetector`, `MoreKeysPanel`.
- **Can integrate independently?**: **YES**, with an adapted base drawing class.

### 3. `MoreKeysKeyboard.java` (Class)

- **Role**: Data model extending `Keyboard`. Computes popup key positions, number of columns, and geometry relative to the parent key.
- **Key Methods**:
  - `MoreKeysKeyboardParams.setParameters(...)`: Computes optimal columns, left/right distribution around parent key center.
  - `Builder`: Populates keys from `MoreKeySpec[]`.
- **Dependencies**: `Keyboard`, `KeyboardParams`, `MoreKeySpec`, `Key`.
- **Can integrate independently?**: **YES**.

### 4. `MoreKeysDetector.java` (Class)

- **Role**: Specialized `KeyDetector` for MoreKeys that adds `slide_allowance` so dragging slightly above or below keys does not prematurely dismiss the popup.
- **Dependencies**: `KeyDetector`, `Keyboard`, `Key`.
- **Can integrate independently?**: **YES**.

### 5. `MoreKeySpec.java` (Class)

- **Role**: Parses comma-delimited strings such as `"1,¹,₁"` into an array of `MoreKeySpec` objects containing `mCode`, `mLabel`, and `mOutputText`.
- **Dependencies**: `KeySpecParser`, `StringUtils`, `Constants`.
- **Can integrate independently?**: **YES**.

---

## 10. Dependency Closure

To bring the AOSP More Keys infrastructure into the project without importing unnecessary LatinIME components (e.g. gesture trails, batch input, dictionary synchronizers), the minimal dependency graph is:

```
                          MoreKeysPanel (Interface)
                                     ▲
                                     │ (implements)
MoreKeysKeyboardView (View) ─────────┴─────────────────────┐
      │                                                     │
      ├──> MoreKeysDetector ──> KeyDetector                 │
      │                                                     │
      ├──> MoreKeysKeyboard ──> Keyboard ──> Key ──> MoreKeySpec
      │                                                     │
      ├──> KeyboardActionListener (Interface) ─────────────┘
      │
      └──> (Drawing Base: KeyDrawParams, KeyVisualAttributes)
```

### Classification of Components

| Component | Status / Recommendation | Rationale |
| --- | --- | --- |
| `MoreKeysPanel` | **MUST IMPORT** | Core interface for popup panel lifecycle. |
| `MoreKeysKeyboardView` | **MUST IMPORT & ADAPT** | Core visual renderer and drag-detector for popup keys. |
| `MoreKeysKeyboard` | **MUST IMPORT** | Accurate multi-column/row key placement and alignment. |
| `MoreKeysDetector` | **MUST IMPORT** | Accurate hit detection with sliding allowance. |
| `KeyDetector` | **MUST IMPORT** | Base hit-detection geometry math. |
| `MoreKeySpec` | **MUST IMPORT** | Spec string parser (`"1,¹,₁"`). |
| `KeySpecParser` | **MUST IMPORT** | Tokenizer for key labels and codes. |
| `Key` | **MUST ADAPT** | Lightweight version holding geometry, code, label, and moreKeys array. |
| `Keyboard` | **MUST ADAPT** | Lightweight version holding keyboard dimensions and key list. |
| `KeyboardActionListener` | **MUST IMPORT** | Listener interface for emitting code/text to `KeyboardController`. |
| `MainKeyboardView` | **MUST NOT IMPORT** | Unnecessary. Existing keyboard UI is preserved. |
| `PointerTracker` | **MUST ADAPT** | Extract long-press timer and drag-routing logic into a focused `MoreKeysTouchHandler`. |
| `BatchInputArbiter` / `GestureEnabler` | **MUST NOT IMPORT** | Unrelated gesture/glide typing code. |

---

## 11. AOSP Touch & Drag Selection Mechanics

The touch-to-selection sequence in AOSP LatinIME proceeds as follows:

```
1. USER TOUCHES KEY:
   MotionEvent.ACTION_DOWN at (x, y)
   └── Start long-press timer (ViewConfiguration.getLongPressTimeout()).

2. LONG-PRESS TIMEOUT EXPIRES:
   PointerTracker.onLongPressed()
   ├── Check key.hasNoPanelAutoMoreKey():
   │   └── If true: directly emit moreKeyCode and abort popup.
   └── If false:
       ├── Instantiate MoreKeysKeyboard(key.getMoreKeys())
       ├── showMoreKeysPanel(parentView, controller, pointX, pointY, listener)
       ├── Compute translated touch coordinates:
       │   translatedX = moreKeysPanel.translateX(x)
       │   translatedY = moreKeysPanel.translateY(y)
       └── moreKeysPanel.onDownEvent(translatedX, translatedY, pointerId, eventTime)
           └── Detect initial hit key under finger.

3. USER DRAGS FINGER:
   MotionEvent.ACTION_MOVE at (x', y')
   └── If panel is showing:
       ├── translatedX' = moreKeysPanel.translateX(x')
       ├── translatedY' = moreKeysPanel.translateY(y')
       └── moreKeysPanel.onMoveEvent(translatedX', translatedY', pointerId, eventTime)
           ├── KeyDetector.detectHitKey(translatedX', translatedY')
           ├── If newKey != currentKey:
           │   ├── Un-highlight old key (updateReleaseKeyGraphics + invalidate)
           │   └── Highlight new key (updatePressKeyGraphics + invalidate)
           └── If finger moves outside allowable bounds:
               └── controller.onCancelMoreKeysPanel() -> dismiss popup.

4. USER LIFTS FINGER:
   MotionEvent.ACTION_UP at (x'', y'')
   └── If panel is showing:
       ├── moreKeysPanel.onUpEvent(translatedX'', translatedY'', pointerId, eventTime)
       │   ├── selectedKey = detectKey(translatedX'', translatedY'')
       │   └── if (selectedKey != null):
       │       └── onKeyInput(selectedKey) -> listener.onCodeInput(code) or onTextInput(text)
       └── dismissMoreKeysPanel()
           └── Panel removed from parent view hierarchy.
```

---

## 12. Single-Alternative vs. Multiple-Alternative Behavior

### Source-Proven Behavior in AOSP LatinIME

In `Key.java:142, 793`:

```java
private static final int MORE_KEYS_FLAGS_NO_PANEL_AUTO_MORE_KEY = 0x10000000;
private static final String MORE_KEYS_NO_PANEL_AUTO_MORE_KEY = "!noPanelAutoMoreKey!";

public final boolean hasNoPanelAutoMoreKey() {
    return (mMoreKeysColumnAndFlags & MORE_KEYS_FLAGS_NO_PANEL_AUTO_MORE_KEY) != 0;
}
```

In `PointerTracker.java:1025`:

```java
if (key.hasNoPanelAutoMoreKey()) {
    cancelKeyTracking();
    final int moreKeyCode = key.getMoreKeys()[0].mCode;
    sListener.onPressKey(moreKeyCode, 0, true);
    sListener.onCodeInput(moreKeyCode, NOT_A_COORDINATE, NOT_A_COORDINATE, false);
    sListener.onReleaseKey(moreKeyCode, false);
    return;
}
```

### Architectural Implications for the Project

1. **Single Alternative (`Q -> 1`)**:
   - When a key's spec includes `!noPanelAutoMoreKey!,1`, AOSP **does not show a popup**. It triggers immediate haptic feedback and emits the key code on long-press timeout.
   - This matches the project's current number-row disabled behavior.
2. **Multiple Alternatives (`Q -> 1, ¹, ₁`)**:
   - Omitting `!noPanelAutoMoreKey!` causes AOSP to open the `MoreKeysKeyboardView` popup.
   - The user drags across `1`, `¹`, `₁` and releases to commit.

---

## 13. Resource Dependency Audit

AOSP's More Keys requires a minimal set of Android resources:

| Resource Type | Resource Identifier | Purpose |
| --- | --- | --- |
| **Layout** | `res/layout/more_keys_keyboard.xml` | Outer container holding `<MoreKeysKeyboardView>`. |
| **Dimension** | `config_more_keys_keyboard_slide_allowance` | Slide tolerance around popup before cancellation (typically `10dp`). |
| **Drawable** | `more_keys_panel_background.xml` | Background bubble / 9-patch for the popup with elevation shadow. |
| **Drawable** | `more_keys_key_background.xml` | StateListDrawable for normal vs pressed state of popup keys. |
| **Colors** | Key text color, highlight color | Synced with `KeyboardTheme.kt` colors. |

Unrelated AOSP themes, styles, and XML assets (such as dictionary line layouts, setup wizard layouts, and full keyboard layouts) must **not** be imported.

---

## 14. Coexistence with Number-Row Setting

### Current State

- Setting stored in `NumberRowRepository` (`getUseNumbers()`).
- Toggled via Flutter UI or settings menu.
- Triggers `KeyboardController.onUseNumbersChanged`, re-rendering the layout in `KeyboardView.renderPanel()`.

### Coexistence Strategy for More Keys

```
                     numberRowEnabled Setting
                               │
            ┌──────────────────┴──────────────────┐
            ▼                                     ▼
      TRUE (Row 0 Visible)              FALSE (Row 0 Hidden)
  ┌─────────────────────────┐       ┌─────────────────────────┐
  │ Number row '1'..'0' has │       │ Row 1 letters ('q'..'p')│
  │ separate keys at top.   │       │ show hint numbers.      │
  │ Letter keys have more-  │       │ Long-press opens:       │
  │ keys without numbers    │       │   '1', '¹', '₁'         │
  │ (or superscripts only). │       │ (or auto-commits '1').  │
  └─────────────────────────┘       └─────────────────────────┘
```

In both configurations, the underlying More Keys system functions identically; only the `moreKeys` specification strings passed to the keys vary based on `numberRowRepository.getUseNumbers()`.

---

## 15. Key Preview vs. More Keys

- **Key Preview**: Transient visual callout displayed immediately upon touch down above a pressed key during normal typing.
- **More Keys**: Interactive popup opened only after long-press timeout holding multiple alternative selectable keys.
- **Audit Finding**: AI Keyboard currently has **no key preview callout** (keys only scale in place via `animatePress`).
- **Conflict Assessment**: **ZERO CONFLICT**. There is no existing key preview view or animation that interferes with popup placement.

---

## 16. InputConnection & Text Commit Integration

AOSP More Keys delivers selection results via `KeyboardActionListener`:

- `onCodeInput(int primaryCode, int x, int y, boolean isKeyRepeat)`
- `onTextInput(CharSequence text)`

### Existing Integration Point in AI Keyboard

In `KeyboardController.kt`:

```kotlin
fun onKeyTyped(char: String) {
    val charToCommit = when (shiftState) {
        ShiftState.SHIFT_ON -> {
            val upper = char.uppercase()
            shiftState = ShiftState.LOWERCASE
            onShiftStateChanged?.invoke(shiftState)
            upper
        }
        ShiftState.CAPS_LOCK -> char.uppercase()
        ShiftState.LOWERCASE -> char
    }
    textEditor.commitText(charToCommit, 1)
    checkForCommandTrigger()
    requestSuggestions()
}
```

### Adapter Implementation

A simple listener adapter implements `KeyboardActionListener` and delegates to `controller.onKeyTyped(...)`:

```kotlin
val listener = object : KeyboardActionListener {
    override fun onCodeInput(primaryCode: Int, x: Int, y: Int, isKeyRepeat: Boolean) {
        val char = Character.toString(primaryCode)
        controller.onKeyTyped(char)
    }
    override fun onTextInput(text: CharSequence?) {
        if (!text.isNullOrEmpty()) {
            controller.onKeyTyped(text.toString())
        }
    }
    // ... no-op stubs for unused callbacks ...
}
```

This requires **zero modifications** to `TextEditor.kt`, `InputConnection`, or the AOSP suggestion engine.

---

## 17. Threading, Lifecycle & Android 16 Compatibility

1. **Threading**: All view updates, touch tracking, timer callbacks, and commits run on the Android Main Looper (UI thread).
2. **Lifecycle Handlers**:
   - `onFinishInputView()` / `onFinishInput()`: Must call `dismissMoreKeysPanel()` to guarantee no lingering popups when the keyboard is hidden.
   - `onDestroy()`: Clear cached popup keyboard models.
3. **Android 16 / API 36 Compatibility**:
   - The AOSP More Keys view hierarchy operates entirely within the IME's application window bounds.
   - It does not require system alert window permissions (`TYPE_APPLICATION_OVERLAY`) or global window tokens.
   - Touch event handling uses standard `MotionEvent` methods supported across API 26 through 36.

---

## 18. License & Attribution

All proposed classes originate from:

- **Project**: Android Open Source Project (AOSP) LatinIME
- **Source Path**: `platform/packages/inputmethods/LatinIME/java/src/com/android/inputmethod/keyboard/`
- **License**: Apache License 2.0
- **Copyright**: Copyright (C) 2010–2014 The Android Open Source Project

### Compliance Action

- Preserve all original AOSP Apache 2.0 license headers at the top of every imported source file.
- Document added components in `NOTICE` in accordance with Section 4(d) of the Apache 2.0 License.

---

## 19. Files to Add, Modify, and Preserve

### Files to Add (Phase 9.2)

1. `app/android/app/src/main/kotlin/com/pk/ai_keyboard/ui/morekeys/MoreKeySpec.kt` (or `.java`)
2. `app/android/app/src/main/kotlin/com/pk/ai_keyboard/ui/morekeys/KeySpecParser.kt`
3. `app/android/app/src/main/kotlin/com/pk/ai_keyboard/ui/morekeys/MoreKeysKeyboard.kt`
4. `app/android/app/src/main/kotlin/com/pk/ai_keyboard/ui/morekeys/MoreKeysKeyboardView.kt`
5. `app/android/app/src/main/kotlin/com/pk/ai_keyboard/ui/morekeys/MoreKeysDetector.kt`
6. `app/android/app/src/main/kotlin/com/pk/ai_keyboard/ui/morekeys/MoreKeysPanel.kt`
7. `app/android/app/src/main/kotlin/com/pk/ai_keyboard/ui/morekeys/KeyboardActionListener.kt`
8. `app/android/app/src/main/kotlin/com/pk/ai_keyboard/ui/morekeys/KeyDef.kt`
9. `app/android/app/src/main/res/layout/more_keys_keyboard.xml`
10. `app/android/app/src/main/res/drawable/more_keys_panel_background.xml`

### Files to Modify (Phase 9.2)

1. `app/android/app/src/main/kotlin/com/pk/ai_keyboard/ui/KeyboardView.kt`:
   - Add overlay container (`FrameLayout`) to host `MoreKeysKeyboardView`.
   - Update key touch listener to forward events to `MoreKeysTouchHandler` / `MoreKeysPanel`.
   - Add dismissal call in `onFinishInputView()` / `updateModeUi()`.
2. `NOTICE`: Add Apache 2.0 attribution for imported AOSP LatinIME keyboard files.

### Files That Must NOT Be Modified

- `app/android/app/src/main/kotlin/com/pk/ai_keyboard/keyboard/KeyboardController.kt` (receives characters via existing `onKeyTyped`)
- `app/android/app/src/main/kotlin/com/pk/ai_keyboard/text/TextEditor.kt`
- `app/android/app/src/main/kotlin/com/pk/ai_keyboard/suggestion/aosp/*` (suggestion engine remains untouched)
- `app/android/app/src/main/cpp/*` (native C++ trie dictionary remains untouched)
- `app/android/app/src/main/kotlin/com/pk/ai_keyboard/voice/*` (dictation remains untouched)
- `app/android/app/src/main/kotlin/com/pk/ai_keyboard/ai/*` (AI providers remain untouched)

---

## 20. Target Integration Architecture Diagram

```
┌────────────────────────────────────────────────────────────────────────┐
│                        KeyboardView (Root View)                        │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                    Toolbar (Suggestions / AI)                    │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                     Main Panel (Key Rows)                        │  │
│  │                                                                  │  │
│  │   [ Q ]   [ W ]   [ E ]   [ R ]   [ T ]   [ Y ]   ...            │  │
│  │     │                                                            │  │
│  │     │ (Long Press on 'Q')                                        │  │
│  │     ▼                                                            │  │
│  │  ┌────────────────────────────────────────────────────────────┐  │  │
│  │  │ Overlay Container (FrameLayout inside KeyboardView)        │  │  │
│  │  │                                                            │  │  │
│  │  │   ┌───┬───┬───┐    <-- MoreKeysKeyboardView               │  │  │
│  │  │   │ 1 │ ¹ │ ₁ │        (renders MoreKeysKeyboard)         │  │  │
│  │  │   └───┴───┴───┘        (drag hit-tested by MoreKeysDet.)  │  │  │
│  │  └────────────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    │ (Selected Char: "¹")
                                    ▼
                 KeyboardActionListenerAdapter.onCodeInput()
                                    │
                                    ▼
                     KeyboardController.onKeyTyped("¹")
                                    │
                                    ▼
                        TextEditor.commitText("¹", 1)
                                    │
                                    ▼
                         InputConnection.commitText
```

---

## 21. Implementation Plan for Phase 9.2

The implementation in Phase 9.2 should proceed in nine strict, incremental stages:

### PHASE 9.2.1 — AOSP Source Import

- Import `MoreKeysPanel.java`, `MoreKeySpec.java`, `KeySpecParser.java`, and `KeyboardActionListener.java` into package `com.pk.ai_keyboard.ui.morekeys`.
- Adapt package declarations and imports to point to `com.pk.ai_keyboard`.
- Compile and verify that the imported base interfaces build cleanly.

### PHASE 9.2.2 — Resource Integration

- Create `res/layout/more_keys_keyboard.xml` containing `<com.pk.ai_keyboard.ui.morekeys.MoreKeysKeyboardView>`.
- Create `res/drawable/more_keys_panel_background.xml` with popup elevation styling.
- Define `config_more_keys_keyboard_slide_allowance` in `res/values/dimens.xml`.

### PHASE 9.2.3 — Key & Keyboard Model Adaptation

- Implement lightweight AOSP-compatible `Key` and `Keyboard` classes to support `MoreKeysKeyboard`.
- Import `MoreKeysKeyboard.java` and `MoreKeysDetector.java`.
- Verify mathematical layout calculation of popup columns and coordinates.

### PHASE 9.2.4 — More Keys Popup View Integration

- Import and adapt `MoreKeysKeyboardView.java` with canvas drawing methods for key backgrounds and labels.
- Add an overlay `FrameLayout` inside `KeyboardView.kt` above `mainPanelContainer`.
- Wire `showMoreKeysPanel` to attach and locate the popup above the target key.

### PHASE 9.2.5 — Drag-Selection Integration

- Update key touch listener in `KeyboardView.kt` to handle `MotionEvent.ACTION_MOVE` and `MotionEvent.ACTION_UP`.
- When popup is active, forward motion events to `moreKeysPanel.onMoveEvent()` and `moreKeysPanel.onUpEvent()`.
- Verify real-time highlight switching as the user drags across alternatives.

### PHASE 9.2.6 — Single-Number Behavior Preservation

- Wire the `!noPanelAutoMoreKey!` flag support in `MoreKeySpec` and `Key`.
- Verify that when a key has a single alternative configured with auto-commit, it directly commits without opening a popup, preserving current `Q -> 1` behavior.

### PHASE 9.2.7 — Multiple-Alternative Support

- Define multiple alternatives for letter keys:
  - `q -> 1, ¹, ₁`
  - `e -> 3, €, é, è, ê, ë`
  - `a -> @, á, à, â, ä, ã, å`
  - etc.
- Verify that dragging between multiple alternatives correctly selects and highlights each option.

### PHASE 9.2.8 — InputConnection Integration

- Implement `KeyboardActionListener` bridge to route `onCodeInput` and `onTextInput` to `KeyboardController.onKeyTyped()`.
- Verify text insertion in active input connection.

### PHASE 9.2.9 — Testing & Verification

- Unit test candidate parsing in `MoreKeySpecTest`.
- Unit test layout math in `MoreKeysKeyboardTest`.
- Manual verification on real device (`CPH2491`, Android 16 / API 36):
  - Long-press and drag selection.
  - Quick single-press preservation.
  - Number row toggling (enabled vs disabled).
  - Rapid touches and edge dismissal.

---

## 22. Risks and Unresolved Questions

1. **Popup Window vs. In-View Overlay**:
   - In AOSP, `MoreKeysKeyboardView` is added to a top-level `DrawingPreviewPlacerView` inside the IME window.
   - An in-view overlay `FrameLayout` within `KeyboardView` is simpler and avoids window manager token issues, but must ensure it does not get clipped if a key on Row 1 expands above the keyboard bounds. If clipping occurs, `clipChildren = false` and `clipToPadding = false` on `KeyboardView`, or using an anchored `PopupWindow`, will be evaluated.
2. **Theme Synchronization**:
   - `MoreKeysKeyboardView` canvas drawing must read colors from `KeyboardTheme.current(context)` so the popup matches the active keyboard theme (dark/light/custom).

---

## 23. Audit Conclusion

**AUDIT COMPLETE — PHASE 9.2 IMPLEMENTED**

---

## 24. Phase 9.2 Implementation Details

### Implemented AOSP Classes (`com.pk.ai_keyboard.ui.aosp.morekeys`)

1. **`MoreKeysPanel.java`**:
   - Original Apache-2.0 AOSP interface defining the contract for More Keys popup panels (`showMoreKeysPanel`, `dismissMoreKeysPanel`, `onDownEvent`, `onMoveEvent`, `onUpEvent`, `translateX`, `translateY`).
   - Includes `Controller` interface for showing/dismissing the panel.

2. **`KeyboardActionListener.java`**:
   - Original Apache-2.0 AOSP interface for delivering key codes (`onCodeInput`) and text strings (`onTextInput`) from the popup to the application controller.

3. **`MoreKeySpec.kt`**:
   - Encapsulates alternative key specifications parsed from comma-delimited strings (e.g. `"1,¹,₁"`).
   - Supports `!noPanelAutoMoreKey!` flag for single-alternative auto-commit on long-press timeout.
   - Robustly handles escaped commas (`\,`), escaped backslashes (`\\`), and pipe characters (`|`).

4. **`AospKey.kt` & `AospKeyboard.kt`**:
   - Lightweight, standalone representations of keys and keyboards for popup layout and hit testing without coupling to full AOSP XML inflation.

5. **`MoreKeysKeyboard.kt`**:
   - Adapted from AOSP `MoreKeysKeyboard.java`.
   - Computes multi-column/multi-row layouts, centering popup over parent key center, and clamping to screen left/right boundaries.

6. **`MoreKeysDetector.kt`**:
   - Adapted from AOSP `MoreKeysDetector.java`.
   - Provides sliding hit-detection with configurable slide allowance margin.

7. **`MoreKeysKeyboardView.kt`**:
   - Adapted from AOSP `MoreKeysKeyboardView.java`.
   - Canvas-based view that renders the popup bubble, key backgrounds, labels, real-time drag highlighting, and release-to-commit selection.

### Key Model Decoupling (`com.pk.ai_keyboard.ui.KeyDef.kt`)

- Decouples primary key `label`, visible top-right `hint`, and long-press `moreKeysSpec`.
- Enabled the **Comma key** `,` to provide 34 commonly used special characters and currency symbols on long press with **NO visible hint** on the key.

### UI Integration (`com.pk.ai_keyboard.ui.KeyboardView.kt`)

- Added `contentWrapper: FrameLayout` with `clipChildren = false` and `clipToPadding = false`.
- Added `moreKeysOverlayContainer: FrameLayout` to host `MoreKeysKeyboardView`.
- Preserved single-alternative auto-commit for `W`..`P` when number row is disabled.
- Supported multi-alternative popup and drag selection for `Q` (`1,¹,₁`) and `,` (34 special characters).

---

## 25. Test and Validation Results

1. **Unit Tests**:
   - `MoreKeySpecTest`: 5 unit tests verifying single alternatives, multiple alternatives, auto-commit flags, escapes, and full 34-character comma set.
   - `MoreKeysKeyboardTest`: 4 unit tests verifying single-row layout, multi-row layout, and left/right boundary clamping.
   - Execution: `./gradlew testDebugUnitTest` -> **BUILD SUCCESSFUL** (all 55 tests passed).

2. **Android Debug Compilation**:
   - Execution: `./gradlew assembleDebug` -> **BUILD SUCCESSFUL**.
   - Output APK: `app/build/app/outputs/apk/debug/app-debug.apk`.

3. **Behavior Verification**:
   - Normal tap: completely unchanged.
   - Single alternative (number row disabled): `W`..`P` auto-commit number directly on long-press timeout.
   - Multi-alternative (`Q`): opens popup containing `1`, `¹`, `₁`, allows dragging, highlights active key, commits on finger release.
   - Comma key: normal tap produces `,`; long press opens 5x8 grid of 34 special characters; no visible hint on the comma key.

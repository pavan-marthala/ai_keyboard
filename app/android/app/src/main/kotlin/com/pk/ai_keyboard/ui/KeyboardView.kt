package com.pk.ai_keyboard.ui

import android.annotation.SuppressLint
import android.content.Context
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.Drawable
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.util.AttributeSet
import android.util.TypedValue
import android.view.Gravity
import android.view.HapticFeedbackConstants
import android.view.MotionEvent
import android.view.View
import android.view.animation.Animation
import android.view.animation.DecelerateInterpolator
import android.view.animation.LinearInterpolator
import android.view.animation.RotateAnimation
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.*
import androidx.core.content.ContextCompat
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import com.pk.ai_keyboard.R
import com.pk.ai_keyboard.command.NativeCommandRegistry
import com.pk.ai_keyboard.keyboard.KeyboardController
import com.pk.ai_keyboard.keyboard.ShiftState
import com.pk.ai_keyboard.suggestion.SuggestionResult
import com.pk.ai_keyboard.ui.theme.KeyboardTheme
import com.pk.ai_keyboard.voice.VoiceState

@SuppressLint("ClickableViewAccessibility")
class KeyboardView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : LinearLayout(context, attrs, defStyleAttr) {

    private lateinit var controller: KeyboardController
    private var theme = KeyboardTheme.current(context)
    private var editorInfo: EditorInfo? = null

    private var isSymbolPanel = false

    private lateinit var toolbarContainer: LinearLayout
    private lateinit var mainPanelContainer: LinearLayout

    // Normal Toolbar Views
    private lateinit var appIconView: ImageView
    private lateinit var toolbarScrollView: HorizontalScrollView
    private lateinit var micButtonView: ImageView
    private lateinit var menuButtonView: ImageView

    // Dictation Toolbar Views
    private lateinit var backArrowView: ImageView
    private lateinit var dictationStatusTextView: TextView
    private lateinit var dictationStateIconView: ImageView

    private val letterKeyViews = mutableListOf<TextView>()
    private var shiftIconView: ImageView? = null
    private var enterIconView: ImageView? = null

    private val handler = Handler(Looper.getMainLooper())
    private var backspaceRunnable: Runnable? = null
    private var rotateAnimation: RotateAnimation? = null

    /** Suggestion chips (word candidates) are visually neutral — they're options to pick,
     *  not actions to trigger. AI command chips (@fix, @rewrite, ...) get the accent
     *  gradient treatment since they *are* actions. Mixing the two styles makes every
     *  suggestion look like a demanding CTA, which is noisy during normal typing. */
    private enum class ChipStyle { SUGGESTION, COMMAND }

    companion object {
        private const val KEY_CORNER_RADIUS_DP = 14f
        private const val KEY_ELEVATION_DP = 1.5f
        private const val PRESS_SCALE = 0.93f
        private const val PRESS_ANIM_MS = 70L
        private const val RELEASE_ANIM_MS = 120L
        private const val ICON_SIZE_DP = 22f

        // Toolbar icon buttons (mic, menu, back, dictation state, app icon) all share
        // this exact icon size and the same circular ghost-press touch target, so
        // nothing in the toolbar reads as bigger/smaller/off-center than its neighbor.
        private const val TOOLBAR_ICON_SIZE_DP = 22f
        private const val TOOLBAR_TOUCH_TARGET_DP = 38f
    }

    init {
        orientation = VERTICAL
        setBackgroundColor(theme.backgroundColor)
        setupInsetsListener()
        buildUi()
    }

    private fun setupInsetsListener() {
        ViewCompat.setOnApplyWindowInsetsListener(this) { view, insets ->
            val sysBars = insets.getInsets(
                WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.navigationBars()
            )
            val bottomInset = sysBars.bottom
            view.setPadding(view.paddingLeft, view.paddingTop, view.paddingRight, bottomInset)
            insets
        }
    }

    fun init(keyboardController: KeyboardController) {
        this.controller = keyboardController
        controller.onShiftStateChanged = { shiftState ->
            updateShiftUi(shiftState)
        }
        controller.onAiDisabledStateChanged = { _ ->
            refreshToolbar()
        }
        controller.onSuggestionsUpdated = { result ->
            renderSuggestions(result)
        }
        controller.onAiCommandModeToggled = { _ ->
            refreshToolbar()
        }
        controller.voiceInputController.onStateChanged = { voiceState ->
            updateDictationToolbar(voiceState)
        }
        refreshToolbar()
    }

    fun updateEditorInfo(info: EditorInfo?) {
        this.editorInfo = info
        updateEnterKeyLabel()
        refreshToolbar()
    }

    private fun dpToPx(dp: Float): Int {
        return TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, dp, resources.displayMetrics).toInt()
    }

    private fun getKeyHeightDp(): Float {
        val isLandscape = resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
        return if (isLandscape) 36f else 46f
    }

    private fun animatePress(view: View) {
        view.animate().scaleX(PRESS_SCALE).scaleY(PRESS_SCALE).setDuration(PRESS_ANIM_MS).start()
    }

    private fun animateRelease(view: View) {
        view.animate().scaleX(1f).scaleY(1f).setDuration(RELEASE_ANIM_MS)
            .setInterpolator(DecelerateInterpolator()).start()
    }

    private fun buildKeyShape(fillColor: Int, isAccent: Boolean): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = dpToPx(KEY_CORNER_RADIUS_DP).toFloat()
            if (isAccent) {
                colors = intArrayOf(theme.accentColorAlt, theme.accentColor)
                orientation = GradientDrawable.Orientation.TL_BR
            } else {
                setColor(fillColor)
                if (theme.keyStrokeColor != 0x00000000) {
                    setStroke(dpToPx(0.75f), theme.keyStrokeColor)
                }
            }
        }
    }

    // ---------------------------------------------------------------------
    // Toolbar
    // ---------------------------------------------------------------------

    private fun buildUi() {
        removeAllViews()

        // Single horizontal toolbar container
        val toolbarRoot = LinearLayout(context).apply {
            orientation = HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setBackgroundColor(theme.toolbarColor)
            setPadding(dpToPx(8f), dpToPx(6f), dpToPx(8f), dpToPx(6f))
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        }

        // --- NORMAL TOOLBAR VIEWS ---
        // 1. App Icon (brand mark — gets touch feedback, but never tinted)
        appIconView = createAppIconView {
            if (::controller.isInitialized) {
                controller.handleAppIconTap()
            }
        }
        toolbarRoot.addView(appIconView)

        // 2. Suggestion / Dynamic Content Area (center, flexible width)
        toolbarScrollView = HorizontalScrollView(context).apply {
            layoutParams = LayoutParams(0, LayoutParams.WRAP_CONTENT, 1.0f).apply {
                gravity = Gravity.CENTER_VERTICAL
            }
            isHorizontalScrollBarEnabled = false
            overScrollMode = View.OVER_SCROLL_NEVER
            setPadding(dpToPx(4f), 0, dpToPx(4f), 0)
        }

        toolbarContainer = LinearLayout(context).apply {
            orientation = HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        toolbarScrollView.addView(toolbarContainer)
        toolbarRoot.addView(toolbarScrollView)

        // 3. Microphone Button
        micButtonView = createToolbarIconButton(
            drawableRes = R.drawable.ic_mic,
            contentDescription = "Voice Input"
        ) {
            if (::controller.isInitialized) {
                controller.handleMicTap()
            }
        }
        toolbarRoot.addView(micButtonView)

        // 4. Menu Button (rightmost 3-dot)
        menuButtonView = createToolbarIconButton(
            drawableRes = R.drawable.ic_more_vert,
            contentDescription = "Menu Options"
        ) {
            if (::controller.isInitialized) {
                controller.handleMenuTap()
            }
        }
        toolbarRoot.addView(menuButtonView)

        // --- DICTATION TOOLBAR VIEWS ---
        // 5. Back Arrow [ ← ] (leftmost exit control)
        backArrowView = createToolbarIconButton(
            drawableRes = R.drawable.ic_arrow_back,
            contentDescription = "Exit Dictation Mode"
        ) {
            if (::controller.isInitialized) {
                controller.handleBackFromDictation()
            }
        }.apply {
            visibility = View.GONE
        }
        toolbarRoot.addView(backArrowView)

        // 6. Dictation Status Text (center message)
        dictationStatusTextView = TextView(context).apply {
            setTextColor(theme.textColor)
            setTypeface(null, Typeface.BOLD)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13.5f)
            gravity = Gravity.CENTER
            setPadding(dpToPx(8f), 0, dpToPx(8f), 0)
            layoutParams = LayoutParams(0, LayoutParams.WRAP_CONTENT, 1.0f).apply {
                gravity = Gravity.CENTER_VERTICAL
            }
            visibility = View.GONE
        }
        toolbarRoot.addView(dictationStatusTextView)

        // 7. Dictation State Icon (rightmost state indicator / mic toggle)
        dictationStateIconView = createToolbarIconButton(
            drawableRes = R.drawable.ic_mic,
            contentDescription = "Dictation State"
        ) {
            if (::controller.isInitialized) {
                if (controller.voiceInputController.currentState == VoiceState.MIC_STOPPED || controller.voiceInputController.currentState == VoiceState.ERROR) {
                    controller.voiceInputController.restartDictationFromStopped()
                } else if (controller.voiceInputController.currentState == VoiceState.LISTENING || controller.voiceInputController.currentState == VoiceState.SPEAK_NOW) {
                    controller.voiceInputController.stopMicrophoneKeepDictation()
                }
            }
        }.apply {
            visibility = View.GONE
        }
        toolbarRoot.addView(dictationStateIconView)

        addView(toolbarRoot)

        val divider = View(context).apply {
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, dpToPx(1f))
            setBackgroundColor(theme.dividerColor)
        }
        addView(divider)

        mainPanelContainer = LinearLayout(context).apply {
            orientation = VERTICAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
            setPadding(dpToPx(4f), dpToPx(6f), dpToPx(4f), dpToPx(6f))
        }
        addView(mainPanelContainer)

        renderPanel()
    }

    private fun updateDictationToolbar(voiceState: VoiceState) {
        if (!::controller.isInitialized) return
        val isDictationActive = controller.voiceInputController.isDictationModeActive

        if (isDictationActive) {
            appIconView.visibility = View.GONE
            toolbarScrollView.visibility = View.GONE
            micButtonView.visibility = View.GONE
            menuButtonView.visibility = View.GONE

            backArrowView.visibility = View.VISIBLE
            dictationStatusTextView.visibility = View.VISIBLE
            dictationStateIconView.visibility = View.VISIBLE

            when (voiceState) {
                VoiceState.LOADING -> {
                    setDictationStatus("Starting…", accent = false)
                    setDictationIcon(R.drawable.ic_sync, theme.textColor, isRotating = true)
                }
                VoiceState.LISTENING -> {
                    setDictationStatus("Listening…", accent = true)
                    setDictationIcon(R.drawable.ic_mic_active, theme.accentColor, isRotating = false)
                }
                VoiceState.SPEAK_NOW -> {
                    setDictationStatus("Speak now", accent = true)
                    setDictationIcon(R.drawable.ic_mic_active, theme.accentColor, isRotating = false)
                }
                VoiceState.PROCESSING -> {
                    setDictationStatus("Processing…", accent = false)
                    setDictationIcon(R.drawable.ic_sync, theme.textColor, isRotating = true)
                }
                VoiceState.MIC_STOPPED -> {
                    setDictationStatus("Tap mic to dictate", accent = false)
                    setDictationIcon(R.drawable.ic_mic, theme.textColor, isRotating = false)
                }
                VoiceState.ERROR -> {
                    setDictationStatus("Voice error", accent = false, isError = true)
                    setDictationIcon(R.drawable.ic_mic, theme.textColor, isRotating = false)
                }
                VoiceState.IDLE -> {
                    setDictationStatus("Tap mic to dictate", accent = false)
                    setDictationIcon(R.drawable.ic_mic, theme.textColor, isRotating = false)
                }
            }
        } else {
            stopRotationAnimation()
            backArrowView.visibility = View.GONE
            dictationStatusTextView.visibility = View.GONE
            dictationStateIconView.visibility = View.GONE

            appIconView.visibility = View.VISIBLE
            toolbarScrollView.visibility = View.VISIBLE
            micButtonView.visibility = View.VISIBLE
            menuButtonView.visibility = View.VISIBLE

            refreshToolbar()
        }
    }

    private fun setDictationStatus(text: String, accent: Boolean, isError: Boolean = false) {
        dictationStatusTextView.text = text
        dictationStatusTextView.setTextColor(
            when {
                isError -> Color.parseColor("#F38BA8")
                accent -> theme.accentColor
                else -> theme.textColor
            }
        )
    }

    private fun setDictationIcon(drawableRes: Int, tintColor: Int, isRotating: Boolean) {
        val drawable = ContextCompat.getDrawable(context, drawableRes)?.mutate()?.apply {
            setTint(tintColor)
        }
        dictationStateIconView.setImageDrawable(drawable)

        if (isRotating) {
            startRotationAnimation()
        } else {
            stopRotationAnimation()
        }
    }

    private fun startRotationAnimation() {
        if (rotateAnimation == null) {
            rotateAnimation = RotateAnimation(
                0f, 360f,
                Animation.RELATIVE_TO_SELF, 0.5f,
                Animation.RELATIVE_TO_SELF, 0.5f
            ).apply {
                duration = 1000L
                repeatCount = Animation.INFINITE
                interpolator = LinearInterpolator()
            }
        }
        dictationStateIconView.startAnimation(rotateAnimation)
    }

    private fun stopRotationAnimation() {
        dictationStateIconView.clearAnimation()
    }

    /** Circular ghost-press background shared by every toolbar icon button, so mic,
     *  menu, back-arrow, dictation-state and the app icon all give identical tap
     *  feedback instead of each behaving/looking slightly different. */
    private fun buildToolbarGhostShape(fillColor: Int): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(fillColor)
        }
    }

    private fun createAppIconView(onClick: () -> Unit): ImageView {
        val touchTargetPx = dpToPx(TOOLBAR_TOUCH_TARGET_DP)
        val shapeNormal = buildToolbarGhostShape(Color.TRANSPARENT)
        val shapePressed = buildToolbarGhostShape(theme.keyPressedColor)

        return ImageView(context).apply {
            setImageResource(R.mipmap.ic_launcher)
            // Never tint the launcher icon — it's full-color brand art, not a
            // monochrome glyph like the rest of the toolbar.
            scaleType = ImageView.ScaleType.FIT_CENTER
            contentDescription = "App Icon Mode Toggle"
            isClickable = true
            isFocusable = true
            background = shapeNormal
            clipToOutline = true
            setPadding(dpToPx(4f), dpToPx(4f), dpToPx(4f), dpToPx(4f))
            layoutParams = LayoutParams(touchTargetPx, touchTargetPx).apply {
                setMargins(dpToPx(2f), 0, dpToPx(4f), 0)
                gravity = Gravity.CENTER_VERTICAL
            }
            setOnTouchListener { v, event ->
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        v.background = shapePressed
                        animatePress(v)
                        v.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                    }
                    MotionEvent.ACTION_UP -> {
                        v.background = shapeNormal
                        animateRelease(v)
                        onClick()
                        v.performClick()
                    }
                    MotionEvent.ACTION_CANCEL -> {
                        v.background = shapeNormal
                        animateRelease(v)
                    }
                }
                true
            }
        }
    }

    private fun createToolbarIconButton(
        drawableRes: Int,
        contentDescription: String,
        onClick: () -> Unit
    ): ImageView {
        val touchTargetPx = dpToPx(TOOLBAR_TOUCH_TARGET_DP)
        val iconPaddingPx = (touchTargetPx - dpToPx(TOOLBAR_ICON_SIZE_DP)) / 2

        val shapeNormal = buildToolbarGhostShape(Color.TRANSPARENT)
        val shapePressed = buildToolbarGhostShape(theme.keyPressedColor)

        return ImageView(context).apply {
            setImageDrawable(ContextCompat.getDrawable(context, drawableRes)?.mutate()?.apply {
                setTint(theme.textColor)
            })
            scaleType = ImageView.ScaleType.FIT_CENTER
            this.contentDescription = contentDescription
            background = shapeNormal
            setPadding(iconPaddingPx, iconPaddingPx, iconPaddingPx, iconPaddingPx)
            isClickable = true
            isFocusable = true
            layoutParams = LayoutParams(touchTargetPx, touchTargetPx).apply {
                setMargins(dpToPx(2f), 0, dpToPx(2f), 0)
                gravity = Gravity.CENTER_VERTICAL
            }
            setOnTouchListener { v, event ->
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        v.background = shapePressed
                        animatePress(v)
                        v.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                    }
                    MotionEvent.ACTION_UP -> {
                        v.background = shapeNormal
                        animateRelease(v)
                        onClick()
                        v.performClick()
                    }
                    MotionEvent.ACTION_CANCEL -> {
                        v.background = shapeNormal
                        animateRelease(v)
                    }
                }
                true
            }
        }
    }

    fun refreshToolbar() {
        if (!::toolbarContainer.isInitialized || !::controller.isInitialized) return
        if (controller.voiceInputController.isDictationModeActive) return

        if (controller.isAiCommandModeActive) {
            renderAiCommands()
        } else {
            controller.requestSuggestions()
        }
    }

    private fun renderAiCommands() {
        if (!::toolbarContainer.isInitialized) return

        toolbarContainer.removeAllViews()

        val commands = listOf(
            "@fix" to "✓ Fix",
            "@rewrite" to "↻ Rewrite",
            "@pro" to "Pro",
            "@casual" to "Casual",
            "@short" to "Short",
            "@expand" to "Expand",
            "@translate" to "🌐 Translate"
        )

        for ((trigger, label) in commands) {
            if (NativeCommandRegistry.isCommandEnabled(context, trigger)) {
                val chip = createChipView(label, ChipStyle.COMMAND) {
                    if (controller.isTransforming) return@createChipView
                    if (trigger == "@translate") {
                        showLanguageSelectorPopup()
                    } else {
                        controller.onCommandButtonClicked(trigger)
                    }
                }
                toolbarContainer.addView(chip)
            }
        }
    }

    private fun renderSuggestions(result: SuggestionResult) {
        if (!::toolbarContainer.isInitialized || !::controller.isInitialized) return
        if (controller.isAiCommandModeActive || controller.voiceInputController.isDictationModeActive) return

        toolbarContainer.removeAllViews()

        for (candidate in result.candidates) {
            val label = if (candidate.isAutoCorrection) "${candidate.text} ✓" else candidate.text
            val chip = createChipView(label, ChipStyle.SUGGESTION, isEmphasized = candidate.isAutoCorrection) {
                controller.onSuggestionCandidateClicked(candidate)
            }
            toolbarContainer.addView(chip)
        }
    }

    private fun createChipView(
        label: String,
        style: ChipStyle,
        isEmphasized: Boolean = false,
        onClick: () -> Unit
    ): TextView {
        val shapeNormal: GradientDrawable
        val shapePressed: GradientDrawable
        val textColor: Int
        val elevationDp: Float
        val typeface: Int

        when (style) {
            ChipStyle.COMMAND -> {
                shapeNormal = GradientDrawable().apply {
                    shape = GradientDrawable.RECTANGLE
                    cornerRadius = dpToPx(18f).toFloat()
                    colors = intArrayOf(theme.accentColorAlt, theme.accentColor)
                    orientation = GradientDrawable.Orientation.TL_BR
                }
                shapePressed = GradientDrawable().apply {
                    shape = GradientDrawable.RECTANGLE
                    cornerRadius = dpToPx(18f).toFloat()
                    setColor(theme.accentColor)
                }
                textColor = theme.chipTextColor
                elevationDp = 1f
                typeface = Typeface.BOLD
            }
            ChipStyle.SUGGESTION -> {
                // Neutral pill — same key-card language as the rest of the keyboard
                // (flat fill + hairline stroke), not a purple CTA. The one emphasized
                // candidate (the auto-correction) gets an accent-colored stroke + text
                // instead of a full accent fill, so it stands out without shouting.
                shapeNormal = GradientDrawable().apply {
                    shape = GradientDrawable.RECTANGLE
                    cornerRadius = dpToPx(16f).toFloat()
                    setColor(theme.keyColor)
                    setStroke(dpToPx(1f), if (isEmphasized) theme.accentColor else theme.dividerColor)
                }
                shapePressed = GradientDrawable().apply {
                    shape = GradientDrawable.RECTANGLE
                    cornerRadius = dpToPx(16f).toFloat()
                    setColor(theme.keyPressedColor)
                    setStroke(dpToPx(1f), if (isEmphasized) theme.accentColor else theme.dividerColor)
                }
                textColor = if (isEmphasized) theme.accentColor else theme.textColor
                elevationDp = 0.5f
                typeface = if (isEmphasized) Typeface.BOLD else Typeface.NORMAL
            }
        }

        return TextView(context).apply {
            text = label
            setTextColor(textColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12.5f)
            setTypeface(null, typeface)
            background = shapeNormal
            elevation = dpToPx(elevationDp).toFloat()
            gravity = Gravity.CENTER
            setPadding(dpToPx(14f), dpToPx(6f), dpToPx(14f), dpToPx(6f))
            layoutParams = LayoutParams(
                LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(dpToPx(4f), 0, dpToPx(4f), 0)
                gravity = Gravity.CENTER_VERTICAL
            }
            setOnTouchListener { v, event ->
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        v.background = shapePressed
                        animatePress(v)
                    }
                    MotionEvent.ACTION_UP -> {
                        v.background = shapeNormal
                        animateRelease(v)
                        v.performClick()
                    }
                    MotionEvent.ACTION_CANCEL -> {
                        v.background = shapeNormal
                        animateRelease(v)
                    }
                }
                true
            }
            setOnClickListener { onClick() }
        }
    }

    private fun showLanguageSelectorPopup() {
        val popupView = LinearLayout(context).apply {
            orientation = VERTICAL
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dpToPx(16f).toFloat()
                setColor(theme.toolbarColor)
            }
            elevation = dpToPx(8f).toFloat()
            setPadding(dpToPx(14f), dpToPx(14f), dpToPx(14f), dpToPx(14f))
        }

        val title = TextView(context).apply {
            text = "Select Target Language"
            setTextColor(theme.textColor)
            setTypeface(null, Typeface.BOLD)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            setPadding(dpToPx(2f), 0, 0, dpToPx(10f))
        }
        popupView.addView(title)

        val grid = GridLayout(context).apply {
            columnCount = 2
        }

        val popupWindow = PopupWindow(
            popupView,
            LayoutParams.WRAP_CONTENT,
            LayoutParams.WRAP_CONTENT,
            true
        )

        for ((code, name) in NativeCommandRegistry.supportedLanguages) {
            val btn = Button(context).apply {
                text = name
                isAllCaps = false
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 12.5f)
                setTextColor(theme.textColor)
                background = GradientDrawable().apply {
                    shape = GradientDrawable.RECTANGLE
                    cornerRadius = dpToPx(10f).toFloat()
                    setColor(theme.keyColor)
                }
                (layoutParams as? GridLayout.LayoutParams)?.setMargins(dpToPx(4f), dpToPx(4f), dpToPx(4f), dpToPx(4f))
                setOnClickListener {
                    popupWindow.dismiss()
                    controller.onTranslateLanguageSelected(code)
                }
            }
            grid.addView(btn)
        }

        popupView.addView(grid)
        popupWindow.elevation = dpToPx(8f).toFloat()
        popupWindow.showAtLocation(this, Gravity.CENTER, 0, 0)
    }

    // ---------------------------------------------------------------------
    // Main key panel (unchanged from before — letters, symbols, bottom row)
    // ---------------------------------------------------------------------

    private fun renderPanel() {
        mainPanelContainer.removeAllViews()
        letterKeyViews.clear()

        if (isSymbolPanel) {
            renderSymbolLayout()
        } else {
            renderQwertyLayout()
        }
    }

    private fun renderQwertyLayout() {
        val row1 = listOf("q", "w", "e", "r", "t", "y", "u", "i", "o", "p")
        val row2 = listOf("a", "s", "d", "f", "g", "h", "j", "k", "l")
        val row3 = listOf("z", "x", "c", "v", "b", "n", "m")

        mainPanelContainer.addView(createKeyRow(row1))
        mainPanelContainer.addView(createKeyRow(row2, paddingHorizontalDp = 12f))

        val row3Layout = LinearLayout(context).apply {
            orientation = HORIZONTAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        }

        val shiftKey = createIconKeyView(
            iconRes = R.drawable.ic_shift,
            weight = 1.4f,
            contentDescription = "Shift"
        ) {
            controller.onShiftPressed()
        }
        shiftIconView = shiftKey.getTag(R.id.tag_icon_view) as? ImageView
        row3Layout.addView(shiftKey)

        for (char in row3) {
            val key = createKeyView(char, weight = 1.0f) {
                controller.onKeyTyped(char)
            }
            letterKeyViews.add(key)
            row3Layout.addView(key)
        }

        val backspaceKey = createIconKeyView(
            iconRes = R.drawable.ic_backspace,
            weight = 1.4f,
            contentDescription = "Delete"
        ) {
            // no-op
        }
        setupBackspaceRepeat(backspaceKey)
        row3Layout.addView(backspaceKey)

        mainPanelContainer.addView(row3Layout)
        renderBottomRow()
        if (::controller.isInitialized) {
            updateShiftUi(controller.shiftState)
        }
    }

    private fun renderSymbolLayout() {
        val row1 = listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "0")
        val row2 = listOf("@", "#", "$", "%", "&", "*", "(", ")", "-", "+")
        val row3 = listOf("_", "\"", "'", ":", ";", "!", "?", "/", ".")

        mainPanelContainer.addView(createKeyRow(row1))
        mainPanelContainer.addView(createKeyRow(row2))

        val row3Layout = LinearLayout(context).apply {
            orientation = HORIZONTAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        }

        for (char in row3) {
            row3Layout.addView(createKeyView(char, weight = 1.0f) {
                controller.onKeyTyped(char)
            })
        }

        val backspaceKey = createIconKeyView(
            iconRes = R.drawable.ic_backspace,
            weight = 1.4f,
            contentDescription = "Delete"
        ) {
            // no-op
        }
        setupBackspaceRepeat(backspaceKey)
        row3Layout.addView(backspaceKey)

        mainPanelContainer.addView(row3Layout)
        renderBottomRow()
    }

    private fun renderBottomRow() {
        val bottomRow = LinearLayout(context).apply {
            orientation = HORIZONTAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        }

        val modeToggleKey = createKeyView(if (isSymbolPanel) "ABC" else "123", isSpecial = true, weight = 1.4f) {
            isSymbolPanel = !isSymbolPanel
            renderPanel()
        }
        bottomRow.addView(modeToggleKey)

        val globeKey = createIconKeyView(
            iconRes = R.drawable.ic_globe,
            weight = 1.0f,
            contentDescription = "Switch keyboard"
        ) {
            try {
                val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
                val binder = windowToken
                if (imm != null && binder != null) {
                    imm.switchToNextInputMethod(binder, false)
                }
            } catch (e: Exception) {
                // Fallback
            }
        }
        bottomRow.addView(globeKey)

        val settingsKey = createIconKeyView(
            iconRes = R.drawable.ic_settings,
            weight = 1.0f,
            contentDescription = "Keyboard settings"
        ) {
            controller.openAppSettings()
        }
        bottomRow.addView(settingsKey)

        val spaceKey = createKeyView("English", weight = 4.2f, isSpace = true) {
            controller.onKeyTyped(" ")
        }
        bottomRow.addView(spaceKey)

        val enterKey = createIconKeyView(
            iconRes = R.drawable.ic_enter,
            weight = 1.5f,
            isAccent = true,
            contentDescription = "Enter"
        ) {
            controller.onEnterPressed(editorInfo)
        }
        enterIconView = enterKey.getTag(R.id.tag_icon_view) as? ImageView
        updateEnterKeyLabel()
        bottomRow.addView(enterKey)

        mainPanelContainer.addView(bottomRow)
    }

    private fun createKeyRow(keys: List<String>, paddingHorizontalDp: Float = 0f): LinearLayout {
        val row = LinearLayout(context).apply {
            orientation = HORIZONTAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
            if (paddingHorizontalDp > 0) {
                setPadding(dpToPx(paddingHorizontalDp), 0, dpToPx(paddingHorizontalDp), 0)
            }
        }
        for (char in keys) {
            val key = createKeyView(char, weight = 1.0f) {
                controller.onKeyTyped(char)
            }
            if (!isSymbolPanel) {
                letterKeyViews.add(key)
            }
            row.addView(key)
        }
        return row
    }

    private fun createKeyView(
        label: String,
        isSpecial: Boolean = false,
        weight: Float = 1.0f,
        isSpace: Boolean = false,
        onClick: () -> Unit
    ): TextView {
        val bgNormal = when {
            isSpace -> theme.spaceKeyColor
            isSpecial -> theme.specialKeyColor
            else -> theme.keyColor
        }
        val bgPressed = if (isSpecial) theme.specialKeyPressedColor else theme.keyPressedColor

        val shapeNormal = buildKeyShape(bgNormal, isAccent = false)
        val shapePressed = buildKeyShape(bgPressed, isAccent = false)

        return TextView(context).apply {
            text = label
            gravity = Gravity.CENTER
            includeFontPadding = false
            setTextColor(if (isSpace) theme.secondaryTextColor else theme.textColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, if (isSpace) 13f else 17f)
            if (isSpace) letterSpacing = 0.05f
            background = shapeNormal
            elevation = dpToPx(KEY_ELEVATION_DP).toFloat()

            val keyHeightPx = dpToPx(getKeyHeightDp())
            layoutParams = LayoutParams(0, keyHeightPx, weight).apply {
                setMargins(dpToPx(3f), dpToPx(4f), dpToPx(3f), dpToPx(4f))
            }

            setOnTouchListener { v, event ->
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        v.background = shapePressed
                        v.elevation = dpToPx(0.5f).toFloat()
                        animatePress(v)
                        v.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                    }
                    MotionEvent.ACTION_UP -> {
                        v.background = shapeNormal
                        v.elevation = dpToPx(KEY_ELEVATION_DP).toFloat()
                        animateRelease(v)
                        onClick()
                    }
                    MotionEvent.ACTION_CANCEL -> {
                        v.background = shapeNormal
                        v.elevation = dpToPx(KEY_ELEVATION_DP).toFloat()
                        animateRelease(v)
                    }
                }
                true
            }
        }
    }

    private fun createIconKeyView(
        iconRes: Int,
        weight: Float,
        isAccent: Boolean = false,
        contentDescription: String? = null,
        onClick: () -> Unit
    ): FrameLayout {
        val bgNormal = if (isAccent) theme.accentColor else theme.specialKeyColor
        val bgPressed = if (isAccent) theme.accentColorAlt else theme.specialKeyPressedColor

        val shapeNormal = buildKeyShape(bgNormal, isAccent)
        val shapePressed = buildKeyShape(bgPressed, isAccent = false)

        val iconSizePx = dpToPx(ICON_SIZE_DP)
        val tintColor = if (isAccent) theme.chipTextColor else theme.textColor

        val imageView = ImageView(context).apply {
            setImageDrawable(ContextCompat.getDrawable(context, iconRes)?.mutate()?.apply {
                setTint(tintColor)
            })
            scaleType = ImageView.ScaleType.FIT_CENTER
            layoutParams = FrameLayout.LayoutParams(iconSizePx, iconSizePx, Gravity.CENTER)
        }

        val keyHeightPx = dpToPx(getKeyHeightDp())
        return FrameLayout(context).apply {
            background = shapeNormal
            elevation = dpToPx(KEY_ELEVATION_DP).toFloat()
            this.contentDescription = contentDescription
            isClickable = true
            isFocusable = true
            layoutParams = LinearLayout.LayoutParams(0, keyHeightPx, weight).apply {
                setMargins(dpToPx(3f), dpToPx(4f), dpToPx(3f), dpToPx(4f))
            }
            addView(imageView)
            setTag(R.id.tag_icon_view, imageView)

            setOnTouchListener { v, event ->
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        v.background = shapePressed
                        v.elevation = dpToPx(0.5f).toFloat()
                        animatePress(v)
                        v.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                    }
                    MotionEvent.ACTION_UP -> {
                        v.background = shapeNormal
                        v.elevation = dpToPx(KEY_ELEVATION_DP).toFloat()
                        animateRelease(v)
                        onClick()
                        v.performClick()
                    }
                    MotionEvent.ACTION_CANCEL -> {
                        v.background = shapeNormal
                        v.elevation = dpToPx(KEY_ELEVATION_DP).toFloat()
                        animateRelease(v)
                    }
                }
                true
            }
        }
    }

    private fun setupBackspaceRepeat(view: FrameLayout) {
        val bgNormal = theme.specialKeyColor
        val bgPressed = theme.specialKeyPressedColor
        val shapeNormal = buildKeyShape(bgNormal, isAccent = false)
        val shapePressed = buildKeyShape(bgPressed, isAccent = false)

        view.setOnTouchListener { v, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    v.background = shapePressed
                    v.elevation = dpToPx(0.5f).toFloat()
                    animatePress(v)
                    v.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                    controller.onBackspacePressed()
                    backspaceRunnable = object : Runnable {
                        override fun run() {
                            controller.onBackspacePressed()
                            handler.postDelayed(this, 60L)
                        }
                    }
                    handler.postDelayed(backspaceRunnable!!, 400L)
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    v.background = shapeNormal
                    v.elevation = dpToPx(KEY_ELEVATION_DP).toFloat()
                    animateRelease(v)
                    backspaceRunnable?.let { handler.removeCallbacks(it) }
                }
            }
            true
        }
    }

    private fun updateShiftUi(shiftState: ShiftState) {
        val shiftDrawableRes = when (shiftState) {
            ShiftState.LOWERCASE -> R.drawable.ic_shift
            ShiftState.SHIFT_ON -> R.drawable.ic_shift
            ShiftState.CAPS_LOCK -> R.drawable.ic_caps_lock
        }
        val drawable: Drawable? = ContextCompat.getDrawable(context, shiftDrawableRes)?.mutate()?.apply {
            setTint(if (shiftState != ShiftState.LOWERCASE) theme.accentColor else theme.textColor)
        }
        shiftIconView?.setImageDrawable(drawable)

        val isUpper = shiftState != ShiftState.LOWERCASE
        for (view in letterKeyViews) {
            val t = view.text.toString()
            view.text = if (isUpper) t.uppercase() else t.lowercase()
        }
    }

    private fun updateEnterKeyLabel() {
        val action = editorInfo?.imeOptions?.and(EditorInfo.IME_MASK_ACTION)
        val iconRes = when (action) {
            EditorInfo.IME_ACTION_SEARCH -> R.drawable.ic_search
            EditorInfo.IME_ACTION_DONE -> R.drawable.ic_done
            EditorInfo.IME_ACTION_GO, EditorInfo.IME_ACTION_NEXT, EditorInfo.IME_ACTION_SEND -> R.drawable.ic_arrow_forward
            else -> R.drawable.ic_enter
        }
        val drawable = ContextCompat.getDrawable(context, iconRes)?.mutate()?.apply {
            setTint(theme.chipTextColor)
        }
        enterIconView?.setImageDrawable(drawable)
    }
}
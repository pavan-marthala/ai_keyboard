package com.pk.ai_keyboard.ui

import android.annotation.SuppressLint
import android.content.Context
import android.content.res.Configuration
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.util.AttributeSet
import android.util.TypedValue
import android.view.Gravity
import android.view.HapticFeedbackConstants
import android.view.MotionEvent
import android.view.View
import android.view.animation.DecelerateInterpolator
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
import com.pk.ai_keyboard.ui.theme.KeyboardTheme

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

    private lateinit var tvStatus: TextView
    private lateinit var toolbarContainer: LinearLayout
    private lateinit var mainPanelContainer: LinearLayout

    private val letterKeyViews = mutableListOf<TextView>()
    private var shiftKeyView: TextView? = null
    private var enterKeyView: TextView? = null

    private val handler = Handler(Looper.getMainLooper())
    private var backspaceRunnable: Runnable? = null

    companion object {
        private const val KEY_CORNER_RADIUS_DP = 14f
        private const val KEY_ELEVATION_DP = 1.5f
        private const val PRESS_SCALE = 0.93f
        private const val PRESS_ANIM_MS = 70L
        private const val RELEASE_ANIM_MS = 120L
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
        controller.onStatusUpdate = { status ->
            tvStatus.text = status
        }
        controller.onShiftStateChanged = { shiftState ->
            updateShiftUi(shiftState)
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

    private fun buildUi() {
        removeAllViews()

        // 1. Top AI Toolbar
        val toolbarLayout = HorizontalScrollView(context).apply {
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
            isHorizontalScrollBarEnabled = false
            overScrollMode = View.OVER_SCROLL_NEVER
            setBackgroundColor(theme.toolbarColor)
            setPadding(dpToPx(10f), dpToPx(6f), dpToPx(10f), dpToPx(6f))
        }

        toolbarContainer = LinearLayout(context).apply {
            orientation = HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        tvStatus = TextView(context).apply {
            text = "✨"
            setTextColor(theme.textColor)
            setTypeface(null, Typeface.BOLD)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12.5f)
            setPadding(dpToPx(6f), dpToPx(2f), dpToPx(12f), dpToPx(2f))
        }
        toolbarContainer.addView(tvStatus)

        toolbarLayout.addView(toolbarContainer)
        addView(toolbarLayout)

        // Subtle divider
        val divider = View(context).apply {
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, dpToPx(1f))
            setBackgroundColor(theme.dividerColor)
        }
        addView(divider)

        // 2. Main Keyboard Panel Container
        mainPanelContainer = LinearLayout(context).apply {
            orientation = VERTICAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
            setPadding(dpToPx(4f), dpToPx(6f), dpToPx(4f), dpToPx(6f))
        }
        addView(mainPanelContainer)

        renderPanel()
    }

    fun refreshToolbar() {
        if (!::toolbarContainer.isInitialized) return

        toolbarContainer.removeAllViews()
        toolbarContainer.addView(tvStatus)

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
                val chip = createChipView(label) {
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

    private fun createChipView(label: String, onClick: () -> Unit): TextView {
        val shapeNormal = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = dpToPx(18f).toFloat()
            colors = intArrayOf(theme.accentColorAlt, theme.accentColor)
            orientation = GradientDrawable.Orientation.TL_BR
        }
        val shapePressed = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = dpToPx(18f).toFloat()
            setColor(theme.accentColor)
        }

        return TextView(context).apply {
            text = label
            setTextColor(theme.chipTextColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12.5f)
            setTypeface(null, Typeface.BOLD)
            background = shapeNormal
            elevation = dpToPx(1f).toFloat()
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
                        v.animate().scaleX(0.95f).scaleY(0.95f).setDuration(PRESS_ANIM_MS).start()
                    }
                    MotionEvent.ACTION_UP -> {
                        v.background = shapeNormal
                        v.animate().scaleX(1f).scaleY(1f).setDuration(RELEASE_ANIM_MS)
                            .setInterpolator(DecelerateInterpolator()).start()
                        if (event.action != MotionEvent.ACTION_CANCEL) v.performClick()
                    }
                    MotionEvent.ACTION_CANCEL -> {
                        v.background = shapeNormal
                        v.animate().scaleX(1f).scaleY(1f).setDuration(RELEASE_ANIM_MS).start()
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

        // Row 3: Shift + Letters + Backspace
        val row3Layout = LinearLayout(context).apply {
            orientation = HORIZONTAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        }

        shiftKeyView = createKeyView("", isSpecial = true, weight = 1.4f, iconRes = R.drawable.ic_shift) {
            controller.onShiftPressed()
        }
        row3Layout.addView(shiftKeyView)

        for (char in row3) {
            val key = createKeyView(char, weight = 1.0f) {
                controller.onKeyTyped(char)
            }
            letterKeyViews.add(key)
            row3Layout.addView(key)
        }

        val backspaceKey = createKeyView("", isSpecial = true, weight = 1.4f, iconRes = R.drawable.ic_backspace) {
            controller.onBackspacePressed()
        }.apply {
            setupBackspaceRepeat(this)
        }
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

        val backspaceKey = createKeyView("", isSpecial = true, weight = 1.4f, iconRes = R.drawable.ic_backspace) {
            controller.onBackspacePressed()
        }.apply {
            setupBackspaceRepeat(this)
        }
        row3Layout.addView(backspaceKey)

        mainPanelContainer.addView(row3Layout)
        renderBottomRow()
    }

    private fun renderBottomRow() {
        val bottomRow = LinearLayout(context).apply {
            orientation = HORIZONTAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        }

        // 123 / ABC Toggle
        val modeToggleKey = createKeyView(if (isSymbolPanel) "ABC" else "123", isSpecial = true, weight = 1.4f) {
            isSymbolPanel = !isSymbolPanel
            renderPanel()
        }
        bottomRow.addView(modeToggleKey)

        // Globe Switcher
        val globeKey = createKeyView("", isSpecial = true, weight = 1.0f, iconRes = R.drawable.ic_globe) {
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

        // Settings Key
        val settingsKey = createKeyView("", isSpecial = true, weight = 1.0f, iconRes = R.drawable.ic_settings) {
            controller.openAppSettings()
        }
        bottomRow.addView(settingsKey)

        // Space Bar
        val spaceKey = createKeyView("English", weight = 4.2f, isSpace = true) {
            controller.onKeyTyped(" ")
        }
        bottomRow.addView(spaceKey)

        // Enter Key — premium gradient CTA
        enterKeyView = createKeyView("↵", isSpecial = true, weight = 1.5f, isAccent = true) {
            controller.onEnterPressed(editorInfo)
        }
        updateEnterKeyLabel()
        bottomRow.addView(enterKeyView)

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
        iconRes: Int? = null,
        isAccent: Boolean = false,
        isSpace: Boolean = false,
        onClick: () -> Unit
    ): TextView {
        val bgNormal = when {
            isAccent -> theme.accentColor
            isSpace -> theme.spaceKeyColor
            isSpecial -> theme.specialKeyColor
            else -> theme.keyColor
        }
        val bgPressed = when {
            isAccent -> theme.accentColorAlt
            isSpecial -> theme.specialKeyPressedColor
            else -> theme.keyPressedColor
        }

        fun buildShape(fillColor: Int): GradientDrawable = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = dpToPx(KEY_CORNER_RADIUS_DP).toFloat()
            if (isAccent) {
                colors = intArrayOf(theme.accentColorAlt, theme.accentColor)
                orientation = GradientDrawable.Orientation.TL_BR
            } else {
                setColor(fillColor)
            }
            if (theme.keyStrokeColor != 0x00000000 && !isAccent) {
                setStroke(dpToPx(0.75f), theme.keyStrokeColor)
            }
        }

        val shapeNormal = buildShape(bgNormal)
        val shapePressed = buildShape(bgPressed)

        return TextView(context).apply {
            text = label
            gravity = Gravity.CENTER
            setTextColor(if (isAccent) theme.chipTextColor else if (isSpace) theme.secondaryTextColor else theme.textColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, if (isSpace) 13f else 17f)
            if (isSpace) {
                setTypeface(null, Typeface.NORMAL)
                letterSpacing = 0.05f
            } else {
                setTypeface(null, Typeface.NORMAL)
            }
            background = shapeNormal
            elevation = dpToPx(KEY_ELEVATION_DP).toFloat()

            if (iconRes != null) {
                val drawable = ContextCompat.getDrawable(context, iconRes)?.apply {
                    setTint(if (isAccent) theme.chipTextColor else theme.textColor)
                }
                setCompoundDrawablesWithIntrinsicBounds(drawable, null, null, null)
            }

            val keyHeightPx = dpToPx(getKeyHeightDp())
            val params = LayoutParams(0, keyHeightPx, weight).apply {
                setMargins(dpToPx(3f), dpToPx(4f), dpToPx(3f), dpToPx(4f))
            }
            layoutParams = params

            setOnTouchListener { v, event ->
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        v.background = shapePressed
                        v.elevation = dpToPx(0.5f).toFloat()
                        v.animate().scaleX(PRESS_SCALE).scaleY(PRESS_SCALE)
                            .setDuration(PRESS_ANIM_MS).start()
                        v.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                    }
                    MotionEvent.ACTION_UP -> {
                        v.background = shapeNormal
                        v.elevation = dpToPx(KEY_ELEVATION_DP).toFloat()
                        v.animate().scaleX(1f).scaleY(1f).setDuration(RELEASE_ANIM_MS)
                            .setInterpolator(DecelerateInterpolator()).start()
                        onClick()
                    }
                    MotionEvent.ACTION_CANCEL -> {
                        v.background = shapeNormal
                        v.elevation = dpToPx(KEY_ELEVATION_DP).toFloat()
                        v.animate().scaleX(1f).scaleY(1f).setDuration(RELEASE_ANIM_MS).start()
                    }
                }
                true
            }
        }
    }

    private fun setupBackspaceRepeat(view: View) {
        view.setOnTouchListener { v, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    controller.onBackspacePressed()
                    v.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                    v.animate().scaleX(PRESS_SCALE).scaleY(PRESS_SCALE).setDuration(PRESS_ANIM_MS).start()
                    backspaceRunnable = object : Runnable {
                        override fun run() {
                            controller.onBackspacePressed()
                            handler.postDelayed(this, 60L)
                        }
                    }
                    handler.postDelayed(backspaceRunnable!!, 400L)
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    v.animate().scaleX(1f).scaleY(1f).setDuration(RELEASE_ANIM_MS)
                        .setInterpolator(DecelerateInterpolator()).start()
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
        val drawable = ContextCompat.getDrawable(context, shiftDrawableRes)?.apply {
            setTint(if (shiftState != ShiftState.LOWERCASE) theme.accentColor else theme.textColor)
        }
        shiftKeyView?.setCompoundDrawablesWithIntrinsicBounds(drawable, null, null, null)

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
            else -> null
        }
        if (iconRes != null) {
            val drawable = ContextCompat.getDrawable(context, iconRes)?.apply {
                setTint(theme.chipTextColor)
            }
            enterKeyView?.text = ""
            enterKeyView?.setCompoundDrawablesWithIntrinsicBounds(drawable, null, null, null)
        } else {
            enterKeyView?.setCompoundDrawablesWithIntrinsicBounds(null, null, null, null)
            enterKeyView?.text = "↵"
        }
    }
}
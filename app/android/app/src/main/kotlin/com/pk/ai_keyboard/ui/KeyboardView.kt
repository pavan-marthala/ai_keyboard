package com.pk.ai_keyboard.ui

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.util.AttributeSet
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.*
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

    init {
        orientation = VERTICAL
        setBackgroundColor(theme.backgroundColor)
        buildUi()
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

    private fun buildUi() {
        removeAllViews()

        // 1. Top AI Toolbar
        val toolbarLayout = HorizontalScrollView(context).apply {
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
            isHorizontalScrollBarEnabled = false
            setBackgroundColor(theme.toolbarColor)
            setPadding(dpToPx(8f), dpToPx(6f), dpToPx(8f), dpToPx(6f))
        }

        toolbarContainer = LinearLayout(context).apply {
            orientation = HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        tvStatus = TextView(context).apply {
            text = "✨ AI Keyboard"
            setTextColor(theme.accentColor)
            setTypeface(null, Typeface.BOLD)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            setPadding(dpToPx(6f), dpToPx(4f), dpToPx(12f), dpToPx(4f))
        }
        toolbarContainer.addView(tvStatus)

        toolbarLayout.addView(toolbarContainer)
        addView(toolbarLayout)

        // Divider
        val divider = View(context).apply {
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, dpToPx(1f))
            setBackgroundColor(theme.dividerColor)
        }
        addView(divider)

        // 2. Main Keyboard Panels Container
        mainPanelContainer = LinearLayout(context).apply {
            orientation = VERTICAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
            setPadding(dpToPx(2f), dpToPx(4f), dpToPx(2f), dpToPx(6f))
        }
        addView(mainPanelContainer)

        renderPanel()
    }

    fun refreshToolbar() {
        if (!::toolbarContainer.isInitialized) return

        // Keep status view
        toolbarContainer.removeAllViews()
        toolbarContainer.addView(tvStatus)

        val commands = listOf(
            "@fix" to "Fix",
            "@rewrite" to "Rewrite",
            "@pro" to "Pro",
            "@casual" to "Casual",
            "@short" to "Short",
            "@expand" to "Expand",
            "@translate" to "Translate"
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
        val shape = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = dpToPx(16f).toFloat()
            setColor(theme.accentColor)
        }
        return TextView(context).apply {
            text = label
            setTextColor(0xFFFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            setTypeface(null, Typeface.BOLD)
            background = shape
            setPadding(dpToPx(12f), dpToPx(6f), dpToPx(12f), dpToPx(6f))
            layoutParams = LinearLayout.LayoutParams(
                LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(dpToPx(3f), 0, dpToPx(3f), 0)
            }
            setOnClickListener { onClick() }
        }
    }

    private fun showLanguageSelectorPopup() {
        val popupView = LinearLayout(context).apply {
            orientation = VERTICAL
            setBackgroundColor(theme.toolbarColor)
            setPadding(dpToPx(12f), dpToPx(12f), dpToPx(12f), dpToPx(12f))
        }

        val title = TextView(context).apply {
            text = "Select Target Language"
            setTextColor(theme.textColor)
            setTypeface(null, Typeface.BOLD)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            setPadding(0, 0, 0, dpToPx(8f))
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
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
                setTextColor(theme.textColor)
                setBackgroundColor(theme.keyColor)
                setOnClickListener {
                    popupWindow.dismiss()
                    controller.onTranslateLanguageSelected(code)
                }
            }
            grid.addView(btn)
        }

        popupView.addView(grid)
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

        shiftKeyView = createKeyView("⇧", isSpecial = true, weight = 1.4f) {
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

        val backspaceKey = createKeyView("⌫", isSpecial = true, weight = 1.4f) {
            controller.onBackspacePressed()
        }.apply {
            setupBackspaceRepeat(this)
        }
        row3Layout.addView(backspaceKey)

        mainPanelContainer.addView(row3Layout)

        // Bottom Action Row
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

        val backspaceKey = createKeyView("⌫", isSpecial = true, weight = 1.4f) {
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
        val globeKey = createKeyView("🌐", isSpecial = true, weight = 1.0f) {
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
        val settingsKey = createKeyView("⚙", isSpecial = true, weight = 1.0f) {
            controller.openAppSettings()
        }
        bottomRow.addView(settingsKey)

        // Space Bar (Generous touch width)
        val spaceKey = createKeyView("SPACE", weight = 4.2f) {
            controller.onKeyTyped(" ")
        }
        bottomRow.addView(spaceKey)

        // Enter Key
        enterKeyView = createKeyView("↵", isSpecial = true, weight = 1.5f) {
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
        onClick: () -> Unit
    ): TextView {
        val bgNormal = if (isSpecial) theme.specialKeyColor else theme.keyColor

        val shapeNormal = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = dpToPx(6f).toFloat()
            setColor(bgNormal)
        }

        val shapePressed = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = dpToPx(6f).toFloat()
            setColor(theme.keyPressedColor)
        }

        return TextView(context).apply {
            text = label
            gravity = Gravity.CENTER
            setTextColor(theme.textColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 17f)
            background = shapeNormal

            val params = LinearLayout.LayoutParams(0, dpToPx(48f), weight).apply {
                setMargins(dpToPx(2f), dpToPx(3f), dpToPx(2f), dpToPx(3f))
            }
            layoutParams = params

            setOnTouchListener { v, event ->
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        v.background = shapePressed
                    }
                    MotionEvent.ACTION_UP -> {
                        v.background = shapeNormal
                        onClick()
                    }
                    MotionEvent.ACTION_CANCEL -> {
                        v.background = shapeNormal
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
                    backspaceRunnable = object : Runnable {
                        override fun run() {
                            controller.onBackspacePressed()
                            handler.postDelayed(this, 60L)
                        }
                    }
                    handler.postDelayed(backspaceRunnable!!, 400L)
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    backspaceRunnable?.let { handler.removeCallbacks(it) }
                }
            }
            true
        }
    }

    private fun updateShiftUi(shiftState: ShiftState) {
        shiftKeyView?.text = when (shiftState) {
            ShiftState.LOWERCASE -> "⇧"
            ShiftState.SHIFT_ON -> "⇪"
            ShiftState.CAPS_LOCK -> "🔒"
        }

        val isUpper = shiftState != ShiftState.LOWERCASE
        for (view in letterKeyViews) {
            val t = view.text.toString()
            view.text = if (isUpper) t.uppercase() else t.lowercase()
        }
    }

    private fun updateEnterKeyLabel() {
        val action = editorInfo?.imeOptions?.and(EditorInfo.IME_MASK_ACTION)
        enterKeyView?.text = when (action) {
            EditorInfo.IME_ACTION_SEARCH -> "🔍"
            EditorInfo.IME_ACTION_DONE -> "✓"
            EditorInfo.IME_ACTION_GO -> "➔"
            EditorInfo.IME_ACTION_NEXT -> "➜"
            EditorInfo.IME_ACTION_SEND -> "✈"
            else -> "↵"
        }
    }
}


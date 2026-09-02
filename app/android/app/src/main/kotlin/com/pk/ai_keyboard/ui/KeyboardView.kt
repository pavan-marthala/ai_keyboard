package com.pk.ai_keyboard.ui

import android.annotation.SuppressLint
import android.content.Context
import android.content.res.ColorStateList
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.Drawable
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.text.Editable
import android.text.TextUtils
import android.text.TextWatcher
import android.util.AttributeSet
import android.util.TypedValue
import android.view.Gravity
import android.view.HapticFeedbackConstants
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
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
import androidx.emoji2.emojipicker.EmojiPickerView
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide
import com.pk.ai_keyboard.R
import com.pk.ai_keyboard.command.NativeCommandRegistry
import com.pk.ai_keyboard.gif.GifItem
import com.pk.ai_keyboard.gif.GifInsertionResult
import com.pk.ai_keyboard.keyboard.KeyboardController
import com.pk.ai_keyboard.keyboard.KeyboardHeightRepository
import com.pk.ai_keyboard.keyboard.KeyboardMode
import com.pk.ai_keyboard.keyboard.ShiftState
import com.pk.ai_keyboard.suggestion.SuggestionResult
import com.pk.ai_keyboard.ui.theme.KeyboardTheme
import com.pk.ai_keyboard.voice.VoiceState
import kotlinx.coroutines.*

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
    private var morePanelPageIndex = 0

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

    // GIF state
    private val uiScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var gifSearchJob: Job? = null
    private var currentGifQuery: String = ""
    private var currentGifOffset: Int = 0
    private var isGifLoading: Boolean = false
    private var hasMoreGifs: Boolean = true
    private val gifItemsList = mutableListOf<GifItem>()
    private var gifAdapter: GifAdapter? = null

    companion object {
        private const val KEY_CORNER_RADIUS_DP = 14f
        private const val KEY_ELEVATION_DP = 1.5f
        private const val PRESS_SCALE = 0.93f
        private const val PRESS_ANIM_MS = 70L
        private const val RELEASE_ANIM_MS = 120L
        private const val ICON_SIZE_DP = 22f
        private const val SEARCH_DEBOUNCE_MS = 300L

        // Toolbar icon buttons all share this exact icon size and touch target,
        // so mic / menu / back / dictation-state / app-icon never look mismatched.
        private const val TOOLBAR_ICON_SIZE_DP = 22f
        private const val TOOLBAR_TOUCH_TARGET_DP = 38f
    }

    /** A medium-weight system font used for panel titles and tool labels — reads
     *  noticeably more "designed" than the default regular/bold-only pairing. */
    private val mediumTypeface: Typeface by lazy { Typeface.create("sans-serif-medium", Typeface.NORMAL) }

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
        if (::mainPanelContainer.isInitialized) {
            mainPanelContainer.layoutParams.height = getContentPanelHeightPx()
        }
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
        controller.onKeyboardModeChanged = { mode ->
            updateModeUi(mode)
        }
        controller.onKeyboardHeightChanged = { _ ->
            if (::mainPanelContainer.isInitialized) {
                mainPanelContainer.layoutParams.height = getContentPanelHeightPx()
            }
            renderPanel()
        }
        controller.clipboardHistoryManager.onHistoryUpdated = { _ ->
            if (controller.keyboardMode == KeyboardMode.CLIPBOARD) {
                renderPanel()
            }
        }
        controller.voiceInputController.onStateChanged = { voiceState ->
            updateDictationToolbar(voiceState)
        }
        updateModeUi(controller.keyboardMode)
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
        if (isLandscape) return 36f
        val contentHeightDp = if (::controller.isInitialized) {
            controller.keyboardHeightRepository.getHeight().toFloat()
        } else {
            216f
        }
        return ((contentHeightDp - 12f) / 4f) - 8f
    }

    private fun getContentPanelHeightPx(): Int {
        return if (::controller.isInitialized) {
            val heightDp = controller.keyboardHeightRepository.getHeight()
            dpToPx(heightDp.toFloat())
        } else {
            dpToPx((getKeyHeightDp() + 8f) * 4f)
        }
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

    /** Circular ghost-press background shared by every toolbar icon button — mic,
     *  menu, back-arrow, dictation-state and the app icon all give identical tap
     *  feedback instead of the flat, background-less touch they had before. */
    private fun buildToolbarGhostShape(fillColor: Int): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(fillColor)
        }
    }

    /** Small rounded icon badge used inside list/grid rows (tools panel, clipboard
     *  cards) so every leading icon sits in a consistent tinted container instead
     *  of floating bare next to text at a different visual weight. */
    private fun createIconBadge(iconRes: Int, badgeSizeDp: Float, iconSizeDp: Float, tint: Int): FrameLayout {
        val badgeSizePx = dpToPx(badgeSizeDp)
        val iconSizePx = dpToPx(iconSizeDp)
        val iconView = ImageView(context).apply {
            setImageDrawable(ContextCompat.getDrawable(context, iconRes)?.mutate()?.apply {
                setTint(tint)
            })
            scaleType = ImageView.ScaleType.FIT_CENTER
            layoutParams = FrameLayout.LayoutParams(iconSizePx, iconSizePx, Gravity.CENTER)
        }
        return FrameLayout(context).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dpToPx(badgeSizeDp * 0.32f).toFloat()
                setColor(theme.specialKeyColor)
            }
            layoutParams = LinearLayout.LayoutParams(badgeSizePx, badgeSizePx)
            addView(iconView)
        }
    }

    /** Centered "nothing here yet" state — icon above a title, optional subtitle —
     *  reused for the clipboard empty state, GIF empty/no-results state, and the
     *  Stickers placeholder, so all three read as one consistent design language. */
    private fun createEmptyStateView(iconRes: Int, title: String, subtitle: String? = null): LinearLayout {
        return LinearLayout(context).apply {
            orientation = VERTICAL
            gravity = Gravity.CENTER
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)

            val iconBadge = createIconBadge(iconRes, badgeSizeDp = 52f, iconSizeDp = 26f, tint = theme.secondaryTextColor).apply {
                (layoutParams as LinearLayout.LayoutParams).apply {
                    gravity = Gravity.CENTER_HORIZONTAL
                    bottomMargin = dpToPx(10f)
                }
            }
            addView(iconBadge)

            val titleView = TextView(context).apply {
                text = title
                setTextColor(theme.textColor)
                typeface = mediumTypeface
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 14.5f)
                gravity = Gravity.CENTER
            }
            addView(titleView)

            if (subtitle != null) {
                val subtitleView = TextView(context).apply {
                    text = subtitle
                    setTextColor(theme.secondaryTextColor)
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 12.5f)
                    gravity = Gravity.CENTER
                    setPadding(0, dpToPx(3f), 0, 0)
                }
                addView(subtitleView)
            }
        }
    }

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
        // 1. App Icon / Close Button (Leftmost control)
        appIconView = createAppIconView {
            if (::controller.isInitialized) {
                controller.handleAppIconTap()
            }
        }
        toolbarRoot.addView(appIconView)

        // 2. Suggestion / Dynamic Content Area (Center, flexible width)
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

        // 4. Menu Button (Rightmost 3-dot)
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
        // 5. Back Arrow [ ← ] (Leftmost exit control)
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

        // 6. Dictation Status Text (Center message)
        dictationStatusTextView = TextView(context).apply {
            setTextColor(theme.textColor)
            typeface = mediumTypeface
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13.5f)
            gravity = Gravity.CENTER
            setPadding(dpToPx(8f), 0, dpToPx(8f), 0)
            layoutParams = LayoutParams(0, LayoutParams.WRAP_CONTENT, 1.0f).apply {
                gravity = Gravity.CENTER_VERTICAL
            }
            visibility = View.GONE
        }
        toolbarRoot.addView(dictationStatusTextView)

        // 7. Dictation State Icon (Rightmost state indicator / mic toggle)
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
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, getContentPanelHeightPx())
            setPadding(dpToPx(4f), dpToPx(6f), dpToPx(4f), dpToPx(6f))
        }
        addView(mainPanelContainer)

        renderPanel()
    }

    private fun updateModeUi(mode: KeyboardMode) {
        if (!::controller.isInitialized) return
        when (mode) {
            KeyboardMode.MORE -> {
                appIconView.setImageDrawable(ContextCompat.getDrawable(context, R.drawable.ic_close)?.mutate()?.apply {
                    setTint(theme.textColor)
                })
                appIconView.contentDescription = "Close Tools Panel"
            }
            KeyboardMode.CLIPBOARD -> {
                appIconView.setImageDrawable(ContextCompat.getDrawable(context, R.drawable.ic_arrow_back)?.mutate()?.apply {
                    setTint(theme.textColor)
                })
                appIconView.contentDescription = "Exit Clipboard History"
                controller.clipboardHistoryManager.checkCurrentPrimaryClip()
            }
            KeyboardMode.EMOJI -> {
                appIconView.setImageDrawable(ContextCompat.getDrawable(context, R.drawable.ic_arrow_back)?.mutate()?.apply {
                    setTint(theme.textColor)
                })
                appIconView.contentDescription = "Exit Emoji Keyboard"
            }
            KeyboardMode.GIF -> {
                appIconView.setImageDrawable(ContextCompat.getDrawable(context, R.drawable.ic_arrow_back)?.mutate()?.apply {
                    setTint(theme.textColor)
                })
                appIconView.contentDescription = "Exit GIF Keyboard"
            }
            KeyboardMode.RESIZE -> {
                appIconView.setImageDrawable(ContextCompat.getDrawable(context, R.drawable.ic_arrow_back)?.mutate()?.apply {
                    setTint(theme.textColor)
                })
                appIconView.contentDescription = "Exit Keyboard Resize"
            }
            KeyboardMode.STICKERS -> {
                appIconView.setImageDrawable(ContextCompat.getDrawable(context, R.drawable.ic_arrow_back)?.mutate()?.apply {
                    setTint(theme.textColor)
                })
                appIconView.contentDescription = "Exit Stickers"
            }
            else -> {
                appIconView.setImageResource(R.mipmap.ic_launcher)
                appIconView.contentDescription = "App Icon Mode Toggle"
            }
        }
        renderPanel()
    }

    private fun renderPanel() {
        mainPanelContainer.removeAllViews()
        letterKeyViews.clear()

        if (!::controller.isInitialized) return

        when (controller.keyboardMode) {
            KeyboardMode.MORE -> renderMoreToolsPanel()
            KeyboardMode.CLIPBOARD -> renderClipboardPanel()
            KeyboardMode.EMOJI -> renderEmojiPanel()
            KeyboardMode.GIF -> renderGifPanel()
            KeyboardMode.RESIZE -> renderResizePanel()
            KeyboardMode.STICKERS -> renderStickersPanel()
            else -> {
                if (isSymbolPanel) {
                    renderSymbolLayout()
                } else {
                    renderQwertyLayout()
                }
            }
        }
    }

    private fun renderEmojiPanel() {
        val emojiPickerView = EmojiPickerView(context).apply {
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, getContentPanelHeightPx())
            setOnEmojiPickedListener { emojiItem ->
                val emojiStr = emojiItem.emoji
                if (!emojiStr.isNullOrEmpty()) {
                    controller.onKeyTyped(emojiStr)
                }
            }
        }
        mainPanelContainer.addView(emojiPickerView)
    }

    /** Not implemented yet — was reachable via the tools grid ("Stickers") but had
     *  no render case, so it silently fell through to the letter keyboard. This is
     *  a proper placeholder in the same visual language as the other empty states,
     *  swap the label out once sticker packs are wired up. */
    private fun renderStickersPanel() {
        val container = FrameLayout(context).apply {
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, getContentPanelHeightPx())
        }
        container.addView(
            createEmptyStateView(
                iconRes = R.drawable.ic_sticker,
                title = "Stickers",
                subtitle = "Coming soon"
            )
        )
        mainPanelContainer.addView(container)
    }

    private fun renderClipboardPanel() {
        val clipboardContainer = LinearLayout(context).apply {
            orientation = VERTICAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, getContentPanelHeightPx())
            setPadding(dpToPx(8f), dpToPx(4f), dpToPx(8f), dpToPx(4f))
        }

        val history = controller.clipboardHistoryManager.getHistory()

        if (history.isEmpty()) {
            clipboardContainer.addView(
                createEmptyStateView(
                    iconRes = R.drawable.ic_clipboard,
                    title = "No copied text yet",
                    subtitle = "Text you copy will show up here"
                )
            )
        } else {
            val scrollView = ScrollView(context).apply {
                layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
                isVerticalScrollBarEnabled = true
            }

            val listLayout = LinearLayout(context).apply {
                orientation = VERTICAL
                layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
            }

            for (text in history) {
                val card = createClipboardCardView(text) {
                    controller.commitClipboardItem(text)
                }
                listLayout.addView(card)
            }

            scrollView.addView(listLayout)
            clipboardContainer.addView(scrollView)
        }

        mainPanelContainer.addView(clipboardContainer)
    }

    private fun renderGifPanel() {
        val gifRootLayout = LinearLayout(context).apply {
            orientation = VERTICAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, getContentPanelHeightPx())
            setPadding(dpToPx(4f), dpToPx(2f), dpToPx(4f), dpToPx(2f))
        }

        // Search Bar — rounded card with a leading search glyph, matching the
        // stroke + fill language used by keys and chips elsewhere in the app.
        val searchIconPx = dpToPx(16f)
        val searchEditText = EditText(context).apply {
            hint = "Search GIFs"
            setHintTextColor(theme.secondaryTextColor)
            setTextColor(theme.textColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13.5f)
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dpToPx(14f).toFloat()
                setColor(theme.keyColor)
                if (theme.keyStrokeColor != 0x00000000) {
                    setStroke(dpToPx(0.75f), theme.keyStrokeColor)
                }
            }
            val searchDrawable = ContextCompat.getDrawable(context, R.drawable.ic_search)?.mutate()?.apply {
                setTint(theme.secondaryTextColor)
                setBounds(0, 0, searchIconPx, searchIconPx)
            }
            setCompoundDrawables(searchDrawable, null, null, null)
            compoundDrawablePadding = dpToPx(8f)
            setPadding(dpToPx(12f), dpToPx(8f), dpToPx(12f), dpToPx(8f))
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                setMargins(0, 0, 0, dpToPx(6f))
            }
        }

        searchEditText.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: Editable?) {
                val query = s?.toString()?.trim() ?: ""
                gifSearchJob?.cancel()
                gifSearchJob = uiScope.launch {
                    delay(SEARCH_DEBOUNCE_MS)
                    fetchGifs(query, isNewSearch = true)
                }
            }
        })
        gifRootLayout.addView(searchEditText)

        // Content Area Container (Grid, Loading, Empty, Error)
        val contentFrame = FrameLayout(context).apply {
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, 0, 1.0f)
        }

        val recyclerView = RecyclerView(context).apply {
            layoutManager = GridLayoutManager(context, 2)
            layoutParams = FrameLayout.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
            clipToPadding = false
            setPadding(0, dpToPx(2f), 0, dpToPx(2f))
        }

        gifAdapter = GifAdapter(gifItemsList) { item ->
            controller.insertGif(item) { result ->
                if (result is GifInsertionResult.UnsupportedEditor) {
                    Toast.makeText(context, "GIF insertion not supported by this app", Toast.LENGTH_SHORT).show()
                }
            }
        }
        recyclerView.adapter = gifAdapter

        val progressBar = ProgressBar(context).apply {
            layoutParams = FrameLayout.LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT, Gravity.CENTER)
            indeterminateTintList = ColorStateList.valueOf(theme.accentColor)
            visibility = View.GONE
        }

        val emptyStateView = createEmptyStateView(
            iconRes = R.drawable.ic_gif,
            title = "No GIFs found",
            subtitle = "Try a different search"
        ).apply {
            visibility = View.GONE
        }

        contentFrame.addView(recyclerView)
        contentFrame.addView(progressBar)
        contentFrame.addView(emptyStateView)

        // Attribution Footer
        val footerTextView = TextView(context).apply {
            text = "Powered by GIPHY"
            setTextColor(theme.secondaryTextColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 10.5f)
            typeface = mediumTypeface
            gravity = Gravity.CENTER
            setPadding(0, dpToPx(4f), 0, dpToPx(2f))
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        }

        gifRootLayout.addView(contentFrame)
        gifRootLayout.addView(footerTextView)

        mainPanelContainer.addView(gifRootLayout)

        // Infinite Scroll Pagination
        recyclerView.addOnScrollListener(object : RecyclerView.OnScrollListener() {
            override fun onScrolled(rv: RecyclerView, dx: Int, dy: Int) {
                super.onScrolled(rv, dx, dy)
                val layoutManager = rv.layoutManager as? GridLayoutManager ?: return
                val totalItemCount = layoutManager.itemCount
                val lastVisible = layoutManager.findLastVisibleItemPosition()

                if (!isGifLoading && hasMoreGifs && lastVisible >= totalItemCount - 4) {
                    fetchGifs(currentGifQuery, isNewSearch = false)
                }
            }
        })

        // Initial Load (Trending)
        fetchGifs("", isNewSearch = true, progressBar = progressBar, emptyStateView = emptyStateView)
    }

    private fun renderResizePanel() {
        val resizeRootLayout = LinearLayout(context).apply {
            orientation = VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, getContentPanelHeightPx())
            setPadding(dpToPx(16f), dpToPx(14f), dpToPx(16f), dpToPx(14f))
        }

        val titleTextView = TextView(context).apply {
            text = "Keyboard height"
            setTextColor(theme.textColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            typeface = mediumTypeface
            gravity = Gravity.CENTER
        }
        resizeRootLayout.addView(titleTextView)

        val currentHeightDp = controller.keyboardHeightRepository.getHeight()

        val heightValueTextView = TextView(context).apply {
            text = "$currentHeightDp dp"
            setTextColor(theme.accentColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
            setTypeface(null, Typeface.BOLD)
            gravity = Gravity.CENTER
            setPadding(0, dpToPx(6f), 0, dpToPx(10f))
        }
        resizeRootLayout.addView(heightValueTextView)

        val seekBar = SeekBar(context).apply {
            max = KeyboardHeightRepository.MAX_HEIGHT_DP - KeyboardHeightRepository.MIN_HEIGHT_DP
            progress = currentHeightDp - KeyboardHeightRepository.MIN_HEIGHT_DP
            progressTintList = ColorStateList.valueOf(theme.accentColor)
            progressBackgroundTintList = ColorStateList.valueOf(theme.specialKeyColor)
            thumbTintList = ColorStateList.valueOf(theme.accentColor)
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                setMargins(dpToPx(12f), dpToPx(4f), dpToPx(12f), dpToPx(8f))
            }
        }

        seekBar.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(sb: SeekBar?, progress: Int, fromUser: Boolean) {
                val newHeightDp = KeyboardHeightRepository.MIN_HEIGHT_DP + progress
                heightValueTextView.text = "$newHeightDp dp"
                if (fromUser) {
                    controller.setKeyboardHeight(newHeightDp)
                }
            }
            override fun onStartTrackingTouch(sb: SeekBar?) {}
            override fun onStopTrackingTouch(sb: SeekBar?) {}
        })
        resizeRootLayout.addView(seekBar)

        val labelsLayout = LinearLayout(context).apply {
            orientation = HORIZONTAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                setMargins(dpToPx(12f), 0, dpToPx(12f), dpToPx(16f))
            }
        }
        val minLabel = TextView(context).apply {
            text = "MIN (${KeyboardHeightRepository.MIN_HEIGHT_DP} dp)"
            setTextColor(theme.secondaryTextColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
            layoutParams = LayoutParams(0, LayoutParams.WRAP_CONTENT, 1.0f)
        }
        val maxLabel = TextView(context).apply {
            text = "MAX (${KeyboardHeightRepository.MAX_HEIGHT_DP} dp)"
            setTextColor(theme.secondaryTextColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
            gravity = Gravity.END
            layoutParams = LayoutParams(0, LayoutParams.WRAP_CONTENT, 1.0f)
        }
        labelsLayout.addView(minLabel)
        labelsLayout.addView(maxLabel)
        resizeRootLayout.addView(labelsLayout)

        // Reset button — same accent-gradient CTA + ghost-press pattern as the
        // enter key and AI command chips, instead of a plain system Button.
        val resetShapeNormal = buildKeyShape(theme.accentColor, isAccent = true)
        val resetShapePressed = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = dpToPx(12f).toFloat()
            setColor(theme.accentColorAlt)
        }
        val resetButton = TextView(context).apply {
            text = "Reset to default"
            setTextColor(theme.chipTextColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13.5f)
            typeface = mediumTypeface
            gravity = Gravity.CENTER
            background = resetShapeNormal
            elevation = dpToPx(1.5f).toFloat()
            setPadding(dpToPx(20f), dpToPx(10f), dpToPx(20f), dpToPx(10f))
            layoutParams = LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT)
            isClickable = true
            isFocusable = true
            setOnTouchListener { v, event ->
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        v.background = resetShapePressed
                        animatePress(v)
                        v.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                    }
                    MotionEvent.ACTION_UP -> {
                        v.background = resetShapeNormal
                        animateRelease(v)
                        v.performClick()
                    }
                    MotionEvent.ACTION_CANCEL -> {
                        v.background = resetShapeNormal
                        animateRelease(v)
                    }
                }
                true
            }
            setOnClickListener {
                val defaultDp = controller.resetKeyboardHeight()
                seekBar.progress = defaultDp - KeyboardHeightRepository.MIN_HEIGHT_DP
                heightValueTextView.text = "$defaultDp dp"
            }
        }
        resizeRootLayout.addView(resetButton)

        mainPanelContainer.addView(resizeRootLayout)
    }

    private fun fetchGifs(
        query: String,
        isNewSearch: Boolean,
        progressBar: ProgressBar? = null,
        emptyStateView: View? = null
    ) {
        if (isGifLoading) return
        isGifLoading = true

        if (isNewSearch) {
            currentGifQuery = query
            currentGifOffset = 0
            hasMoreGifs = true
            gifItemsList.clear()
            gifAdapter?.notifyDataSetChanged()
            progressBar?.visibility = View.VISIBLE
            emptyStateView?.visibility = View.GONE
        }

        uiScope.launch {
            val page = withContext(Dispatchers.IO) {
                if (query.isEmpty()) {
                    controller.gifProvider.getTrending(currentGifOffset, 20)
                } else {
                    controller.gifProvider.searchGifs(query, currentGifOffset, 20)
                }
            }

            progressBar?.visibility = View.GONE

            if (page.items.isNotEmpty()) {
                val startPos = gifItemsList.size
                gifItemsList.addAll(page.items)
                gifAdapter?.notifyItemRangeInserted(startPos, page.items.size)
                currentGifOffset += page.items.size
                hasMoreGifs = currentGifOffset < page.totalCount
            } else if (isNewSearch) {
                emptyStateView?.visibility = View.VISIBLE
            }

            isGifLoading = false
        }
    }

    private inner class GifAdapter(
        private val items: List<GifItem>,
        private val onItemClick: (GifItem) -> Unit
    ) : RecyclerView.Adapter<GifAdapter.GifViewHolder>() {

        inner class GifViewHolder(val view: ImageView) : RecyclerView.ViewHolder(view)

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): GifViewHolder {
            val imageView = ImageView(parent.context).apply {
                scaleType = ImageView.ScaleType.CENTER_CROP
                clipToOutline = true
                background = GradientDrawable().apply {
                    shape = GradientDrawable.RECTANGLE
                    cornerRadius = dpToPx(10f).toFloat()
                    setColor(theme.keyColor)
                }
                layoutParams = ViewGroup.MarginLayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    dpToPx(85f)
                ).apply {
                    setMargins(dpToPx(3f), dpToPx(3f), dpToPx(3f), dpToPx(3f))
                }
            }
            return GifViewHolder(imageView)
        }

        override fun onBindViewHolder(holder: GifViewHolder, position: Int) {
            val item = items[position]
            Glide.with(holder.view.context)
                .asGif()
                .load(item.previewUrl)
                .into(holder.view)

            holder.view.setOnClickListener {
                onItemClick(item)
            }
        }

        override fun getItemCount(): Int = items.size
    }

    private fun createClipboardCardView(text: String, onClick: () -> Unit): FrameLayout {
        val shapeNormal = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = dpToPx(12f).toFloat()
            setColor(theme.keyColor)
            if (theme.keyStrokeColor != 0x00000000) {
                setStroke(dpToPx(0.75f), theme.keyStrokeColor)
            }
        }

        val shapePressed = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = dpToPx(12f).toFloat()
            setColor(theme.keyPressedColor)
        }

        val rowLayout = LinearLayout(context).apply {
            orientation = HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dpToPx(10f), dpToPx(8f), dpToPx(12f), dpToPx(8f))
            layoutParams = FrameLayout.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        }

        val iconBadge = createIconBadge(
            iconRes = R.drawable.ic_clipboard,
            badgeSizeDp = 30f,
            iconSizeDp = 15f,
            tint = theme.secondaryTextColor
        ).apply {
            (layoutParams as LinearLayout.LayoutParams).marginEnd = dpToPx(10f)
        }
        rowLayout.addView(iconBadge)

        val textView = TextView(context).apply {
            this.text = text
            setTextColor(theme.textColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13.5f)
            maxLines = 3
            ellipsize = TextUtils.TruncateAt.END
            layoutParams = LinearLayout.LayoutParams(0, LayoutParams.WRAP_CONTENT, 1.0f)
        }
        rowLayout.addView(textView)

        return FrameLayout(context).apply {
            background = shapeNormal
            elevation = dpToPx(KEY_ELEVATION_DP).toFloat()
            isClickable = true
            isFocusable = true
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                setMargins(0, dpToPx(3f), 0, dpToPx(3f))
            }
            addView(rowLayout)

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

    private fun renderMoreToolsPanel() {
        val toolsContainer = LinearLayout(context).apply {
            orientation = VERTICAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, getContentPanelHeightPx())
            setPadding(dpToPx(8f), dpToPx(8f), dpToPx(8f), dpToPx(6f))
        }

        val items = listOf(
            ToolItemData(R.drawable.ic_emoji, "Emoji") { controller.setMode(KeyboardMode.EMOJI) },
            ToolItemData(R.drawable.ic_clipboard, "Clipboard") { controller.setMode(KeyboardMode.CLIPBOARD) },
            ToolItemData(R.drawable.ic_gif, "GIFs") { controller.setMode(KeyboardMode.GIF) },
            ToolItemData(R.drawable.ic_sticker, "Stickers") { controller.setMode(KeyboardMode.STICKERS) },
            ToolItemData(R.drawable.ic_settings, "Keyboard settings") { controller.openAppSettings() },
            ToolItemData(R.drawable.ic_resize, "Resize keyboard") { controller.setMode(KeyboardMode.RESIZE) }
        )

        val singleRowHeightPx = dpToPx(52f)
        val totalHeightPx = getContentPanelHeightPx()
        val reservedHeightPx = dpToPx(14f + 17f + 12f)
        val availableGridHeightPx = (totalHeightPx - reservedHeightPx).coerceAtLeast(singleRowHeightPx)
        val maxRowsPerPage = (availableGridHeightPx / singleRowHeightPx).coerceAtLeast(1)
        val maxItemsPerPage = maxRowsPerPage * 2
        val totalPages = (items.size + maxItemsPerPage - 1) / maxItemsPerPage

        morePanelPageIndex = morePanelPageIndex.coerceIn(0, totalPages - 1)

        val startIndex = morePanelPageIndex * maxItemsPerPage
        val endIndex = (startIndex + maxItemsPerPage).coerceAtMost(items.size)
        val pageItems = items.subList(startIndex, endIndex)

        for (i in pageItems.indices step 2) {
            val row = LinearLayout(context).apply {
                orientation = HORIZONTAL
                layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, dpToPx(46f)).apply {
                    setMargins(0, dpToPx(3f), 0, dpToPx(3f))
                }
            }

            val item1 = pageItems[i]
            val btn1 = createGboardToolButton(item1.iconRes, item1.label, item1.onClick)
            row.addView(btn1)

            if (i + 1 < pageItems.size) {
                val item2 = pageItems[i + 1]
                val btn2 = createGboardToolButton(item2.iconRes, item2.label, item2.onClick)
                row.addView(btn2)
            }

            toolsContainer.addView(row)
        }

        // Bottom Page Indicator Dots (Dynamic reflecting available pages)
        val indicatorContainer = LinearLayout(context).apply {
            orientation = HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(0, dpToPx(6f), 0, dpToPx(4f))
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        }

        for (p in 0 until totalPages) {
            val dot = View(context).apply {
                val sizePx = dpToPx(7f)
                layoutParams = LayoutParams(sizePx, sizePx).apply {
                    setMargins(dpToPx(4f), 0, dpToPx(4f), 0)
                }
                background = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(if (p == morePanelPageIndex) theme.accentColor else theme.secondaryTextColor)
                }
                if (totalPages > 1) {
                    isClickable = true
                    setOnClickListener {
                        morePanelPageIndex = p
                        renderPanel()
                    }
                }
            }
            indicatorContainer.addView(dot)
        }

        toolsContainer.addView(indicatorContainer)
        mainPanelContainer.addView(toolsContainer)
    }

    private data class ToolItemData(val iconRes: Int, val label: String, val onClick: () -> Unit)

    private fun createGboardToolButton(iconRes: Int, label: String, onClick: () -> Unit): FrameLayout {
        val shapeNormal = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = dpToPx(KEY_CORNER_RADIUS_DP * 1.6f).toFloat()
            setColor(theme.keyColor)
            if (theme.keyStrokeColor != 0x00000000) {
                setStroke(dpToPx(0.75f), theme.keyStrokeColor)
            }
        }

        val shapePressed = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = dpToPx(KEY_CORNER_RADIUS_DP * 1.6f).toFloat()
            setColor(theme.keyPressedColor)
        }

        val container = LinearLayout(context).apply {
            orientation = HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dpToPx(10f), 0, dpToPx(12f), 0)
            layoutParams = FrameLayout.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
        }

        // Icon now sits inside the same rounded-badge container used in the
        // clipboard rows and empty states, rather than a bare tinted glyph —
        // gives every tool entry a consistent "chip + label" shape.
        val iconBadge = createIconBadge(
            iconRes = iconRes,
            badgeSizeDp = 34f,
            iconSizeDp = 18f,
            tint = theme.accentColor
        ).apply {
            (layoutParams as LinearLayout.LayoutParams).marginEnd = dpToPx(12f)
        }
        container.addView(iconBadge)

        val textView = TextView(context).apply {
            text = label
            setTextColor(theme.textColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13.5f)
            typeface = mediumTypeface
            maxLines = 1
            ellipsize = TextUtils.TruncateAt.END
            layoutParams = LinearLayout.LayoutParams(0, LayoutParams.WRAP_CONTENT, 1.0f)
        }
        container.addView(textView)

        return FrameLayout(context).apply {
            background = shapeNormal
            elevation = dpToPx(KEY_ELEVATION_DP).toFloat()
            isClickable = true
            isFocusable = true
            layoutParams = LayoutParams(0, LayoutParams.MATCH_PARENT, 1.0f).apply {
                setMargins(dpToPx(4f), 0, dpToPx(4f), 0)
            }
            addView(container)

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

    /** Suggestion chips (word candidates) are visually neutral — they're options to
     *  pick, not actions to trigger. AI command chips (@fix, @rewrite, ...) get the
     *  accent gradient treatment since they *are* actions. */
    private enum class ChipStyle { SUGGESTION, COMMAND }

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
        val typefaceStyle: Int

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
                typefaceStyle = Typeface.BOLD
            }
            ChipStyle.SUGGESTION -> {
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
                typefaceStyle = if (isEmphasized) Typeface.BOLD else Typeface.NORMAL
            }
        }

        return TextView(context).apply {
            text = label
            setTextColor(textColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12.5f)
            setTypeface(null, typefaceStyle)
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

        val modeToggleKey = createKeyView(if (isSymbolPanel) "ABC" else "123", isSpecial = true, weight = 1.3f) {
            isSymbolPanel = !isSymbolPanel
            renderPanel()
        }
        bottomRow.addView(modeToggleKey)

        val emojiKey = createIconKeyView(
            iconRes = R.drawable.ic_emoji,
            weight = 1.0f,
            contentDescription = "Emoji"
        ) {
            controller.setMode(KeyboardMode.EMOJI)
        }
        bottomRow.addView(emojiKey)

        val atKey = createKeyView("@", isSpecial = true, weight = 1.0f) {
            controller.onKeyTyped("@")
        }
        bottomRow.addView(atKey)

        val spaceKey = createKeyView("English", weight = 3.6f, isSpace = true) {
            controller.onKeyTyped(" ")
        }
        bottomRow.addView(spaceKey)

        val commaKey = createKeyView(",", isSpecial = true, weight = 1.0f) {
            controller.onKeyTyped(",")
        }
        bottomRow.addView(commaKey)

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
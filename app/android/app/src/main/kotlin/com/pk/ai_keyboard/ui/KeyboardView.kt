package com.pk.ai_keyboard.ui

import android.annotation.SuppressLint
import android.content.Context
import android.content.res.Configuration
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
        return if (isLandscape) 36f else 46f
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

    private fun buildUi() {
        removeAllViews()

        // Single horizontal toolbar container
        val toolbarRoot = LinearLayout(context).apply {
            orientation = HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setBackgroundColor(theme.toolbarColor)
            setPadding(dpToPx(8f), dpToPx(4f), dpToPx(8f), dpToPx(4f))
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

        // 2. Suggestion / Dynamic Content Area (Center, 75-80% flexible width)
        toolbarScrollView = HorizontalScrollView(context).apply {
            layoutParams = LayoutParams(0, LayoutParams.WRAP_CONTENT, 1.0f).apply {
                gravity = Gravity.CENTER_VERTICAL
            }
            isHorizontalScrollBarEnabled = false
            overScrollMode = View.OVER_SCROLL_NEVER
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
            setTypeface(null, Typeface.BOLD)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            gravity = Gravity.CENTER_VERTICAL
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

    private fun renderClipboardPanel() {
        val clipboardContainer = LinearLayout(context).apply {
            orientation = VERTICAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, getContentPanelHeightPx())
            setPadding(dpToPx(8f), dpToPx(4f), dpToPx(8f), dpToPx(4f))
        }

        val history = controller.clipboardHistoryManager.getHistory()

        if (history.isEmpty()) {
            val emptyTextView = TextView(context).apply {
                text = "No copied text yet"
                setTextColor(theme.secondaryTextColor)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
                gravity = Gravity.CENTER
                layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
            }
            clipboardContainer.addView(emptyTextView)
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

        // Search Bar
        val searchEditText = EditText(context).apply {
            hint = "Search GIFs..."
            setHintTextColor(theme.secondaryTextColor)
            setTextColor(theme.textColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dpToPx(12f).toFloat()
                setColor(theme.keyColor)
            }
            setPadding(dpToPx(12f), dpToPx(6f), dpToPx(12f), dpToPx(6f))
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                setMargins(0, 0, 0, dpToPx(4f))
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
            visibility = View.GONE
        }

        val emptyTextView = TextView(context).apply {
            text = "No GIFs found"
            setTextColor(theme.secondaryTextColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13.5f)
            gravity = Gravity.CENTER
            layoutParams = FrameLayout.LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT, Gravity.CENTER)
            visibility = View.GONE
        }

        contentFrame.addView(recyclerView)
        contentFrame.addView(progressBar)
        contentFrame.addView(emptyTextView)

        // Attribution Footer
        val footerTextView = TextView(context).apply {
            text = "Powered by GIPHY"
            setTextColor(theme.secondaryTextColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
            setTypeface(null, Typeface.BOLD)
            gravity = Gravity.CENTER
            setPadding(0, dpToPx(2f), 0, dpToPx(2f))
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
        fetchGifs("", isNewSearch = true, progressBar = progressBar, emptyTextView = emptyTextView)
    }

    private fun renderResizePanel() {
        val resizeRootLayout = LinearLayout(context).apply {
            orientation = VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, getContentPanelHeightPx())
            setPadding(dpToPx(16f), dpToPx(12f), dpToPx(16f), dpToPx(12f))
        }

        val titleTextView = TextView(context).apply {
            text = "Keyboard Height"
            setTextColor(theme.textColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            setTypeface(null, Typeface.BOLD)
            gravity = Gravity.CENTER
        }
        resizeRootLayout.addView(titleTextView)

        val currentHeightDp = controller.keyboardHeightRepository.getHeight()

        val heightValueTextView = TextView(context).apply {
            text = "$currentHeightDp dp"
            setTextColor(theme.accentColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
            setTypeface(null, Typeface.BOLD)
            gravity = Gravity.CENTER
            setPadding(0, dpToPx(6f), 0, dpToPx(8f))
        }
        resizeRootLayout.addView(heightValueTextView)

        val seekBar = SeekBar(context).apply {
            max = KeyboardHeightRepository.MAX_HEIGHT_DP - KeyboardHeightRepository.MIN_HEIGHT_DP
            progress = currentHeightDp - KeyboardHeightRepository.MIN_HEIGHT_DP
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
                setMargins(dpToPx(12f), 0, dpToPx(12f), dpToPx(12f))
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

        val resetButton = Button(context).apply {
            text = "Reset to Default"
            isAllCaps = false
            setTextColor(theme.chipTextColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            setTypeface(null, Typeface.BOLD)
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dpToPx(12f).toFloat()
                setColor(theme.accentColor)
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
        emptyTextView: TextView? = null
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
            emptyTextView?.visibility = View.GONE
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
                emptyTextView?.visibility = View.VISIBLE
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
                layoutParams = ViewGroup.MarginLayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    dpToPx(85f)
                ).apply {
                    setMargins(dpToPx(2f), dpToPx(2f), dpToPx(2f), dpToPx(2f))
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

        val textView = TextView(context).apply {
            this.text = text
            setTextColor(theme.textColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13.5f)
            maxLines = 3
            ellipsize = TextUtils.TruncateAt.END
            setPadding(dpToPx(14f), dpToPx(10f), dpToPx(14f), dpToPx(10f))
            layoutParams = FrameLayout.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        }

        return FrameLayout(context).apply {
            background = shapeNormal
            elevation = dpToPx(KEY_ELEVATION_DP).toFloat()
            isClickable = true
            isFocusable = true
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                setMargins(0, dpToPx(3f), 0, dpToPx(3f))
            }
            addView(textView)

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

        val rowHeightPx = dpToPx(getKeyHeightDp() * 1.15f)

        for (i in items.indices step 2) {
            val row = LinearLayout(context).apply {
                orientation = HORIZONTAL
                layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, rowHeightPx).apply {
                    setMargins(0, dpToPx(3f), 0, dpToPx(3f))
                }
            }

            val item1 = items[i]
            val btn1 = createGboardToolButton(item1.iconRes, item1.label, item1.onClick)
            row.addView(btn1)

            if (i + 1 < items.size) {
                val item2 = items[i + 1]
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

        val activeDot = View(context).apply {
            val sizePx = dpToPx(7f)
            layoutParams = LayoutParams(sizePx, sizePx).apply {
                setMargins(dpToPx(4f), 0, dpToPx(4f), 0)
            }
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(theme.textColor)
            }
        }
        indicatorContainer.addView(activeDot)

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
            setPadding(dpToPx(14f), 0, dpToPx(14f), 0)
            layoutParams = FrameLayout.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
        }

        val iconView = ImageView(context).apply {
            setImageDrawable(ContextCompat.getDrawable(context, iconRes)?.mutate()?.apply {
                setTint(theme.textColor)
            })
            scaleType = ImageView.ScaleType.FIT_CENTER
            val iconSizePx = dpToPx(20f)
            layoutParams = LayoutParams(iconSizePx, iconSizePx).apply {
                setMargins(0, 0, dpToPx(10f), 0)
            }
        }
        container.addView(iconView)

        val textView = TextView(context).apply {
            text = label
            setTextColor(theme.textColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13.5f)
            setTypeface(null, Typeface.NORMAL)
            maxLines = 1
            layoutParams = LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT)
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
                    dictationStatusTextView.text = "Starting..."
                    setDictationIcon(R.drawable.ic_sync, theme.textColor, isRotating = true)
                }
                VoiceState.LISTENING -> {
                    dictationStatusTextView.text = "Listening..."
                    setDictationIcon(R.drawable.ic_mic_active, theme.accentColor, isRotating = false)
                }
                VoiceState.SPEAK_NOW -> {
                    dictationStatusTextView.text = "Speak now"
                    setDictationIcon(R.drawable.ic_mic_active, theme.accentColor, isRotating = false)
                }
                VoiceState.PROCESSING -> {
                    dictationStatusTextView.text = "Processing..."
                    setDictationIcon(R.drawable.ic_sync, theme.textColor, isRotating = true)
                }
                VoiceState.MIC_STOPPED -> {
                    dictationStatusTextView.text = "Tip: Mic to dictate"
                    setDictationIcon(R.drawable.ic_mic, theme.textColor, isRotating = false)
                }
                VoiceState.ERROR -> {
                    dictationStatusTextView.text = "Voice error"
                    setDictationIcon(R.drawable.ic_mic, theme.textColor, isRotating = false)
                }
                VoiceState.IDLE -> {
                    dictationStatusTextView.text = "Tip: Mic to dictate"
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
        val sizePx = dpToPx(28f)
        return ImageView(context).apply {
            setImageResource(R.mipmap.ic_launcher)
            scaleType = ImageView.ScaleType.FIT_CENTER
            contentDescription = "App Icon Mode Toggle"
            isClickable = true
            isFocusable = true
            layoutParams = LayoutParams(sizePx, sizePx).apply {
                setMargins(dpToPx(4f), 0, dpToPx(6f), 0)
                gravity = Gravity.CENTER_VERTICAL
            }
            setOnTouchListener { v, event ->
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        animatePress(v)
                        v.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                    }
                    MotionEvent.ACTION_UP -> {
                        animateRelease(v)
                        onClick()
                        v.performClick()
                    }
                    MotionEvent.ACTION_CANCEL -> {
                        animateRelease(v)
                    }
                }
                true
            }
        }
    }

    private fun createToolbarIconButton(
        drawableRes: Int,
        sizeDp: Float = 24f,
        contentDescription: String,
        onClick: () -> Unit
    ): ImageView {
        val sizePx = dpToPx(sizeDp)
        return ImageView(context).apply {
            setImageDrawable(ContextCompat.getDrawable(context, drawableRes)?.mutate()?.apply {
                setTint(theme.textColor)
            })
            scaleType = ImageView.ScaleType.FIT_CENTER
            this.contentDescription = contentDescription
            isClickable = true
            isFocusable = true
            layoutParams = LayoutParams(sizePx, sizePx).apply {
                setMargins(dpToPx(4f), 0, dpToPx(4f), 0)
                gravity = Gravity.CENTER_VERTICAL
            }
            setOnTouchListener { v, event ->
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        animatePress(v)
                        v.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                    }
                    MotionEvent.ACTION_UP -> {
                        animateRelease(v)
                        onClick()
                        v.performClick()
                    }
                    MotionEvent.ACTION_CANCEL -> {
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

    private fun renderSuggestions(result: SuggestionResult) {
        if (!::toolbarContainer.isInitialized || !::controller.isInitialized) return
        if (controller.isAiCommandModeActive || controller.voiceInputController.isDictationModeActive) return

        toolbarContainer.removeAllViews()

        for (candidate in result.candidates) {
            val label = if (candidate.isAutoCorrection) "${candidate.text} ✓" else candidate.text
            val chip = createChipView(label) {
                controller.onSuggestionCandidateClicked(candidate)
            }
            toolbarContainer.addView(chip)
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
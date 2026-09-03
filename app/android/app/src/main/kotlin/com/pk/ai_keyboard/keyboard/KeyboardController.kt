package com.pk.ai_keyboard.keyboard

import android.content.Context
import android.content.Intent
import android.util.Log
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputConnection
import com.pk.ai_keyboard.MainActivity
import com.pk.ai_keyboard.ai.AiFailure
import com.pk.ai_keyboard.ai.AiResult
import com.pk.ai_keyboard.clipboard.ClipboardHistoryManager
import com.pk.ai_keyboard.command.CommandParser
import com.pk.ai_keyboard.command.NativeCommandRegistry
import com.pk.ai_keyboard.gif.*
import com.pk.ai_keyboard.suggestion.AospSuggestionEngine
import com.pk.ai_keyboard.suggestion.SuggestionCandidate
import com.pk.ai_keyboard.suggestion.SuggestionEngine
import com.pk.ai_keyboard.suggestion.SuggestionResult
import com.pk.ai_keyboard.text.TextEditor
import android.os.SystemClock
import com.pk.ai_keyboard.transform.AiTextTransformer
import com.pk.ai_keyboard.voice.VoiceImeHelper
import com.pk.ai_keyboard.voice.VoiceImeSwitcher
import com.pk.ai_keyboard.voice.VoiceInputController
import com.pk.ai_keyboard.voice.VoiceState
import kotlinx.coroutines.*

enum class ShiftState { LOWERCASE, SHIFT_ON, CAPS_LOCK }

class KeyboardController(
    private val context: Context,
    private val textEditor: TextEditor = TextEditor(),
    private val aiTextTransformer: AiTextTransformer = AiTextTransformer(context),
    private val suggestionEngine: SuggestionEngine = com.pk.ai_keyboard.suggestion.aosp.AospSuggestionAdapter(context),
    val voiceInputController: VoiceInputController = VoiceInputController(context),
    val clipboardHistoryManager: ClipboardHistoryManager = ClipboardHistoryManager(context),
    val gifProvider: GifProvider = GiphyGifProvider(),
    val recentGifManager: RecentGifManager = RecentGifManager(context),
    val gifInserter: GifInserter = GifInserter(context),
    val keyboardHeightRepository: KeyboardHeightRepository = KeyboardHeightRepository(context),
    val numberRowRepository: NumberRowRepository = NumberRowRepository(context),
    voiceImeSwitcher: VoiceImeSwitcher? = null,
    val voiceImeHelper: VoiceImeHelper = VoiceImeHelper(context, voiceImeSwitcher)
) {

    companion object {
        private const val TAG = "KeyboardController"
        private const val DOUBLE_TAP_TIMEOUT_MS = 300L
        private const val MIC_TAP_DEBOUNCE_MS = 500L
        const val MAX_TRANSFORMATION_CHARS = 4000
    }

    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var activeJob: Job? = null

    var currentSessionId: Long = 1L
        private set

    var activeRequestContext: TransformationRequestContext? = null
        private set

    var isTransforming = false
        private set

    var currentEditorInfo: EditorInfo? = null
        private set

    var isAiDisabled = false
        private set

    var isSuggestionsDisabled = false
        private set

    var isAiCommandModeActive = false
        private set

    var keyboardMode: KeyboardMode = KeyboardMode.MAIN
        private set

    var shiftState = ShiftState.LOWERCASE
        private set

    private var lastShiftTapTime = 0L
    private var lastMicTapTime = 0L
    private var suggestionSequenceId: Long = 0L

    var onStatusUpdate: ((String) -> Unit)? = null
    var onShiftStateChanged: ((ShiftState) -> Unit)? = null
    var onAiDisabledStateChanged: ((Boolean) -> Unit)? = null
    var onSuggestionsUpdated: ((SuggestionResult) -> Unit)? = null
    var onAiCommandModeToggled: ((Boolean) -> Unit)? = null
    var onKeyboardModeChanged: ((KeyboardMode) -> Unit)? = null
    var onKeyboardHeightChanged: ((Int) -> Unit)? = null
    var onUseNumbersChanged: ((Boolean) -> Unit)? = null
    var onAppIconClicked: (() -> Unit)? = null
    var onMicClicked: (() -> Unit)? = null
    var onMenuClicked: (() -> Unit)? = null

    fun setUseNumbers(enabled: Boolean): Boolean {
        val applied = numberRowRepository.setUseNumbers(enabled)
        onUseNumbersChanged?.invoke(enabled)
        return applied
    }

    init {
        scope.launch(Dispatchers.IO) {
            suggestionEngine.initialize()
        }
        voiceInputController.onTextRecognized = { text ->
            textEditor.commitRecognizedText(text)
            requestSuggestions()
        }
    }

    fun setMode(mode: KeyboardMode) {
        if (keyboardMode != mode) {
            keyboardMode = mode
            Log.d(TAG, "Keyboard mode updated to: $mode")
            onKeyboardModeChanged?.invoke(mode)
        }
    }

    fun resetModeToMain() {
        if (keyboardMode != KeyboardMode.MAIN) {
            setMode(KeyboardMode.MAIN)
        }
    }

    fun setKeyboardHeight(heightDp: Int): Int {
        val applied = keyboardHeightRepository.setHeight(heightDp)
        onKeyboardHeightChanged?.invoke(applied)
        return applied
    }

    fun updateGeometry(widthPx: Int, heightPx: Int, useNumbers: Boolean) {
        if (suggestionEngine is com.pk.ai_keyboard.suggestion.aosp.AospSuggestionAdapter) {
            suggestionEngine.updateGeometry(widthPx, heightPx, useNumbers)
        }
    }

    fun resetKeyboardHeight(): Int {
        val defaultHeight = keyboardHeightRepository.reset()
        onKeyboardHeightChanged?.invoke(defaultHeight)
        return defaultHeight
    }

    fun commitClipboardItem(text: String): Boolean {
        val committed = textEditor.commitClipboardText(text)
        if (committed) {
            setMode(KeyboardMode.MAIN)
        }
        return committed
    }

    fun insertGif(item: GifItem, onResult: (GifInsertionResult) -> Unit) {
        scope.launch {
            val result = gifInserter.insertGif(
                textEditor.getInputConnection(),
                currentEditorInfo,
                item
            )
            if (result is GifInsertionResult.Success) {
                recentGifManager.addRecent(item)
            }
            onResult(result)
        }
    }

    fun handleAppIconTap() {
        if (keyboardMode != KeyboardMode.MAIN) {
            setMode(KeyboardMode.MAIN)
            return
        }
        isAiCommandModeActive = !isAiCommandModeActive
        Log.d(TAG, "App icon tapped. AI Command Mode: $isAiCommandModeActive")
        onAiCommandModeToggled?.invoke(isAiCommandModeActive)
        if (!isAiCommandModeActive) {
            requestSuggestions()
        }
    }

    fun handleMicTap() {
        val now = SystemClock.uptimeMillis()
        if (now - lastMicTapTime < MIC_TAP_DEBOUNCE_MS) {
            Log.d(TAG, "Ignoring rapid mic tap (debounced)")
            return
        }
        lastMicTapTime = now

        Log.d(TAG, "Microphone clicked")
        if (!voiceInputController.isDictationModeActive) {
            startDictation()
        } else if (voiceInputController.currentState == VoiceState.MIC_STOPPED) {
            voiceInputController.restartDictationFromStopped()
        } else {
            voiceInputController.stopMicrophoneKeepDictation()
        }
        onMicClicked?.invoke()
    }

    fun startDictation() {
        if (voiceImeHelper.isVoiceImeAvailable()) {
            val switched = voiceImeHelper.switchToVoiceIme()
            if (switched) {
                Log.i(TAG, "Switch to voice IME succeeded")
                return
            }
            Log.i(TAG, "Falling back to existing dictation: Switch attempt failed or returned false")
        } else {
            Log.i(TAG, "Falling back to existing dictation: No suitable voice-capable IME available")
        }

        startExistingDictation()
    }

    fun startExistingDictation() {
        voiceInputController.startDictationMode()
    }

    fun handleBackFromDictation() {
        Log.d(TAG, "Back button tapped from Dictation Mode")
        voiceInputController.exitDictationMode()
    }

    fun handleMenuTap() {
        Log.d(TAG, "Menu button tapped")
        setMode(KeyboardMode.MORE)
        onMenuClicked?.invoke()
    }

    fun handleCloseMorePanel() {
        Log.d(TAG, "Close button tapped from More Panel")
        setMode(KeyboardMode.MAIN)
    }

    fun onInputConnectionChanged(inputConnection: InputConnection?) {
        textEditor.setInputConnection(inputConnection)
        if (inputConnection != null) {
            requestSuggestions()
        } else {
            onSuggestionsUpdated?.invoke(SuggestionResult())
        }
    }

    fun onEditorInfoChanged(editorInfo: EditorInfo?) {
        this.currentEditorInfo = editorInfo
        val password = TextEditor.isPasswordField(editorInfo)
        val numeric = TextEditor.isNumericField(editorInfo)
        isAiDisabled = password || numeric
        isSuggestionsDisabled = TextEditor.isProtectedField(editorInfo)

        onAiDisabledStateChanged?.invoke(isAiDisabled)
        if (isSuggestionsDisabled) {
            onSuggestionsUpdated?.invoke(SuggestionResult())
        } else {
            requestSuggestions()
        }
    }

    fun invalidateInputContext() {
        currentSessionId++
        activeJob?.cancel()
        activeJob = null
        activeRequestContext = null
        isTransforming = false
        suggestionSequenceId++
        onSuggestionsUpdated?.invoke(SuggestionResult())
        onStatusUpdate?.invoke("✨ AI Keyboard")
    }

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

    fun onShiftPressed() {
        val now = System.currentTimeMillis()
        shiftState = if (now - lastShiftTapTime < DOUBLE_TAP_TIMEOUT_MS) {
            ShiftState.CAPS_LOCK
        } else {
            when (shiftState) {
                ShiftState.LOWERCASE -> ShiftState.SHIFT_ON
                ShiftState.SHIFT_ON -> ShiftState.LOWERCASE
                ShiftState.CAPS_LOCK -> ShiftState.LOWERCASE
            }
        }
        lastShiftTapTime = now
        onShiftStateChanged?.invoke(shiftState)
    }

    fun onCommandButtonClicked(trigger: String) {
        if (isTransforming || isAiDisabled) return

        val selectedText = textEditor.getSelectedText()
        if (selectedText != null) {
            val prompt = NativeCommandRegistry.getPrompt(trigger, emptyMap())
            val statusMsg = NativeCommandRegistry.getStatusMessage(trigger, emptyMap())
            if (prompt != null) {
                executeSelectionTransformation(selectedText, prompt, statusMsg)
            }
            return
        }

        val currentText = textEditor.getTextBeforeCursor(1000)
        val prefixSpace = if (currentText.isNotEmpty() && !currentText.endsWith(" ")) " " else ""
        textEditor.commitText("$prefixSpace$trigger ", 1)
        checkForCommandTrigger()
    }

    fun onTranslateLanguageSelected(langCode: String) {
        if (isTransforming || isAiDisabled) return

        val langName = NativeCommandRegistry.supportedLanguages[langCode] ?: langCode
        val prompt = "Translate the user's text into $langName. Return ONLY the translated text without markdown wrappers, explanations, quotes, or commentary."

        val selectedText = textEditor.getSelectedText()
        if (selectedText != null) {
            executeSelectionTransformation(selectedText, prompt, "Translating to $langName")
            return
        }

        val currentText = textEditor.getTextBeforeCursor(1000)
        val prefixSpace = if (currentText.isNotEmpty() && !currentText.endsWith(" ")) " " else ""
        textEditor.commitText("${prefixSpace}@translate:$langCode ", 1)
        checkForCommandTrigger()
    }

    fun onSuggestionCandidateClicked(candidate: SuggestionCandidate) {
        if (isTransforming || isSuggestionsDisabled) return
        val replaced = textEditor.replaceCurrentWord(candidate.text)
        if (replaced) {
            suggestionEngine.commitSuggestion(candidate.text)
            requestSuggestions()
        }
    }

    fun requestSuggestions() {
        if (isSuggestionsDisabled || isTransforming || isAiCommandModeActive || TextEditor.isProtectedField(currentEditorInfo)) {
            onSuggestionsUpdated?.invoke(SuggestionResult())
            return
        }

        val textBefore = textEditor.getTextBeforeCursor(100)
        val lastWord = textEditor.getCurrentWordBeforeCursor()

        if (lastWord.startsWith("@") || textBefore.trim().startsWith("@")) {
            onSuggestionsUpdated?.invoke(SuggestionResult())
            return
        }

        val currentSeq = ++suggestionSequenceId
        scope.launch {
            val result = withContext(Dispatchers.IO) {
                suggestionEngine.updateInput(typedText = lastWord, sequenceId = currentSeq)
            }
            if (currentSeq == suggestionSequenceId && !isSuggestionsDisabled && !isTransforming && !isAiCommandModeActive) {
                onSuggestionsUpdated?.invoke(result)
            }
        }
    }

    private fun executeSelectionTransformation(selectedText: String, prompt: String, actionName: String) {
        if (selectedText.length > MAX_TRANSFORMATION_CHARS) {
            onStatusUpdate?.invoke("⚠️ Text too long")
            return
        }

        val requestContext = TransformationRequestContext(
            sessionId = currentSessionId,
            submittedText = selectedText,
            isSelectionTransform = true
        )
        activeRequestContext = requestContext
        isTransforming = true
        onStatusUpdate?.invoke(if (actionName.startsWith("✨")) actionName else "✨ $actionName...")
        onSuggestionsUpdated?.invoke(SuggestionResult())

        activeJob = scope.launch {
            try {
                val result = withContext(Dispatchers.IO) {
                    aiTextTransformer.transformText(text = selectedText, prompt = prompt)
                }

                if (requestContext != activeRequestContext || requestContext.sessionId != currentSessionId || !textEditor.hasValidInputConnection()) {
                    Log.w(TAG, "Selection request context invalid or changed. Discarding AI result.")
                    onStatusUpdate?.invoke("✨ AI Keyboard")
                    return@launch
                }

                val currentSelected = textEditor.getSelectedText()
                if (currentSelected != selectedText) {
                    Log.w(TAG, "Selection modified while request in flight. Discarding AI result.")
                    onStatusUpdate?.invoke("✨ AI Keyboard")
                    return@launch
                }

                when (result) {
                    is AiResult.Success -> {
                        val replaced = textEditor.replaceSelectedText(result.data)
                        if (replaced) {
                            onStatusUpdate?.invoke("✨ AI Keyboard")
                        } else {
                            onStatusUpdate?.invoke("⚠️ Replacement failed")
                        }
                    }
                    is AiResult.Failure -> {
                        handleAiFailure(result.failure)
                    }
                }
            } finally {
                isTransforming = false
            }
        }
    }

    fun onBackspacePressed() {
        textEditor.sendBackspace()
        requestSuggestions()
    }

    fun onEnterPressed(editorInfo: EditorInfo?) {
        val action = editorInfo?.imeOptions?.and(EditorInfo.IME_MASK_ACTION)
        when (action) {
            EditorInfo.IME_ACTION_DONE,
            EditorInfo.IME_ACTION_GO,
            EditorInfo.IME_ACTION_NEXT,
            EditorInfo.IME_ACTION_SEARCH,
            EditorInfo.IME_ACTION_SEND -> {
                val performed = if (action != null && action != 0) {
                    textEditor.performEditorAction(action)
                } else false

                if (!performed) {
                    textEditor.sendEnter()
                }
            }
            else -> textEditor.sendEnter()
        }
        checkForCommandTrigger()
        requestSuggestions()
    }

    fun openAppSettings() {
        try {
            val intent = Intent(context, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to launch app settings intent", e)
        }
    }

    fun onDestroy() {
        invalidateInputContext()
        suggestionEngine.close()
        voiceInputController.destroy()
        clipboardHistoryManager.close()
        scope.cancel()
    }

    fun checkForCommandTrigger() {
        if (isTransforming || isAiDisabled) return

        val textBeforeCursor = textEditor.getTextBeforeCursor(1000)
        if (textBeforeCursor.isBlank()) return

        val parsedCommand = CommandParser.parse(context, textBeforeCursor) ?: return

        if (parsedCommand.cleanText.length > MAX_TRANSFORMATION_CHARS) {
            onStatusUpdate?.invoke("⚠️ Text too long")
            return
        }

        val requestContext = TransformationRequestContext(
            sessionId = currentSessionId,
            submittedText = textBeforeCursor,
            isSelectionTransform = false
        )
        activeRequestContext = requestContext
        isTransforming = true
        onStatusUpdate?.invoke(parsedCommand.statusMessage)
        onSuggestionsUpdated?.invoke(SuggestionResult())

        activeJob = scope.launch {
            try {
                val result = withContext(Dispatchers.IO) {
                    aiTextTransformer.transformText(
                        text = parsedCommand.cleanText,
                        prompt = parsedCommand.prompt
                    )
                }

                if (requestContext != activeRequestContext || requestContext.sessionId != currentSessionId || !textEditor.hasValidInputConnection()) {
                    Log.w(TAG, "Trailing command request context invalid or changed. Discarding AI result.")
                    onStatusUpdate?.invoke("✨ AI Keyboard")
                    return@launch
                }

                val currentTextBeforeCursor = textEditor.getTextBeforeCursor(1000)
                if (currentTextBeforeCursor != requestContext.submittedText) {
                    Log.w(TAG, "Context changed while AI request was in flight. Discarding result.")
                    onStatusUpdate?.invoke("✨ AI Keyboard")
                    return@launch
                }

                when (result) {
                    is AiResult.Success -> {
                        val replaced = textEditor.replaceBeforeCursor(
                            charsToDelete = parsedCommand.fullMatchLength,
                            transformedText = result.data
                        )
                        if (replaced) {
                            onStatusUpdate?.invoke("✨ AI Keyboard")
                        } else {
                            onStatusUpdate?.invoke("⚠️ Replacement failed")
                        }
                    }
                    is AiResult.Failure -> {
                        handleAiFailure(result.failure)
                    }
                }
            } finally {
                isTransforming = false
            }
        }
    }

    private suspend fun handleAiFailure(failure: AiFailure) {
        val message = when (failure) {
            is AiFailure.MissingApiKey -> "No API Key"
            is AiFailure.InvalidApiKey -> "Invalid API Key"
            is AiFailure.NetworkError -> "Network Offline"
            is AiFailure.Timeout -> "Request Timeout"
            is AiFailure.HttpError -> when (failure.statusCode) {
                401 -> "Invalid API Key"
                403 -> "Access Denied"
                404 -> "Model Not Found"
                408 -> "Request Timeout"
                429 -> "Rate Limited"
                in 500..599 -> "Provider Error"
                else -> "API Error (${failure.statusCode})"
            }
            else -> "Transformation Error"
        }
        Log.e(TAG, "AI request failed: $message")
        onStatusUpdate?.invoke("⚠️ $message")
        delay(2500)
        onStatusUpdate?.invoke("✨ AI Keyboard")
    }
}

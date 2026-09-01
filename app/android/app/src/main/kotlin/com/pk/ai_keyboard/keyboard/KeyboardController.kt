package com.pk.ai_keyboard.keyboard

import android.content.Context
import android.content.Intent
import android.util.Log
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputConnection
import com.pk.ai_keyboard.MainActivity
import com.pk.ai_keyboard.ai.AiFailure
import com.pk.ai_keyboard.ai.AiResult
import com.pk.ai_keyboard.command.CommandParser
import com.pk.ai_keyboard.text.TextEditor
import com.pk.ai_keyboard.transform.AiTextTransformer
import kotlinx.coroutines.*

enum class ShiftState { LOWERCASE, SHIFT_ON, CAPS_LOCK }

class KeyboardController(
    private val context: Context,
    private val textEditor: TextEditor = TextEditor(),
    private val aiTextTransformer: AiTextTransformer = AiTextTransformer(context)
) {

    companion object {
        private const val TAG = "KeyboardController"
        private const val DOUBLE_TAP_TIMEOUT_MS = 300L
    }

    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    var isTransforming = false
        private set

    var shiftState = ShiftState.LOWERCASE
        private set

    private var lastShiftTapTime = 0L

    var onStatusUpdate: ((String) -> Unit)? = null
    var onShiftStateChanged: ((ShiftState) -> Unit)? = null

    fun onInputConnectionChanged(inputConnection: InputConnection?) {
        textEditor.setInputConnection(inputConnection)
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
        if (isTransforming) return
        val currentText = textEditor.getTextBeforeCursor(1000)
        val prefixSpace = if (currentText.isNotEmpty() && !currentText.endsWith(" ")) " " else ""
        textEditor.commitText("$prefixSpace$trigger ", 1)
        checkForCommandTrigger()
    }

    fun onTranslateLanguageSelected(langCode: String) {
        if (isTransforming) return
        val currentText = textEditor.getTextBeforeCursor(1000)
        val prefixSpace = if (currentText.isNotEmpty() && !currentText.endsWith(" ")) " " else ""
        textEditor.commitText("${prefixSpace}@translate:$langCode ", 1)
        checkForCommandTrigger()
    }

    fun onBackspacePressed() {
        textEditor.sendBackspace()
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
        scope.cancel()
    }

    fun checkForCommandTrigger() {
        if (isTransforming) return

        val textBeforeCursor = textEditor.getTextBeforeCursor(1000)
        if (textBeforeCursor.isBlank()) return

        val parsedCommand = CommandParser.parse(context, textBeforeCursor) ?: return

        isTransforming = true
        onStatusUpdate?.invoke(parsedCommand.statusMessage)
        Log.d(TAG, "Command detected: ${parsedCommand.baseTrigger}")

        val submittedTextBeforeCursor = textBeforeCursor

        scope.launch {
            try {
                val result = withContext(Dispatchers.IO) {
                    aiTextTransformer.transformText(
                        text = parsedCommand.cleanText,
                        prompt = parsedCommand.prompt
                    )
                }

                // Verify input context still matches what was submitted
                val currentTextBeforeCursor = textEditor.getTextBeforeCursor(1000)
                if (currentTextBeforeCursor != submittedTextBeforeCursor) {
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
                            Log.d(TAG, "AI transformation applied successfully")
                            onStatusUpdate?.invoke("✨ AI Keyboard")
                        } else {
                            onStatusUpdate?.invoke("⚠️ Replacement failed")
                        }
                    }
                    is AiResult.Failure -> {
                        val message = when (result.failure) {
                            is AiFailure.MissingApiKey -> "No API Key"
                            is AiFailure.InvalidApiKey -> "Invalid API Key"
                            is AiFailure.NetworkError -> "Network Offline"
                            is AiFailure.Timeout -> "Request Timeout"
                            is AiFailure.HttpError -> "API Error (${result.failure.statusCode})"
                            else -> "Transformation Error"
                        }
                        Log.e(TAG, "AI request failed: $message")
                        onStatusUpdate?.invoke("⚠️ $message")

                        delay(2500)
                        onStatusUpdate?.invoke("✨ AI Keyboard")
                    }
                }
            } finally {
                isTransforming = false
            }
        }
    }
}

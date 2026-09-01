package com.pk.ai_keyboard.keyboard

import android.content.Context
import android.util.Log
import android.view.inputmethod.InputConnection
import com.pk.ai_keyboard.ai.AiFailure
import com.pk.ai_keyboard.ai.AiResult
import com.pk.ai_keyboard.command.CommandParser
import com.pk.ai_keyboard.text.TextEditor
import com.pk.ai_keyboard.transform.AiTextTransformer
import kotlinx.coroutines.*

class KeyboardController(
    private val context: Context,
    private val textEditor: TextEditor = TextEditor(),
    private val aiTextTransformer: AiTextTransformer = AiTextTransformer(context)
) {

    companion object {
        private const val TAG = "KeyboardController"
    }

    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var isTransforming = false

    var onStatusUpdate: ((String) -> Unit)? = null

    fun onInputConnectionChanged(inputConnection: InputConnection?) {
        textEditor.setInputConnection(inputConnection)
    }

    fun onKeyTyped(char: String) {
        textEditor.commitText(char, 1)
        checkForCommandTrigger()
    }

    fun onBackspacePressed() {
        textEditor.sendBackspace()
    }

    fun onEnterPressed() {
        textEditor.sendEnter()
        checkForCommandTrigger()
    }

    fun onDestroy() {
        scope.cancel()
    }

    private fun checkForCommandTrigger() {
        if (isTransforming) return

        val textBeforeCursor = textEditor.getTextBeforeCursor(1000)
        if (textBeforeCursor.isBlank()) return

        val parsedCommand = CommandParser.parse(textBeforeCursor) ?: return

        isTransforming = true
        onStatusUpdate?.invoke("✨ Transforming...")
        Log.d(TAG, "Command detected: ${parsedCommand.trigger}")

        val submittedTextBeforeCursor = textBeforeCursor

        scope.launch {
            val result = withContext(Dispatchers.IO) {
                aiTextTransformer.transformText(
                    trigger = parsedCommand.trigger,
                    text = parsedCommand.cleanText
                )
            }

            // Verify input context still matches what was submitted
            val currentTextBeforeCursor = textEditor.getTextBeforeCursor(1000)
            if (currentTextBeforeCursor != submittedTextBeforeCursor) {
                Log.w(TAG, "Context changed while AI request was in flight. Discarding result.")
                onStatusUpdate?.invoke("✨ AI Keyboard")
                isTransforming = false
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
            isTransforming = false
        }
    }
}

package com.pk.ai_keyboard.keyboard

import android.util.Log
import android.view.inputmethod.InputConnection
import com.pk.ai_keyboard.command.CommandParser
import com.pk.ai_keyboard.text.TextEditor
import com.pk.ai_keyboard.transform.MockTextTransformer
import com.pk.ai_keyboard.transform.TextTransformer

class KeyboardController(
    private val textEditor: TextEditor = TextEditor(),
    private val textTransformer: TextTransformer = MockTextTransformer()
) {

    companion object {
        private const val TAG = "KeyboardController"
    }

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

    private fun checkForCommandTrigger() {
        val textBeforeCursor = textEditor.getTextBeforeCursor(1000)
        if (textBeforeCursor.isBlank()) return

        val parsedCommand = CommandParser.parse(textBeforeCursor) ?: return

        Log.d(TAG, "Command detected: ${parsedCommand.trigger}")

        val transformedText = textTransformer.transform(parsedCommand.trigger, parsedCommand.cleanText)

        if (transformedText != null) {
            val replaced = textEditor.replaceBeforeCursor(
                charsToDelete = parsedCommand.fullMatchLength,
                transformedText = transformedText
            )
            if (replaced) {
                Log.d(TAG, "Transformation completed and text replaced successfully")
            }
        }
    }
}


package com.pk.ai_keyboard.text

import android.view.KeyEvent
import android.view.inputmethod.InputConnection

/**
 * TextEditor encapsulates interactions with Android's [InputConnection].
 * Performs safe text extraction, character insertion, key event sending,
 * and text replacement.
 */
class TextEditor {

    private var inputConnection: InputConnection? = null

    fun setInputConnection(connection: InputConnection?) {
        this.inputConnection = connection
    }

    fun getTextBeforeCursor(length: Int = 1000): String {
        val connection = inputConnection ?: return ""
        val charSequence = connection.getTextBeforeCursor(length, 0)
        return charSequence?.toString() ?: ""
    }

    fun getTextAfterCursor(length: Int = 1000): String {
        val connection = inputConnection ?: return ""
        val charSequence = connection.getTextAfterCursor(length, 0)
        return charSequence?.toString() ?: ""
    }

    fun getSelectedText(): String? {
        val connection = inputConnection ?: return null
        val charSequence = connection.getSelectedText(0)
        return charSequence?.toString()
    }

    fun commitText(text: String, newCursorPosition: Int = 1) {
        inputConnection?.commitText(text, newCursorPosition)
    }

    fun sendBackspace() {
        val connection = inputConnection ?: return
        connection.sendKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_DEL))
        connection.sendKeyEvent(KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_DEL))
    }

    fun sendEnter() {
        val connection = inputConnection ?: return
        connection.sendKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_ENTER))
        connection.sendKeyEvent(KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_ENTER))
    }

    /**
     * Replaces [charsToDelete] before the cursor with [transformedText].
     * Deletes the target text + trigger, then commits transformedText.
     */
    fun replaceBeforeCursor(charsToDelete: Int, transformedText: String): Boolean {
        val connection = inputConnection ?: return false
        if (charsToDelete <= 0) return false

        // 1. Delete original target text + trigger
        connection.deleteSurroundingText(charsToDelete, 0)

        // 2. Commit transformed replacement text with cursor at the end
        connection.commitText(transformedText, 1)
        return true
    }
}


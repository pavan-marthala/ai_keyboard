package com.pk.ai_keyboard.text

import android.text.InputType
import android.view.KeyEvent
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputConnection

class TextEditor {

    private var inputConnection: InputConnection? = null

    fun setInputConnection(connection: InputConnection?) {
        this.inputConnection = connection
    }

    fun hasValidInputConnection(): Boolean = inputConnection != null

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
        return charSequence?.toString()?.takeIf { it.isNotEmpty() }
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

    fun performEditorAction(actionCode: Int): Boolean {
        val connection = inputConnection ?: return false
        return connection.performEditorAction(actionCode)
    }

    fun replaceBeforeCursor(charsToDelete: Int, transformedText: String): Boolean {
        val connection = inputConnection ?: return false
        if (charsToDelete <= 0) return false
        connection.deleteSurroundingText(charsToDelete, 0)
        connection.commitText(transformedText, 1)
        return true
    }

    fun replaceSelectedText(transformedText: String): Boolean {
        val connection = inputConnection ?: return false
        connection.commitText(transformedText, 1)
        return true
    }

    companion object {
        fun isPasswordField(editorInfo: EditorInfo?): Boolean {
            if (editorInfo == null) return false
            val inputType = editorInfo.inputType
            val variation = inputType and InputType.TYPE_MASK_VARIATION
            val clazz = inputType and InputType.TYPE_MASK_CLASS

            return clazz == InputType.TYPE_CLASS_TEXT && (
                variation == InputType.TYPE_TEXT_VARIATION_PASSWORD ||
                variation == InputType.TYPE_TEXT_VARIATION_WEB_PASSWORD ||
                variation == InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD
            )
        }

        fun isNumericField(editorInfo: EditorInfo?): Boolean {
            if (editorInfo == null) return false
            val clazz = editorInfo.inputType and InputType.TYPE_MASK_CLASS
            return clazz == InputType.TYPE_CLASS_NUMBER || clazz == InputType.TYPE_CLASS_PHONE
        }
    }
}

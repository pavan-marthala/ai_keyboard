package com.pk.ai_keyboard.keyboard

import android.inputmethodservice.InputMethodService
import android.view.View
import android.view.inputmethod.EditorInfo
import com.pk.ai_keyboard.ui.KeyboardView

class KeyboardService : InputMethodService() {

    companion object {
        var activeInstance: KeyboardService? = null
            private set
    }

    private lateinit var controller: KeyboardController
    private lateinit var keyboardView: KeyboardView

    override fun onCreate() {
        super.onCreate()
        activeInstance = this
        controller = KeyboardController(applicationContext)
    }

    fun updateUseNumbers(enabled: Boolean) {
        if (::controller.isInitialized) {
            controller.setUseNumbers(enabled)
        }
    }

    override fun onCreateInputView(): View {
        keyboardView = KeyboardView(this)
        keyboardView.init(controller)
        return keyboardView
    }

    override fun onStartInput(attribute: EditorInfo?, restarting: Boolean) {
        super.onStartInput(attribute, restarting)
        controller.invalidateInputContext()
        controller.onEditorInfoChanged(attribute)
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        controller.onInputConnectionChanged(currentInputConnection)
        controller.resetModeToMain()
        controller.onEditorInfoChanged(info)
        if (::keyboardView.isInitialized) {
            keyboardView.updateEditorInfo(info)
        }
    }

    override fun onFinishInputView(finishingInput: Boolean) {
        super.onFinishInputView(finishingInput)
        controller.invalidateInputContext()
    }

    override fun onFinishInput() {
        super.onFinishInput()
        controller.invalidateInputContext()
        controller.onInputConnectionChanged(null)
    }

    override fun onDestroy() {
        super.onDestroy()
        if (activeInstance == this) {
            activeInstance = null
        }
        controller.onDestroy()
    }
}

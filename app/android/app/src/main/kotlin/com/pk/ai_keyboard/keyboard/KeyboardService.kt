package com.pk.ai_keyboard.keyboard

import android.inputmethodservice.InputMethodService
import android.view.View
import android.view.inputmethod.EditorInfo
import com.pk.ai_keyboard.ui.KeyboardView

class KeyboardService : InputMethodService() {

    private lateinit var controller: KeyboardController
    private lateinit var keyboardView: KeyboardView

    override fun onCreate() {
        super.onCreate()
        controller = KeyboardController(applicationContext)
    }

    override fun onCreateInputView(): View {
        keyboardView = KeyboardView(this)
        keyboardView.init(controller)
        return keyboardView
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        controller.onInputConnectionChanged(currentInputConnection)
        if (::keyboardView.isInitialized) {
            keyboardView.updateEditorInfo(info)
        }
    }

    override fun onFinishInput() {
        super.onFinishInput()
        controller.onInputConnectionChanged(null)
    }

    override fun onDestroy() {
        super.onDestroy()
        controller.onDestroy()
    }
}

package com.pk.ai_keyboard.keyboard

import android.inputmethodservice.InputMethodService
import android.view.View
import android.view.inputmethod.EditorInfo
import android.widget.Button
import com.pk.ai_keyboard.R

class KeyboardService : InputMethodService() {

    private val controller = KeyboardController()

    override fun onCreateInputView(): View {
        val view = layoutInflater.inflate(R.layout.keyboard_view, null)
        setupKeyListeners(view)
        return view
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        controller.onInputConnectionChanged(currentInputConnection)
    }

    override fun onFinishInput() {
        super.onFinishInput()
        controller.onInputConnectionChanged(null)
    }

    private fun setupKeyListeners(view: View) {
        val letterButtonIds = listOf(
            R.id.btn_q to "q", R.id.btn_w to "w", R.id.btn_e to "e", R.id.btn_r to "r",
            R.id.btn_t to "t", R.id.btn_y to "y", R.id.btn_u to "u", R.id.btn_i to "i",
            R.id.btn_o to "o", R.id.btn_p to "p", R.id.btn_a to "a", R.id.btn_s to "s",
            R.id.btn_d to "d", R.id.btn_f to "f", R.id.btn_g to "g", R.id.btn_h to "h",
            R.id.btn_j to "j", R.id.btn_k to "k", R.id.btn_l to "l", R.id.btn_z to "z",
            R.id.btn_x to "x", R.id.btn_c to "c", R.id.btn_v to "v", R.id.btn_b to "b",
            R.id.btn_n to "n", R.id.btn_m to "m", R.id.btn_at to "@", R.id.btn_period to "."
        )

        for ((id, char) in letterButtonIds) {
            view.findViewById<Button>(id)?.setOnClickListener {
                controller.onKeyTyped(char)
            }
        }

        view.findViewById<Button>(R.id.btn_space)?.setOnClickListener {
            controller.onKeyTyped(" ")
        }

        view.findViewById<Button>(R.id.btn_delete)?.setOnClickListener {
            controller.onBackspacePressed()
        }

        view.findViewById<Button>(R.id.btn_enter)?.setOnClickListener {
            controller.onEnterPressed()
        }
    }
}


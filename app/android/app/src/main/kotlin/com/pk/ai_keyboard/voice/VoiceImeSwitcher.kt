package com.pk.ai_keyboard.voice

import android.view.inputmethod.InputMethodSubtype

/**
 * Interface allowing components to request switching to another Input Method (IME).
 * Implemented by [com.pk.ai_keyboard.keyboard.KeyboardService].
 */
fun interface VoiceImeSwitcher {
    /**
     * Attempts to switch the active input method to the target [imeId],
     * optionally specifying a target [subtype].
     *
     * @param imeId The component ID of the target IME.
     * @param subtype Optional subtype to switch to (e.g. a voice subtype).
     * @return true if the switch request was dispatched successfully, false otherwise.
     */
    fun switchToVoiceIme(imeId: String, subtype: InputMethodSubtype?): Boolean
}


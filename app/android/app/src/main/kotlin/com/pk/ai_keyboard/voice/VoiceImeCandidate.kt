package com.pk.ai_keyboard.voice

import android.view.inputmethod.InputMethodInfo
import android.view.inputmethod.InputMethodSubtype

/**
 * Represents a discovered, enabled voice-capable input method candidate.
 *
 * @property imeId The component identifier of the IME (e.g. "com.example/.VoiceService").
 * @property packageName The package name of the IME.
 * @property voiceSubtype The selected voice [InputMethodSubtype], or null if none was explicitly declared.
 * @property isDefaultVoiceIme True if this candidate matches the system default voice input method setting.
 * @property isShortcutIme True if returned in [android.view.inputmethod.InputMethodManager.getShortcutInputMethodsAndSubtypes].
 * @property hasVoiceSubtype True if at least one subtype explicitly declares mode="voice".
 * @property isAuxiliary True if the selected subtype is marked as auxiliary.
 * @property priorityScore Deterministic ranking score used for candidate selection.
 * @property imi Optional system [InputMethodInfo] describing the candidate.
 */
data class VoiceImeCandidate(
    val imeId: String,
    val packageName: String,
    val voiceSubtype: InputMethodSubtype? = null,
    val isDefaultVoiceIme: Boolean = false,
    val isShortcutIme: Boolean = false,
    val hasVoiceSubtype: Boolean = false,
    val isAuxiliary: Boolean = false,
    val priorityScore: Int = 0,
    val imi: InputMethodInfo? = null
)

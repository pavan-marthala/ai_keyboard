package com.pk.ai_keyboard.ui

/**
 * Encapsulates the visual definition and alternative-key specification of a keyboard key.
 *
 * Decouples primary [label], visible top-right [hint], and long-press [moreKeysSpec]
 * so that keys (like the Comma key) can have a rich set of More Keys alternatives
 * without displaying a cluttered hint label.
 */
data class KeyDef(
    val label: String,
    val hint: String? = null,
    val moreKeysSpec: String? = null,
    val weight: Float = 1.0f,
    val isSpecial: Boolean = false,
    val isSpace: Boolean = false
)


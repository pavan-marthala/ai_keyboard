package com.pk.atfix.suggestion

data class SuggestionCandidate(
    val text: String,
    val score: Int = 0,
    val isAutoCorrection: Boolean = false,
    val isTypedWord: Boolean = false
)


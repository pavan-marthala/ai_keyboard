package com.pk.ai_keyboard.suggestion

data class SuggestionResult(
    val candidates: List<SuggestionCandidate> = emptyList(),
    val autoCorrection: SuggestionCandidate? = null,
    val sequenceId: Long = 0L
)


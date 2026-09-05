package com.pk.atfix.suggestion

data class SuggestionResult(
    val candidates: List<SuggestionCandidate> = emptyList(),
    val autoCorrection: SuggestionCandidate? = null,
    val sequenceId: Long = 0L
)


package com.pk.ai_keyboard.suggestion

interface SuggestionEngine {
    fun initialize()
    fun updateInput(
        typedText: String,
        previousContext: String = "",
        sequenceId: Long = 0L
    ): SuggestionResult
    fun commitSuggestion(word: String)
    fun learnWord(word: String)
    fun clear()
    fun close()
}


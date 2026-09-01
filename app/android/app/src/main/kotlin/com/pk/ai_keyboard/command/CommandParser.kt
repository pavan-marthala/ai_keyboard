package com.pk.ai_keyboard.command

/**
 * CommandParser identifies valid commands at the end of input text.
 * For Phase 2A, detects `@fix` (or `@fix` followed by space/punctuation).
 * Ignores email addresses (e.g. `user@example.com`) and unknown triggers (`@unknown`, `@john`).
 */
object CommandParser {

    private val supportedTriggers = setOf("@fix")

    /**
     * Parses text before cursor for trailing supported commands.
     * Returns [ParsedCommand] if a valid command is detected at the end of the text; null otherwise.
     */
    fun parse(textBeforeCursor: String): ParsedCommand? {
        if (textBeforeCursor.isBlank()) return null

        // Split by whitespace
        val tokens = textBeforeCursor.split(Regex("\\s+"))
        if (tokens.isEmpty()) return null

        val lastTokenIndex = if (tokens.last().isEmpty() && tokens.size > 1) tokens.size - 2 else tokens.size - 1
        val lastToken = tokens[lastTokenIndex]

        if (!lastToken.startsWith("@")) return null

        // Ensure it's not an email address like user@domain.com
        if (lastToken.contains(".") && !lastToken.startsWith("@")) return null

        // Strip trailing punctuation attached to trigger
        val cleanTrigger = lastToken.replace(Regex("[.,!?]+$"), "").lowercase()

        if (cleanTrigger in supportedTriggers) {
            val precedingTokens = tokens.take(lastTokenIndex)
            val cleanText = precedingTokens.joinToString(" ").trim()
            val fullMatchLength = textBeforeCursor.length

            return ParsedCommand(
                cleanText = cleanText,
                trigger = cleanTrigger,
                fullMatchLength = fullMatchLength
            )
        }

        return null
    }
}


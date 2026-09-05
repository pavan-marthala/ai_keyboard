package com.pk.atfix.command

import android.content.Context

object CommandParser {

    /**
     * Parses text before cursor for trailing supported commands.
     * Returns [ParsedCommand] if a valid enabled command is detected at the end of the text; null otherwise.
     */
    fun parse(context: Context, textBeforeCursor: String): ParsedCommand? {
        if (textBeforeCursor.isBlank()) return null

        val trimmedInput = textBeforeCursor.trimEnd()
        val tokens = trimmedInput.split(Regex("\\s+"))
        if (tokens.isEmpty()) return null

        val lastToken = tokens.last()
        if (!lastToken.startsWith("@")) return null

        // Email or URL false positive prevention
        if (lastToken.contains("://")) return null

        val cleanLastToken = lastToken.replace(Regex("[.,!?]+$"), "").lowercase()
        var baseTrigger = cleanLastToken
        val arguments = mutableMapOf<String, String>()

        if (cleanLastToken.contains(":")) {
            val parts = cleanLastToken.split(":")
            baseTrigger = parts[0]
            if (parts.size > 1) {
                arguments["language"] = parts[1].lowercase()
            }
        }

        // Check if trigger is enabled
        if (!NativeCommandRegistry.isCommandEnabled(context, baseTrigger)) {
            return null
        }

        val prompt = NativeCommandRegistry.getPrompt(baseTrigger, arguments) ?: return null
        val statusMessage = NativeCommandRegistry.getStatusMessage(baseTrigger, arguments)

        val precedingTokens = tokens.take(tokens.size - 1)
        val cleanText = precedingTokens.joinToString(" ").trim()
        if (cleanText.isEmpty()) return null

        return ParsedCommand(
            cleanText = cleanText,
            rawTrigger = cleanLastToken,
            baseTrigger = baseTrigger,
            prompt = prompt,
            statusMessage = statusMessage,
            fullMatchLength = textBeforeCursor.length,
            arguments = arguments
        )
    }
}

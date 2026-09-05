package com.pk.atfix.command

import android.content.Context

object NativeCommandRegistry {

    private const val PREFS_NAME = "atfix_commands_prefs"
    private const val DISABLED_COMMANDS_KEY = "disabled_commands"

    val supportedLanguages = mapOf(
        "en" to "English",
        "es" to "Spanish",
        "fr" to "French",
        "de" to "German",
        "it" to "Italian",
        "pt" to "Portuguese",
        "hi" to "Hindi",
        "te" to "Telugu",
        "kn" to "Kannada",
        "ta" to "Tamil"
    )

    private const val FIX_PROMPT = """You are a text transformation engine inside a keyboard application.

Correct the user's text.

Rules:
- Return ONLY the corrected text.
- Do not explain changes.
- Do not answer questions.
- Do not add information.
- Preserve the original meaning.
- Fix grammar, spelling, punctuation, capitalization, and obvious sentence-formation errors.
- If the text is already correct, return it unchanged.
- If the text is unclear, incomplete, slang, a name, a technical term, or random text, preserve it rather than asking questions.
- Never mention being an AI or assistant.
- Do not add notes, explanations, disclaimers, or commentary.
- Do not wrap the result in quotation marks.
- Preserve URLs, usernames, hashtags, numbers, emojis, and intentional formatting.

Return exactly one transformed text."""

    private const val REWRITE_PROMPT = """Rewrite the user's text while preserving its original meaning.

Return ONLY the rewritten text.

Do not:
- explain the rewrite
- answer questions
- add information
- add introductions or conclusions
- mention AI
- use quotation marks around the result

Preserve important names, numbers, URLs, usernames, and factual information."""

    private const val PRO_PROMPT = """Rewrite the user's text in a clear, professional tone.

Return ONLY the transformed text.

Preserve the original meaning and facts.
Do not invent information.
Do not explain the changes.
Do not answer questions.
Do not add commentary.
Do not mention AI.
Do not wrap the result in quotation marks."""

    private const val CASUAL_PROMPT = """Rewrite the user's text in a natural, friendly, conversational tone.

Return ONLY the transformed text.

Preserve the original meaning.
Do not add information.
Do not explain the changes.
Do not answer questions.
Do not mention AI.
Do not wrap the result in quotation marks."""

    private const val SHORT_PROMPT = """Make the user's text shorter and more concise while preserving its meaning.

Return ONLY the shortened text.

Do not remove important information.
Do not add information.
Do not explain what was changed.
Do not answer questions.
Do not mention AI.
Do not wrap the result in quotation marks."""

    private const val EXPAND_PROMPT = """Expand the user's text to make it clearer and more complete while preserving its original meaning.

Do not invent facts or specific details that were not provided.

Return ONLY the expanded text.

Do not explain the changes.
Do not answer questions.
Do not mention AI.
Do not wrap the result in quotation marks."""

    fun saveDisabledCommands(context: Context, disabledTriggers: Set<String>) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putStringSet(DISABLED_COMMANDS_KEY, disabledTriggers.map { it.lowercase() }.toSet()).apply()
    }

    fun isCommandEnabled(context: Context, trigger: String): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val disabled = prefs.getStringSet(DISABLED_COMMANDS_KEY, emptySet()) ?: emptySet()
        return !disabled.contains(trigger.lowercase())
    }

    fun getPrompt(baseTrigger: String, args: Map<String, String>): String? {
        return when (baseTrigger.lowercase()) {
            "@fix" -> FIX_PROMPT
            "@rewrite" -> REWRITE_PROMPT
            "@pro" -> PRO_PROMPT
            "@casual" -> CASUAL_PROMPT
            "@short" -> SHORT_PROMPT
            "@expand" -> EXPAND_PROMPT
            "@translate" -> {
                val langCode = args["language"]?.lowercase() ?: ""
                val langName = supportedLanguages[langCode] ?: return null
                """Translate the user's text into $langName.

Return ONLY the translated text.

Rules:
- Do not explain the translation.
- Do not answer questions contained in the text.
- Do not add information that was not in the original text.
- Do not mention AI or being an assistant.
- Do not wrap the result in quotation marks.
- Preserve URLs, usernames, numbers, and emojis.

Return exactly one translated result."""
            }
            else -> null
        }
    }

    fun getStatusMessage(baseTrigger: String, args: Map<String, String>): String {
        return when (baseTrigger.lowercase()) {
            "@fix" -> "✨ Fixing..."
            "@rewrite" -> "✨ Rewriting..."
            "@pro" -> "✨ Making professional..."
            "@casual" -> "✨ Making casual..."
            "@short" -> "✨ Shortening..."
            "@expand" -> "✨ Expanding..."
            "@translate" -> {
                val langCode = args["language"]?.lowercase() ?: ""
                val langName = supportedLanguages[langCode] ?: "language"
                "✨ Translating to $langName..."
            }
            else -> "✨ Transforming..."
        }
    }
}


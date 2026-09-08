package com.pk.atfix.command

import android.content.Context
import com.pk.atfix.ai.CommandDefinition
import com.pk.atfix.ai.PromptRepository

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

    fun saveDisabledCommands(context: Context, disabledTriggers: Set<String>) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putStringSet(DISABLED_COMMANDS_KEY, disabledTriggers.map { it.lowercase() }.toSet()).apply()
    }

    fun isCommandEnabled(context: Context, trigger: String): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val disabled = prefs.getStringSet(DISABLED_COMMANDS_KEY, emptySet()) ?: emptySet()
        return !disabled.contains(trigger.lowercase())
    }

    fun getCommands(context: Context? = null): List<CommandDefinition> {
        val repo = context?.let { PromptRepository.getInstance(it) }
            ?: PromptRepository.getInstanceOrNull()
            ?: return emptyList()
        return repo.getCommands()
    }

    fun getPrompt(context: Context, baseTrigger: String, args: Map<String, String>): String? {
        val repo = PromptRepository.getInstance(context)
        return resolvePrompt(repo, baseTrigger, args)
    }

    fun getPrompt(baseTrigger: String, args: Map<String, String>, context: Context? = null): String? {
        val repo = context?.let { PromptRepository.getInstance(it) }
            ?: PromptRepository.getInstanceOrNull()
            ?: return null
        return resolvePrompt(repo, baseTrigger, args)
    }

    private fun resolvePrompt(repo: PromptRepository, baseTrigger: String, args: Map<String, String>): String? {
        val clean = baseTrigger.lowercase().trim()
        if (clean == "@pro" || clean == "pro") return null

        val cmd = repo.getCommand(clean) ?: return null
        return try {
            if (cmd.id == "translate") {
                val langCode = args["language"]?.lowercase() ?: ""
                val langName = supportedLanguages[langCode] ?: return null
                repo.getPrompt(cmd.id, mapOf("language" to langName))
            } else {
                repo.getPrompt(cmd.id)
            }
        } catch (e: Exception) {
            null
        }
    }

    fun getStatusMessage(baseTrigger: String, args: Map<String, String>, context: Context? = null): String {
        val clean = baseTrigger.lowercase().trim()
        if (clean == "@pro" || clean == "pro") return "✨ Transforming..."

        val repo = context?.let { PromptRepository.getInstance(it) } ?: PromptRepository.getInstanceOrNull()
        val cmd = repo?.getCommand(clean)

        if (cmd?.id == "translate") {
            val langCode = args["language"]?.lowercase() ?: ""
            val langName = supportedLanguages[langCode] ?: "language"
            return "✨ Translating to $langName..."
        }

        val label = cmd?.actionLabel ?: "Transforming..."
        return "✨ $label"
    }
}

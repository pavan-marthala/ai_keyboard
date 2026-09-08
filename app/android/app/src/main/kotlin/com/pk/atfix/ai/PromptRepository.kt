package com.pk.atfix.ai

import android.content.Context
import com.pk.atfix.generated.GeneratedCommandDefinition
import com.pk.atfix.generated.GeneratedCommandDefinitions

typealias CommandDefinition = GeneratedCommandDefinition

/**
 * Repository responsible for loading and resolving canonical AI commands and prompts
 * from generated command definitions.
 */
class PromptRepository(
    definitions: List<GeneratedCommandDefinition> = GeneratedCommandDefinitions.commands
) {
    private val prompts = mutableMapOf<String, String>()
    private val commandDefinitions = mutableListOf<CommandDefinition>()
    private val commandsById = mutableMapOf<String, CommandDefinition>()
    private val commandsByTrigger = mutableMapOf<String, CommandDefinition>()

    init {
        loadDefinitions(definitions)
    }

    private fun loadDefinitions(definitions: List<GeneratedCommandDefinition>) {
        commandDefinitions.clear()
        commandsById.clear()
        commandsByTrigger.clear()
        prompts.clear()

        val sorted = definitions.sortedBy { it.order }
        for (def in sorted) {
            commandDefinitions.add(def)
            commandsById[def.id.lowercase()] = def
            commandsByTrigger[def.command.lowercase()] = def
            prompts[def.id.lowercase()] = def.system
        }
    }

    fun getCommands(): List<CommandDefinition> = commandDefinitions.toList()

    fun getCommand(triggerOrId: String): CommandDefinition? {
        val clean = triggerOrId.trim().lowercase()
        val base = if (clean.contains(":")) clean.split(":")[0] else clean
        return commandsByTrigger[base] ?: commandsById[base]
    }

    fun getActionLabel(triggerOrId: String): String {
        return getCommand(triggerOrId)?.actionLabel ?: "Transforming..."
    }

    /**
     * Resolves the system prompt for [key], interpolating any variables matching `{{variableName}}`.
     *
     * @throws IllegalArgumentException if [key] is not found in prompts.
     */
    fun getPrompt(key: String, variables: Map<String, String> = emptyMap()): String {
        val cleanKey = key.trim().lowercase()
        val template = prompts[cleanKey]
            ?: commandsByTrigger[cleanKey]?.system
            ?: throw IllegalArgumentException("Unknown prompt key: $key")

        var result = template
        for ((varName, varValue) in variables) {
            result = result.replace("{{$varName}}", varValue)
        }
        return result
    }

    fun hasPrompt(key: String): Boolean = prompts.containsKey(key.trim().lowercase()) || commandsByTrigger.containsKey(key.trim().lowercase())

    companion object {
        @Volatile
        private var instance: PromptRepository? = null

        fun getInstance(context: Context? = null): PromptRepository {
            return instance ?: synchronized(this) {
                instance ?: PromptRepository().also { instance = it }
            }
        }

        fun getInstanceOrNull(): PromptRepository? = instance ?: synchronized(this) {
            instance ?: PromptRepository().also { instance = it }
        }

        fun setInstance(repository: PromptRepository?) {
            instance = repository
        }

        fun resetInstance() {
            instance = null
        }
    }
}


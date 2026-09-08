package com.pk.atfix.ai

import android.content.Context
import org.json.JSONException
import org.json.JSONObject
import java.io.IOException
import java.io.InputStream

data class CommandDefinition(
    val id: String,
    val command: String,
    val label: String,
    val actionLabel: String,
    val order: Int,
    val requiresInput: Boolean,
    val inputType: String?,
    val system: String
)

/**
 * Repository responsible for loading and resolving canonical AI commands and prompts
 * from the shared `ai_prompts.json` asset.
 */
class PromptRepository(
    jsonContent: String
) {
    private val prompts = mutableMapOf<String, String>()
    private val commandDefinitions = mutableListOf<CommandDefinition>()
    private val commandsById = mutableMapOf<String, CommandDefinition>()
    private val commandsByTrigger = mutableMapOf<String, CommandDefinition>()

    init {
        loadJson(jsonContent)
    }

    private fun loadJson(content: String) {
        val root = JSONObject(content)
        if (root.has("commands")) {
            val commandsObj = root.getJSONObject("commands")
            val keys = commandsObj.keys()
            val parsedList = mutableListOf<CommandDefinition>()
            val seenIds = mutableSetOf<String>()
            val seenTriggers = mutableSetOf<String>()

            while (keys.hasNext()) {
                val key = keys.next().trim().lowercase()
                if (key.isEmpty()) {
                    throw JSONException("Command key cannot be empty")
                }
                if (key == "pro" || key == "@pro") {
                    throw IllegalArgumentException("@pro is deprecated and not supported")
                }

                val cmdObj = commandsObj.getJSONObject(key)
                val rawCommand = cmdObj.getString("command").trim()
                if (!rawCommand.startsWith("@")) {
                    throw JSONException("Command syntax must start with '@': $rawCommand")
                }
                if (rawCommand.lowercase() == "@pro") {
                    throw IllegalArgumentException("@pro is deprecated and not supported")
                }

                val label = cmdObj.getString("label").trim()
                val actionLabel = cmdObj.getString("actionLabel").trim()
                val order = cmdObj.getInt("order")
                val requiresInput = cmdObj.optBoolean("requiresInput", false)
                val inputType = if (cmdObj.isNull("inputType")) null else cmdObj.getString("inputType").trim()
                val system = cmdObj.getString("system").trim()

                if (label.isEmpty() || actionLabel.isEmpty() || system.isEmpty()) {
                    throw JSONException("Fields label, actionLabel, and system cannot be empty for command $key")
                }
                if (order <= 0) {
                    throw JSONException("Command order must be positive for command $key")
                }
                if (requiresInput && inputType.isNullOrEmpty()) {
                    throw JSONException("Command $key requires input but inputType is null or empty")
                }

                if (!seenIds.add(key)) {
                    throw JSONException("Duplicate command id: $key")
                }
                if (!seenTriggers.add(rawCommand.lowercase())) {
                    throw JSONException("Duplicate command trigger: $rawCommand")
                }

                val def = CommandDefinition(
                    id = key,
                    command = rawCommand,
                    label = label,
                    actionLabel = actionLabel,
                    order = order,
                    requiresInput = requiresInput,
                    inputType = inputType,
                    system = cmdObj.getString("system")
                )
                parsedList.add(def)
            }

            if (!seenIds.contains("professional") || !seenTriggers.contains("@professional")) {
                throw JSONException("Missing required canonical command @professional")
            }

            parsedList.sortBy { it.order }

            commandDefinitions.clear()
            commandsById.clear()
            commandsByTrigger.clear()
            prompts.clear()

            for (def in parsedList) {
                commandDefinitions.add(def)
                commandsById[def.id] = def
                commandsByTrigger[def.command.lowercase()] = def
                prompts[def.id] = def.system
            }
        } else if (root.has("prompts")) {
            // Legacy schema v1 fallback
            val promptsObj = root.getJSONObject("prompts")
            val keys = promptsObj.keys()
            while (keys.hasNext()) {
                val key = keys.next()
                val promptEntry = promptsObj.getJSONObject(key)
                if (promptEntry.has("system")) {
                    prompts[key] = promptEntry.getString("system")
                }
            }
        } else {
            throw JSONException("Root object missing 'commands' or 'prompts' key")
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
        const val ASSET_PATH = "prompts/ai_prompts.json"

        @Volatile
        private var instance: PromptRepository? = null

        fun getInstance(context: Context): PromptRepository {
            return instance ?: synchronized(this) {
                instance ?: loadFromAssets(context.applicationContext).also { instance = it }
            }
        }

        fun getInstanceOrNull(): PromptRepository? = instance

        @Throws(IOException::class, JSONException::class)
        fun loadFromAssets(context: Context, assetPath: String = ASSET_PATH): PromptRepository {
            val inputStream: InputStream = context.assets.open(assetPath)
            val content = inputStream.bufferedReader().use { it.readText() }
            return PromptRepository(content)
        }

        fun fromJson(jsonContent: String): PromptRepository {
            return PromptRepository(jsonContent)
        }

        fun setInstance(repository: PromptRepository?) {
            instance = repository
        }

        fun resetInstance() {
            instance = null
        }
    }
}

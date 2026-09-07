package com.pk.atfix.ai

import android.content.Context
import org.json.JSONException
import org.json.JSONObject
import java.io.IOException
import java.io.InputStream

/**
 * Repository responsible for loading and resolving canonical AI prompts
 * from the shared `ai_prompts.json` asset.
 */
class PromptRepository(
    jsonContent: String
) {
    private val prompts = mutableMapOf<String, String>()

    init {
        loadJson(jsonContent)
    }

    private fun loadJson(content: String) {
        val root = JSONObject(content)
        if (!root.has("prompts")) {
            throw JSONException("Root object missing 'prompts' key")
        }
        val promptsObj = root.getJSONObject("prompts")
        val keys = promptsObj.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            val promptEntry = promptsObj.getJSONObject(key)
            if (promptEntry.has("system")) {
                prompts[key] = promptEntry.getString("system")
            }
        }
    }

    /**
     * Resolves the system prompt for [key], interpolating any variables matching `{{variableName}}`.
     *
     * @throws IllegalArgumentException if [key] is not found in prompts.
     */
    fun getPrompt(key: String, variables: Map<String, String> = emptyMap()): String {
        val template = prompts[key]
            ?: throw IllegalArgumentException("Unknown prompt key: $key")

        var result = template
        for ((varName, varValue) in variables) {
            result = result.replace("{{$varName}}", varValue)
        }
        return result
    }

    fun hasPrompt(key: String): Boolean = prompts.containsKey(key)

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


package com.pk.ai_keyboard.transform

import android.content.Context
import com.pk.ai_keyboard.ai.AiFailure
import com.pk.ai_keyboard.ai.AiProviderFactory
import com.pk.ai_keyboard.ai.AiResult
import com.pk.ai_keyboard.config.NativeSecureStorage

class AiTextTransformer(private val context: Context) {

    private val defaultPrompt =
        "You are a text transformation assistant. Fix grammar, spelling, punctuation, and obvious sentence-formation issues. Preserve original meaning. Return ONLY the corrected text without quotation marks or extra explanations."

    suspend fun transformText(trigger: String, text: String): AiResult<String> {
        val config = NativeSecureStorage.getConfig(context)
            ?: return AiResult.Failure(AiFailure.MissingApiKey)

        val provider = AiProviderFactory.getProvider(config.provider)
        return provider.transform(
            text = text,
            prompt = defaultPrompt,
            model = config.model,
            apiKey = config.apiKey,
            baseUrl = config.baseUrl
        )
    }
}


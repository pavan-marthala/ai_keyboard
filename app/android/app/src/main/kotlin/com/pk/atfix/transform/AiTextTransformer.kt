package com.pk.atfix.transform

import android.content.Context
import com.pk.atfix.ai.AiFailure
import com.pk.atfix.ai.AiProviderFactory
import com.pk.atfix.ai.AiResult
import com.pk.atfix.config.NativeSecureStorage

class AiTextTransformer(private val context: Context) {

    suspend fun transformText(text: String, prompt: String): AiResult<String> {
        val config = NativeSecureStorage.getConfig(context)
            ?: return AiResult.Failure(AiFailure.MissingApiKey)

        val provider = AiProviderFactory.getProvider(config.provider)
        return provider.transform(
            text = text,
            prompt = prompt,
            model = config.model,
            apiKey = config.apiKey,
            baseUrl = config.baseUrl
        )
    }
}

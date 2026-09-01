package com.pk.ai_keyboard.ai

interface AiProvider {
    suspend fun transform(
        text: String,
        prompt: String,
        model: String,
        apiKey: String,
        baseUrl: String? = null
    ): AiResult<String>
}


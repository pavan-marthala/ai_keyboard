package com.pk.ai_keyboard.ai

class GroqProvider : OpenAiProvider() {
    override suspend fun transform(
        text: String,
        prompt: String,
        model: String,
        apiKey: String,
        baseUrl: String?
    ): AiResult<String> {
        val endpoint = if (!baseUrl.isNullOrBlank()) baseUrl else "https://api.groq.com/openai/v1/chat/completions"
        val modelId = if (model.isBlank()) "llama-3.3-70b-versatile" else model
        return super.transform(text, prompt, modelId, apiKey, endpoint)
    }
}


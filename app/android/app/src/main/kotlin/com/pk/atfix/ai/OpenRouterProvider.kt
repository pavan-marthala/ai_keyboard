package com.pk.atfix.ai

class OpenRouterProvider : OpenAiProvider() {
    override suspend fun transform(
        text: String,
        prompt: String,
        model: String,
        apiKey: String,
        baseUrl: String?
    ): AiResult<String> {
        val endpoint = if (!baseUrl.isNullOrBlank()) baseUrl else "https://openrouter.ai/api/v1/chat/completions"
        val modelId = if (model.isBlank()) "openai/gpt-4o-mini" else model
        return super.transform(text, prompt, modelId, apiKey, endpoint)
    }
}


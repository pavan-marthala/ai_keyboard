package com.pk.atfix.ai

object AiProviderFactory {
    fun getProvider(providerName: String): AiProvider {
        return when (providerName.lowercase()) {
            "openai" -> OpenAiProvider()
            "gemini" -> GeminiProvider()
            "openrouter" -> OpenRouterProvider()
            "groq" -> GroqProvider()
            else -> OpenAiProvider()
        }
    }
}

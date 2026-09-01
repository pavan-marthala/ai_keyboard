package com.pk.ai_keyboard.ai

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

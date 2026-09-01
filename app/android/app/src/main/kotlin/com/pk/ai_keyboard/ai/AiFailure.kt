package com.pk.ai_keyboard.ai

sealed class AiFailure {
    object MissingApiKey : AiFailure()
    object InvalidApiKey : AiFailure()
    object NetworkError : AiFailure()
    object Timeout : AiFailure()
    data class HttpError(val statusCode: Int, val message: String) : AiFailure()
    object InvalidResponse : AiFailure()
    object ContextChanged : AiFailure()
}


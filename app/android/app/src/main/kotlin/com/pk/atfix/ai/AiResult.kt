package com.pk.atfix.ai

sealed class AiResult<out T> {
    data class Success<out T>(val data: T) : AiResult<T>()
    data class Failure(val failure: AiFailure) : AiResult<Nothing>()
}


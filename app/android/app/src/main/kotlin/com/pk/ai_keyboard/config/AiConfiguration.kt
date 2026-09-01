package com.pk.ai_keyboard.config

data class AiConfiguration(
    val provider: String,
    val apiKey: String,
    val model: String,
    val baseUrl: String? = null
)


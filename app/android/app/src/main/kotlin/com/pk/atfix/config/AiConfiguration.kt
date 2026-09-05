package com.pk.atfix.config

data class AiConfiguration(
    val provider: String,
    val apiKey: String,
    val model: String,
    val baseUrl: String? = null
)


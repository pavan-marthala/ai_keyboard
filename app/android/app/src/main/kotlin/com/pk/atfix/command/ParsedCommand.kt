package com.pk.atfix.command

data class ParsedCommand(
    val cleanText: String,
    val rawTrigger: String,
    val baseTrigger: String,
    val prompt: String,
    val statusMessage: String,
    val fullMatchLength: Int,
    val arguments: Map<String, String> = emptyMap()
)

package com.pk.ai_keyboard.command

data class ParsedCommand(
    val cleanText: String,
    val trigger: String,
    val fullMatchLength: Int
)


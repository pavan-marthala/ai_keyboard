package com.pk.ai_keyboard.transform

interface TextTransformer {
    fun transform(trigger: String, text: String): String?
}


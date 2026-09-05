package com.pk.atfix.transform

interface TextTransformer {
    fun transform(trigger: String, text: String): String?
}


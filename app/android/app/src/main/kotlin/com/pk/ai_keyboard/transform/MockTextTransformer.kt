package com.pk.ai_keyboard.transform

/**
 * MockTextTransformer provides deterministic local mock transformations for `@fix`.
 * Used for Phase 2A architecture validation.
 */
class MockTextTransformer : TextTransformer {

    private val presetTransformations = mapOf(
        "i am going office tomorrow" to "I am going to the office tomorrow.",
        "i am going office" to "I am going to the office.",
        "hello" to "Hello.",
        "this is broken text" to "This is corrected text."
    )

    override fun transform(trigger: String, text: String): String? {
        if (trigger.lowercase() != "@fix") return null
        if (text.isBlank()) return "Corrected text."

        val lowercaseInput = text.trim().lowercase()

        // 1. Check preset mock match
        presetTransformations[lowercaseInput]?.let { return it }

        // 2. Fallback heuristic: capitalize first letter & append period if missing
        val capitalized = text.trim().replaceFirstChar { if (it.isLowerCase()) it.titlecase() else it.toString() }
        return if (capitalized.endsWith(".") || capitalized.endsWith("!") || capitalized.endsWith("?")) {
            capitalized
        } else {
            "$capitalized."
        }
    }
}


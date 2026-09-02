package com.pk.ai_keyboard.suggestion

import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

class SuggestionEngineTest {

    private lateinit var engine: AospSuggestionEngine

    @Before
    fun setUp() {
        engine = AospSuggestionEngine(null)
        engine.initialize()
    }

    @Test
    fun `updateInput with empty string returns empty result`() {
        val result = engine.updateInput("")
        assertTrue(result.candidates.isEmpty())
        assertNull(result.autoCorrection)
    }

    @Test
    fun `updateInput with hel prefix returns hello and help candidates`() {
        val result = engine.updateInput("hel")
        assertFalse(result.candidates.isEmpty())
        val texts = result.candidates.map { it.text.lowercase() }
        assertTrue(texts.contains("hello") || texts.contains("help"))
    }

    @Test
    fun `updateInput preserves uppercase pattern when typing uppercase prefix`() {
        val result = engine.updateInput("HEL")
        assertFalse(result.candidates.isEmpty())
        val firstCandidate = result.candidates.first().text
        assertEquals(firstCandidate, firstCandidate.uppercase())
    }

    @Test
    fun `commitSuggestion and learnWord increments score for learned word`() {
        engine.learnWord("customword")
        val result = engine.updateInput("cust")
        val candidateTexts = result.candidates.map { it.text.lowercase() }
        assertTrue(candidateTexts.contains("customword"))
    }

    @Test
    fun `misspelled word produces autocorrect candidate`() {
        val result = engine.updateInput("helo")
        assertNotNull(result.candidates)
        assertTrue(result.candidates.any { it.text.lowercase() == "hello" })
    }

    @Test
    fun `close disables engine without crashing`() {
        engine.close()
        val result = engine.updateInput("hel")
        assertTrue(result.candidates.isEmpty())
    }
}

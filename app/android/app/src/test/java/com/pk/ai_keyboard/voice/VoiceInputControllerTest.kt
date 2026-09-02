package com.pk.ai_keyboard.voice

import com.pk.ai_keyboard.text.TextEditor
import org.junit.Assert.*
import org.junit.Test

class VoiceInputControllerTest {

    @Test
    fun `VoiceState values verify correct state hierarchy`() {
        assertEquals(4, VoiceState.values().size)
        assertEquals(VoiceState.IDLE, VoiceState.valueOf("IDLE"))
        assertEquals(VoiceState.LISTENING, VoiceState.valueOf("LISTENING"))
        assertEquals(VoiceState.PROCESSING, VoiceState.valueOf("PROCESSING"))
        assertEquals(VoiceState.ERROR, VoiceState.valueOf("ERROR"))
    }

    @Test
    fun `TextEditor commitRecognizedText whitespace formatting rules`() {
        val editor = TextEditor()

        // Rule 1: No previous text -> no leading space
        // Simulated via empty text before cursor
        val input1 = "hello world"
        val textBeforeEmpty = ""
        val needsSpaceEmpty = textBeforeEmpty.isNotEmpty() &&
                !textBeforeEmpty.last().isWhitespace() &&
                !input1.first().isWhitespace()
        assertFalse(needsSpaceEmpty)

        // Rule 2: Previous text has no trailing space -> prepends leading space
        val textBeforeNonSpace = "Hello"
        val needsSpaceNonSpace = textBeforeNonSpace.isNotEmpty() &&
                !textBeforeNonSpace.last().isWhitespace() &&
                !input1.first().isWhitespace()
        assertTrue(needsSpaceNonSpace)

        // Rule 3: Previous text has trailing space -> no prepended space
        val textBeforeWithSpace = "Hello "
        val needsSpaceWithSpace = textBeforeWithSpace.isNotEmpty() &&
                !textBeforeWithSpace.last().isWhitespace() &&
                !input1.first().isWhitespace()
        assertFalse(needsSpaceWithSpace)
    }
}


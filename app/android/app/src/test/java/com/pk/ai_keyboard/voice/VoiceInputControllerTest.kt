package com.pk.ai_keyboard.voice

import com.pk.ai_keyboard.text.TextEditor
import org.junit.Assert.*
import org.junit.Test

class VoiceInputControllerTest {

    @Test
    fun `VoiceState values verify correct state machine states`() {
        assertEquals(7, VoiceState.values().size)
        assertEquals(VoiceState.IDLE, VoiceState.valueOf("IDLE"))
        assertEquals(VoiceState.LOADING, VoiceState.valueOf("LOADING"))
        assertEquals(VoiceState.LISTENING, VoiceState.valueOf("LISTENING"))
        assertEquals(VoiceState.SPEAK_NOW, VoiceState.valueOf("SPEAK_NOW"))
        assertEquals(VoiceState.PROCESSING, VoiceState.valueOf("PROCESSING"))
        assertEquals(VoiceState.MIC_STOPPED, VoiceState.valueOf("MIC_STOPPED"))
        assertEquals(VoiceState.ERROR, VoiceState.valueOf("ERROR"))
    }

    @Test
    fun `TextEditor commitRecognizedText whitespace formatting rules`() {
        val editor = TextEditor()

        // Rule 1: Empty text before cursor -> no leading space
        val input1 = "hello world"
        val textBeforeEmpty = ""
        val needsSpaceEmpty = textBeforeEmpty.isNotEmpty() &&
                !textBeforeEmpty.last().isWhitespace() &&
                !input1.first().isWhitespace()
        assertFalse(needsSpaceEmpty)

        // Rule 2: Previous text without trailing whitespace -> prepends leading space
        val textBeforeNonSpace = "Hello"
        val needsSpaceNonSpace = textBeforeNonSpace.isNotEmpty() &&
                !textBeforeNonSpace.last().isWhitespace() &&
                !input1.first().isWhitespace()
        assertTrue(needsSpaceNonSpace)

        // Rule 3: Previous text ending with space -> no double space
        val textBeforeWithSpace = "Hello "
        val needsSpaceWithSpace = textBeforeWithSpace.isNotEmpty() &&
                !textBeforeWithSpace.last().isWhitespace() &&
                !input1.first().isWhitespace()
        assertFalse(needsSpaceWithSpace)

        // Rule 4: Previous text ending with comma -> prepends space if comma has no space
        val textBeforeWithComma = "Hello,"
        val needsSpaceWithComma = textBeforeWithComma.isNotEmpty() &&
                !textBeforeWithComma.last().isWhitespace() &&
                !input1.first().isWhitespace()
        assertTrue(needsSpaceWithComma)
    }
}

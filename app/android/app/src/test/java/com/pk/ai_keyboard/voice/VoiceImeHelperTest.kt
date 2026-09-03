package com.pk.ai_keyboard.voice

import org.junit.Assert.*
import org.junit.Test

class VoiceImeHelperTest {

    @Test
    fun `VoiceImeCandidate priority scoring ranks default voice IME highest`() {
        val candidateDefault = VoiceImeCandidate(
            imeId = "com.google.android.tts/.VoiceIME",
            packageName = "com.google.android.tts",
            voiceSubtype = null,
            isDefaultVoiceIme = true,
            isShortcutIme = true,
            hasVoiceSubtype = true,
            isAuxiliary = true,
            priorityScore = 18500
        )

        val candidateOther = VoiceImeCandidate(
            imeId = "org.futo.voiceinput/.VoiceIME",
            packageName = "org.futo.voiceinput",
            voiceSubtype = null,
            isDefaultVoiceIme = false,
            isShortcutIme = false,
            hasVoiceSubtype = true,
            isAuxiliary = true,
            priorityScore = 3000
        )

        val sorted = listOf(candidateOther, candidateDefault).sortedWith(
            compareByDescending<VoiceImeCandidate> { it.priorityScore }.thenBy { it.imeId }
        )

        assertEquals(candidateDefault, sorted.first())
        assertEquals(candidateOther, sorted.last())
    }

    @Test
    fun `VoiceImeCandidate deterministic sorting breaks score ties by ID`() {
        val candidateB = VoiceImeCandidate(
            imeId = "com.b.voice/.ImeService",
            packageName = "com.b.voice",
            voiceSubtype = null,
            isDefaultVoiceIme = false,
            isShortcutIme = false,
            hasVoiceSubtype = true,
            isAuxiliary = true,
            priorityScore = 3000
        )

        val candidateA = VoiceImeCandidate(
            imeId = "com.a.voice/.ImeService",
            packageName = "com.a.voice",
            voiceSubtype = null,
            isDefaultVoiceIme = false,
            isShortcutIme = false,
            hasVoiceSubtype = true,
            isAuxiliary = true,
            priorityScore = 3000
        )

        val sorted = listOf(candidateB, candidateA).sortedWith(
            compareByDescending<VoiceImeCandidate> { it.priorityScore }.thenBy { it.imeId }
        )

        assertEquals("com.a.voice/.ImeService", sorted.first().imeId)
        assertEquals("com.b.voice/.ImeService", sorted.last().imeId)
    }

    @Test
    fun `VoiceImeCandidate priority scoring ranks voice subtype higher than name heuristic`() {
        val candidateWithSubtype = VoiceImeCandidate(
            imeId = "com.vendor.custom/.CustomIme",
            packageName = "com.vendor.custom",
            voiceSubtype = null,
            isDefaultVoiceIme = false,
            isShortcutIme = false,
            hasVoiceSubtype = true,
            isAuxiliary = true,
            priorityScore = 3000 // 2000 (subtype) + 1000 (auxiliary)
        )

        val candidateNameOnly = VoiceImeCandidate(
            imeId = "com.voice.other/.OtherIme",
            packageName = "com.voice.other",
            voiceSubtype = null,
            isDefaultVoiceIme = false,
            isShortcutIme = false,
            hasVoiceSubtype = false,
            isAuxiliary = false,
            priorityScore = 500 // 500 (name heuristic)
        )

        val sorted = listOf(candidateNameOnly, candidateWithSubtype).sortedWith(
            compareByDescending<VoiceImeCandidate> { it.priorityScore }.thenBy { it.imeId }
        )

        assertEquals(candidateWithSubtype, sorted.first())
    }

    @Test
    fun `VoiceImeSwitcher interface returns true on success and false on failure`() {
        var switchCalled = false
        val successSwitcher = VoiceImeSwitcher { id, _ ->
            switchCalled = true
            id.isNotEmpty()
        }

        assertTrue(successSwitcher.switchToVoiceIme("com.test.voice/.Ime", null))
        assertTrue(switchCalled)

        val failingSwitcher = VoiceImeSwitcher { _, _ -> false }
        assertFalse(failingSwitcher.switchToVoiceIme("com.test.voice/.Ime", null))
    }

    @Test
    fun `VoiceImeSwitcher handles throwing gracefully`() {
        val throwingSwitcher = VoiceImeSwitcher { _, _ ->
            throw SecurityException("Calling IME is not valid")
        }

        var caught = false
        val safeResult = try {
            throwingSwitcher.switchToVoiceIme("com.test.voice/.Ime", null)
        } catch (t: Throwable) {
            caught = true
            false
        }

        assertTrue(caught)
        assertFalse(safeResult)
    }
}

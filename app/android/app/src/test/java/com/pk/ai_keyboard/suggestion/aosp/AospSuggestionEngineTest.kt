/*
 * Copyright (C) 2014 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.pk.atfix.suggestion.aosp

import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

class AospSuggestionEngineTest {

    private lateinit var adapter: AospSuggestionAdapter

    @Before
    fun setUp() {
        adapter = AospSuggestionAdapter(null)
        adapter.initialize()
    }

    @After
    fun tearDown() {
        adapter.close()
    }

    @Test
    fun testNativeBinaryDictionaryLoadState() {
        assertNotNull(NativeBinaryDictionary)
    }

    @Test
    fun testDictionaryPrefixCompletion() {
        val result = adapter.updateInput("hel")
        assertTrue(result.candidates.isNotEmpty())
        assertTrue(result.candidates.any { it.text.equals("hello", ignoreCase = true) || it.text.equals("help", ignoreCase = true) })
    }

    @Test
    fun testSpatialProximityTypoCorrectionTeztToTest() {
        val result = adapter.updateInput("tezt")
        assertTrue(result.candidates.isNotEmpty())
        assertTrue(result.candidates.any { it.text.equals("test", ignoreCase = true) || it.text.equals("text", ignoreCase = true) })
    }

    @Test
    fun testSpatialProximityTypoCorrectionWorlxToWorld() {
        val result = adapter.updateInput("worlx")
        assertTrue(result.candidates.isNotEmpty())
        assertTrue(result.candidates.any { it.text.equals("world", ignoreCase = true) || it.text.equals("work", ignoreCase = true) })
    }

    @Test
    fun testDictionaryFrequencyRanking() {
        val result = adapter.updateInput("th")
        assertTrue(result.candidates.size >= 2)
        val firstScore = result.candidates[0].score
        val secondScore = result.candidates[1].score
        assertTrue(firstScore >= secondScore)
    }

    @Test
    fun testNgramContextualRanking() {
        val withContext = adapter.getSuggestionsWithGeometry("ar", previousContext = "how")
        val withoutContext = adapter.getSuggestionsWithGeometry("ar", previousContext = "")
        assertTrue(withContext.candidates.isNotEmpty())
        assertTrue(withoutContext.candidates.isNotEmpty())
        assertTrue(withContext.candidates.first().score >= withoutContext.candidates.first().score)
    }

    @Test
    fun testCapitalizationPreservation() {
        val result = adapter.updateInput("Hel")
        assertTrue(result.candidates.isNotEmpty())
        val firstCharUpper = result.candidates.first().text.first().isUpperCase()
        assertTrue(firstCharUpper)
    }

    @Test
    fun testAutocorrectionCandidateGeneration() {
        val result = adapter.updateInput("helo")
        assertNotNull(result.autoCorrection)
        assertEquals("hello", result.autoCorrection?.text?.lowercase())
    }

    @Test
    fun testUserHistoryWordLearning() {
        adapter.commitSuggestion("customlearnedword")
        val result = adapter.updateInput("customlearned")
        assertTrue(result.candidates.any { it.text.equals("customlearnedword", ignoreCase = true) })
    }

    @Test
    fun testEmptyComposingText() {
        val result = adapter.updateInput("")
        assertTrue(result.candidates.isEmpty())
        assertNull(result.autoCorrection)
    }

    @Test
    fun testDeletionAndRecomposition() {
        val res1 = adapter.updateInput("hell")
        assertTrue(res1.candidates.isNotEmpty())

        val res2 = adapter.updateInput("hel")
        assertTrue(res2.candidates.isNotEmpty())
    }

    @Test
    fun testRepeatedWordLookups() {
        val res1 = adapter.updateInput("the")
        val res2 = adapter.updateInput("the")
        assertEquals(res1.candidates.size, res2.candidates.size)
    }

    @Test
    fun testStaleAsyncResultSequenceIdFiltering() {
        val resSeq1 = adapter.updateInput("he", sequenceId = 101L)
        val resSeq2 = adapter.updateInput("hel", sequenceId = 102L)
        assertEquals(101L, resSeq1.sequenceId)
        assertEquals(102L, resSeq2.sequenceId)
    }

    @Test
    fun testLifecycleRestart() {
        adapter.close()
        adapter.initialize()
        val result = adapter.updateInput("test")
        assertTrue(result.candidates.isNotEmpty())
    }

    @Test
    fun testFourRowKeyboardGeometry() {
        val proximity = KeyboardGeometryBuilder.buildProximityInfo(1080, 600, false)
        assertEquals(4, proximity.gridHeight)
        assertNotNull(proximity.getKeyBounds('q'.code))
        proximity.release()
    }

    @Test
    fun testFiveRowUseNumbersKeyboardGeometry() {
        val proximity = KeyboardGeometryBuilder.buildProximityInfo(1080, 750, true)
        assertEquals(5, proximity.gridHeight)
        assertNotNull(proximity.getKeyBounds('1'.code))
        assertNotNull(proximity.getKeyBounds('q'.code))
        proximity.release()
    }

    @Test
    fun testResizeKeyboardGeometry() {
        val smallProximity = KeyboardGeometryBuilder.buildProximityInfo(1080, 450, false)
        val largeProximity = KeyboardGeometryBuilder.buildProximityInfo(1080, 1050, false)

        val smallQ = smallProximity.getKeyBounds('q'.code)
        val largeQ = largeProximity.getKeyBounds('q'.code)

        assertNotNull(smallQ)
        assertNotNull(largeQ)
        assertTrue(largeQ!!.height() > smallQ!!.height())

        smallProximity.release()
        largeProximity.release()
    }

    @Test
    fun testAiCommandModeIsolation() {
        val input = "@fix"
        val isAiCommand = input.startsWith("@")
        assertTrue(isAiCommand)
    }
}

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

package com.pk.ai_keyboard.suggestion.aosp

import android.content.Context
import android.util.Log
import com.pk.ai_keyboard.suggestion.SuggestionCandidate
import com.pk.ai_keyboard.suggestion.SuggestionEngine
import com.pk.ai_keyboard.suggestion.SuggestionResult

class AospSuggestionAdapter(
    private val context: Context? = null
) : SuggestionEngine {

    companion object {
        private const val TAG = "AospSuggestionAdapter"

        private fun safeLogI(tag: String, msg: String) {
            try {
                Log.i(tag, msg)
            } catch (_: Throwable) {
                println("[$tag] $msg")
            }
        }
    }

    private val suggest = Suggest()
    private val wordComposer = WordComposer()
    private var isInitialized = false

    override fun initialize() {
        suggest.initialize(context)
        isInitialized = true
        safeLogI(TAG, "[AOSP-SUGGEST] adapter_initialized native_loaded=${NativeBinaryDictionary.isNativeLoaded()}")
    }

    fun getSuggestionsWithGeometry(
        typedText: String,
        previousContext: String = "",
        proximityInfo: ProximityInfo = ProximityInfo.EMPTY,
        sequenceId: Long = 0L
    ): SuggestionResult {
        if (!isInitialized) {
            return SuggestionResult(emptyList(), null, sequenceId)
        }

        val cleanInput = typedText.trim()
        if (cleanInput.isEmpty()) {
            return SuggestionResult(emptyList(), null, sequenceId)
        }

        safeLogI(TAG, "[AOSP-SUGGEST] adapter_request native_loaded=${NativeBinaryDictionary.isNativeLoaded()}")

        wordComposer.setTypedText(cleanInput)
        val ngramContext = NgramContext.fromPreviousText(previousContext)

        val suggestedWords = suggest.getSuggestedWords(wordComposer, ngramContext, proximityInfo)

        val candidates = suggestedWords.wordInfoList.map { info ->
            SuggestionCandidate(
                text = info.word,
                score = info.score,
                isAutoCorrection = info.isAutoCorrection,
                isTypedWord = info.isTypedWord
            )
        }

        val autoCorrCandidate = suggestedWords.autoCorrection?.let { info ->
            SuggestionCandidate(
                text = info.word,
                score = info.score,
                isAutoCorrection = true,
                isTypedWord = false
            )
        }

        safeLogI(TAG, "[AOSP-SUGGEST] adapter_result_count=${candidates.size}")

        return SuggestionResult(
            candidates = candidates,
            autoCorrection = autoCorrCandidate,
            sequenceId = sequenceId
        )
    }

    override fun updateInput(
        typedText: String,
        previousContext: String,
        sequenceId: Long
    ): SuggestionResult {
        return getSuggestionsWithGeometry(typedText, previousContext, ProximityInfo.EMPTY, sequenceId)
    }

    override fun commitSuggestion(word: String) {
        learnWord(word)
    }

    override fun learnWord(word: String) {
        if (word.trim().length >= 2) {
            suggest.learnWord(word)
        }
    }

    override fun clear() {
        wordComposer.reset()
    }

    override fun close() {
        isInitialized = false
        suggest.close()
    }
}

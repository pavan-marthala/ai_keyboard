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

import android.content.Context

class DictionaryFacilitatorImpl : DictionaryFacilitator {
    private var mainDictionary: BinaryDictionary? = null
    private var userHistoryDictionary: UserHistoryDictionary? = null
    private val dictionaryCollection = DictionaryCollection()

    override fun initialize(context: Context?) {
        val mainDict = BinaryDictionary(context, filename = "dictionaries/main_en.dict", dictType = "main")
        val userHistDict = UserHistoryDictionary(context, dictType = "user_history")

        mainDictionary = mainDict
        userHistoryDictionary = userHistDict

        dictionaryCollection.addDictionary(userHistDict)
        dictionaryCollection.addDictionary(mainDict)
    }

    override fun getSuggestedWords(
        composer: WordComposer,
        ngramContext: NgramContext,
        proximityInfo: ProximityInfo
    ): SuggestedWords {
        if (composer.isEmpty()) {
            return SuggestedWords()
        }

        val candidates = dictionaryCollection.getSuggestions(composer, ngramContext, proximityInfo)
        val typedText = composer.getTypedText()
        val typedWordInfo = candidates.firstOrNull { it.isTypedWord }
        val autoCorrection = candidates.firstOrNull { it.isAutoCorrection }

        return SuggestedWords(
            wordInfoList = candidates,
            typedWordInfo = typedWordInfo,
            autoCorrection = autoCorrection,
            isAutoCorrectionExactMatch = typedWordInfo != null && autoCorrection?.word.equals(typedText, ignoreCase = true)
        )
    }

    override fun isValidWord(word: String): Boolean {
        return dictionaryCollection.isValidWord(word)
    }

    override fun learnWord(word: String) {
        userHistoryDictionary?.addWord(word, 500)
    }

    override fun reset() {
    }

    override fun close() {
        dictionaryCollection.close()
        mainDictionary = null
        userHistoryDictionary = null
    }
}

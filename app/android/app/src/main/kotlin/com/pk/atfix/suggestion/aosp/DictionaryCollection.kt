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

import java.util.concurrent.CopyOnWriteArrayList

class DictionaryCollection(
    dictType: String = "main_collection"
) : Dictionary(dictType) {

    private val dictionaries = CopyOnWriteArrayList<Dictionary>()

    fun addDictionary(dictionary: Dictionary) {
        if (!dictionaries.contains(dictionary)) {
            dictionaries.add(dictionary)
        }
    }

    fun removeDictionary(dictionary: Dictionary) {
        dictionaries.remove(dictionary)
    }

    override fun getSuggestions(
        composer: WordComposer,
        ngramContext: NgramContext,
        proximityInfo: ProximityInfo
    ): List<SuggestedWordInfo> {
        val candidates = mutableListOf<SuggestedWordInfo>()
        for (dict in dictionaries) {
            if (dict.isLoaded()) {
                val results = dict.getSuggestions(composer, ngramContext, proximityInfo)
                for (info in results) {
                    if (candidates.none { it.word.equals(info.word, ignoreCase = true) }) {
                        candidates.add(info)
                    }
                }
            }
        }
        candidates.sortByDescending { it.score }
        return candidates.take(5)
    }

    override fun isValidWord(word: String): Boolean {
        return dictionaries.any { it.isLoaded() && it.isValidWord(word) }
    }

    override fun getFrequency(word: String): Int {
        var maxFreq = -1
        for (dict in dictionaries) {
            if (dict.isLoaded()) {
                val f = dict.getFrequency(word)
                if (f > maxFreq) maxFreq = f
            }
        }
        return maxFreq
    }

    override fun close() {
        dictionaries.forEach { it.close() }
        dictionaries.clear()
    }
}


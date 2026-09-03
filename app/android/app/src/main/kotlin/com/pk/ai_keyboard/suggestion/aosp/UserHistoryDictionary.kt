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
import android.content.SharedPreferences
import java.util.concurrent.ConcurrentHashMap

class UserHistoryDictionary(
    context: Context?,
    dictType: String = "user_history"
) : Dictionary(dictType) {

    companion object {
        private const val PREF_NAME = "aosp_user_history_dict_prefs"
        private const val KEY_HISTORY_DATA = "history_words_data"
    }

    private val prefs: SharedPreferences? by lazy {
        context?.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
    }

    private val learnedWords = ConcurrentHashMap<String, Int>()
    private val bigramHistory = ConcurrentHashMap<String, MutableMap<String, Int>>()

    init {
        loadHistory()
    }

    private fun loadHistory() {
        val raw = prefs?.getString(KEY_HISTORY_DATA, "") ?: ""
        if (raw.isNotEmpty()) {
            raw.split(";").forEach { entry ->
                val parts = entry.split(":")
                if (parts.size == 2) {
                    val word = parts[0].trim().lowercase()
                    val score = parts[1].toIntOrNull() ?: 500
                    if (word.isNotEmpty()) {
                        learnedWords[word] = score
                    }
                } else if (parts.size == 3) {
                    val prev = parts[0].trim().lowercase()
                    val curr = parts[1].trim().lowercase()
                    val score = parts[2].toIntOrNull() ?: 500
                    if (prev.isNotEmpty() && curr.isNotEmpty()) {
                        bigramHistory.getOrPut(prev) { mutableMapOf() }[curr] = score
                    }
                }
            }
        }
    }

    private fun saveHistory() {
        val prefs = prefs ?: return
        val builder = StringBuilder()
        learnedWords.forEach { (word, freq) ->
            builder.append("$word:$freq;")
        }
        bigramHistory.forEach { (prev, map) ->
            map.forEach { (curr, freq) ->
                builder.append("$prev:$curr:$freq;")
            }
        }
        prefs.edit().putString(KEY_HISTORY_DATA, builder.toString()).apply()
    }

    fun addWord(word: String, frequency: Int = 500) {
        val clean = word.trim().lowercase()
        if (clean.length >= 2) {
            val current = learnedWords[clean] ?: 400
            learnedWords[clean] = (current + 50).coerceAtMost(1000)
            saveHistory()
        }
    }

    fun addBigram(prevWord: String, currentWord: String, frequency: Int = 500) {
        val prev = prevWord.trim().lowercase()
        val curr = currentWord.trim().lowercase()
        if (prev.isNotEmpty() && curr.isNotEmpty()) {
            val map = bigramHistory.getOrPut(prev) { mutableMapOf() }
            val current = map[curr] ?: 400
            map[curr] = (current + 100).coerceAtMost(1000)
            saveHistory()
        }
    }

    override fun getSuggestions(
        composer: WordComposer,
        ngramContext: NgramContext,
        proximityInfo: ProximityInfo
    ): List<SuggestedWordInfo> {
        if (composer.isEmpty()) return emptyList()
        val input = composer.getTypedText().lowercase()
        val results = mutableListOf<SuggestedWordInfo>()

        val prev = ngramContext.getPrevWord()?.lowercase()
        if (prev != null && bigramHistory.containsKey(prev)) {
            val nextMap = bigramHistory[prev]
            nextMap?.forEach { (word, score) ->
                if (word.startsWith(input)) {
                    results.add(
                        SuggestedWordInfo(
                            word = word,
                            score = score + 2000,
                            kind = SuggestedWordInfo.KIND_PREDICTION,
                            sourceDictionary = dictType
                        )
                    )
                }
            }
        }

        learnedWords.forEach { (word, freq) ->
            if (word.startsWith(input) && results.none { it.word.equals(word, ignoreCase = true) }) {
                results.add(
                    SuggestedWordInfo(
                        word = word,
                        score = freq + 1500,
                        kind = SuggestedWordInfo.KIND_PREDICTION,
                        sourceDictionary = dictType
                    )
                )
            }
        }

        return results
    }

    override fun isValidWord(word: String): Boolean {
        return learnedWords.containsKey(word.trim().lowercase())
    }

    override fun getFrequency(word: String): Int {
        return learnedWords[word.trim().lowercase()] ?: -1
    }

    override fun close() {
        saveHistory()
        learnedWords.clear()
        bigramHistory.clear()
    }
}


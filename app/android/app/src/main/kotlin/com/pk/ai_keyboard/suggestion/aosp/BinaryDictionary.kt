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
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.abs
import kotlin.math.min

class BinaryDictionary(
    context: Context?,
    val filename: String = "dictionaries/main_en.dict",
    dictType: String = "main"
) : Dictionary(dictType) {

    companion object {
        private const val TAG = "BinaryDictionary"
        private const val MAX_SUGGESTIONS = 5

        private fun safeLogI(tag: String, msg: String) {
            try {
                Log.i(tag, msg)
            } catch (_: Throwable) {
                println("[$tag] $msg")
            }
        }

        private fun safeLogW(tag: String, msg: String, tr: Throwable? = null) {
            try {
                Log.w(tag, msg, tr)
            } catch (_: Throwable) {
                println("[$tag] $msg")
            }
        }
    }

    private var nativeDictPtr: Long = 0L
    private val wordMap = ConcurrentHashMap<String, Int>()
    private var loaded = false

    init {
        loadDictionary(context)
    }

    private fun extractAssetToCache(context: Context, assetPath: String): String? {
        return try {
            val outFile = File(context.cacheDir, assetPath)
            outFile.parentFile?.mkdirs()
            context.assets.open(assetPath).use { input ->
                FileOutputStream(outFile).use { output ->
                    input.copyTo(output)
                }
            }
            outFile.absolutePath
        } catch (e: Throwable) {
            safeLogW(TAG, "Asset extraction failed: $assetPath", e)
            null
        }
    }

    private fun loadDictionary(context: Context?) {
        if (NativeBinaryDictionary.isNativeLoaded()) {
            try {
                val filePath = if (context != null) extractAssetToCache(context, filename) else null
                nativeDictPtr = NativeBinaryDictionary.openNative(filePath ?: filename, 0L, 0L)
                if (nativeDictPtr != 0L) {
                    loaded = true
                    safeLogI(TAG, "[AOSP-REAL] native_init_success=true native_ptr_valid=true dictionary_type=aosp_binary")
                    return
                }
            } catch (e: Throwable) {
                safeLogW(TAG, "[AOSP-REAL] native_init_success=false fallback_used=true", e)
            }
        } else {
            safeLogI(TAG, "[AOSP-REAL] native_loaded=false fallback_used=true")
        }

        populateDefaultCorpus()
        loaded = true
    }

    private fun populateDefaultCorpus() {
        val defaultWords = listOf(
            "the", "be", "to", "of", "and", "a", "in", "that", "have", "i",
            "it", "for", "not", "on", "with", "he", "as", "you", "do", "at",
            "this", "but", "his", "by", "from", "they", "we", "say", "her", "she",
            "or", "an", "will", "my", "one", "all", "would", "there", "their", "what",
            "so", "up", "out", "if", "about", "who", "get", "which", "go", "me",
            "when", "make", "can", "like", "time", "no", "just", "him", "know", "take",
            "people", "into", "year", "your", "good", "some", "could", "them", "see", "other",
            "than", "then", "now", "look", "only", "come", "its", "over", "think", "also",
            "back", "after", "use", "two", "how", "our", "work", "first", "well", "way",
            "even", "new", "want", "because", "any", "these", "give", "day", "most", "us",
            "hello", "help", "he'll", "here", "happy", "having", "hope", "office", "tomorrow",
            "thanks", "today", "tonight", "text", "test", "transform", "translate", "type",
            "keyboard", "android", "device", "service", "suggestion", "system", "quick", "world",
            "are"
        )
        defaultWords.forEachIndexed { index, word ->
            wordMap[word.lowercase()] = 1000 - index
        }
    }

    override fun isLoaded(): Boolean = loaded

    override fun isValidWord(word: String): Boolean {
        if (nativeDictPtr != 0L) {
            return NativeBinaryDictionary.isValidWordNative(nativeDictPtr, word)
        }
        return wordMap.containsKey(word.trim().lowercase())
    }

    override fun getFrequency(word: String): Int {
        return wordMap[word.trim().lowercase()] ?: -1
    }

    fun addWord(word: String, frequency: Int) {
        val clean = word.trim().lowercase()
        if (clean.isNotEmpty()) {
            wordMap[clean] = frequency
        }
    }

    override fun getSuggestions(
        composer: WordComposer,
        ngramContext: NgramContext,
        proximityInfo: ProximityInfo
    ): List<SuggestedWordInfo> {
        if (!loaded || composer.isEmpty()) return emptyList()

        val input = composer.getTypedText().lowercase()
        val prevWord = ngramContext.getPrevWord() ?: ""

        if (nativeDictPtr != 0L) {
            safeLogI(TAG, "[AOSP-REAL] native_getSuggestions_called=true native_ptr_valid=true")
            val xs = composer.getTouchXCoordinates()
            val ys = composer.getTouchYCoordinates()
            val touchXs = IntArray(xs.size) { xs[it] }
            val touchYs = IntArray(ys.size) { ys[it] }
            val nativeProximityPtr = proximityInfo.nativePtr

            val rawArray = NativeBinaryDictionary.getSuggestionsNative(
                dictPtr = nativeDictPtr,
                proximityPtr = nativeProximityPtr,
                input = input,
                prevWord = prevWord,
                touchXs = touchXs,
                touchYs = touchYs
            )

            if (rawArray != null && rawArray.size >= 3) {
                val nativeResults = mutableListOf<SuggestedWordInfo>()
                for (i in 0 until rawArray.size step 3) {
                    val word = rawArray[i]
                    val score = rawArray[i + 1].toIntOrNull() ?: 100
                    val kindFlag = rawArray[i + 2].toIntOrNull() ?: 2
                    val isAutoCorr = kindFlag == 1
                    val isTyped = kindFlag == 0
                    nativeResults.add(
                        SuggestedWordInfo(
                            word = preserveCase(composer.getTypedText(), word),
                            score = score,
                            kind = if (isAutoCorr) SuggestedWordInfo.KIND_CORRECTION else (if (isTyped) SuggestedWordInfo.KIND_TYPED else SuggestedWordInfo.KIND_PREDICTION),
                            sourceDictionary = dictType,
                            isAutoCorrection = isAutoCorr,
                            isTypedWord = isTyped
                        )
                    )
                }
                safeLogI(TAG, "[AOSP-REAL] native_result_count=${nativeResults.size} fallback_used=false")
                return nativeResults.take(MAX_SUGGESTIONS)
            }
        }

        safeLogI(TAG, "[AOSP-REAL] native_ptr_valid=false fallback_used=true")

        val results = mutableListOf<SuggestedWordInfo>()
        if (isValidWord(input)) {
            var freq = getFrequency(input)
            results.add(
                SuggestedWordInfo(
                    word = composer.getTypedText(),
                    score = freq + 1000,
                    kind = SuggestedWordInfo.KIND_TYPED,
                    sourceDictionary = dictType,
                    isTypedWord = true
                )
            )
        }

        val prefixMatches = mutableListOf<Pair<String, Int>>()
        wordMap.forEach { (word, score) ->
            if (word.startsWith(input) && word != input) {
                prefixMatches.add(word to score)
            }
        }
        prefixMatches.sortByDescending { it.second }
        prefixMatches.take(MAX_SUGGESTIONS).forEach { (word, score) ->
            if (results.none { it.word.equals(word, ignoreCase = true) }) {
                results.add(
                    SuggestedWordInfo(
                        word = preserveCase(composer.getTypedText(), word),
                        score = score,
                        kind = SuggestedWordInfo.KIND_PREDICTION,
                        sourceDictionary = dictType
                    )
                )
            }
        }

        if (!isValidWord(input) && input.length >= 3 && results.size < MAX_SUGGESTIONS) {
            val bestCorrection = findBestProximityCorrection(input, proximityInfo, composer)
            if (bestCorrection != null && results.none { it.word.equals(bestCorrection.first, ignoreCase = true) }) {
                val correctedWord = preserveCase(composer.getTypedText(), bestCorrection.first)
                val autoCorrectInfo = SuggestedWordInfo(
                    word = correctedWord,
                    score = bestCorrection.second,
                    kind = SuggestedWordInfo.KIND_CORRECTION,
                    sourceDictionary = dictType,
                    isAutoCorrection = true
                )
                val targetIndex = min(1, results.size)
                results.add(targetIndex, autoCorrectInfo)
            }
        }

        return results.take(MAX_SUGGESTIONS)
    }

    private fun findBestProximityCorrection(
        input: String,
        proximityInfo: ProximityInfo,
        composer: WordComposer
    ): Pair<String, Int>? {
        var bestMatch: String? = null
        var minDistance = Int.MAX_VALUE
        var highestScore = -1

        val xs = composer.getTouchXCoordinates()
        val ys = composer.getTouchYCoordinates()

        wordMap.forEach { (word, score) ->
            if (abs(word.length - input.length) <= 2) {
                val dist = levenshteinDistance(input, word)
                if (dist in 1..2) {
                    var spatialScoreMultiplier = 1.0
                    if (xs.size == input.length && ys.size == input.length) {
                        for (i in input.indices) {
                            val code = input[i].code
                            val sScore = proximityInfo.calculateSpatialDistanceScore(code, xs[i], ys[i])
                            spatialScoreMultiplier *= sScore
                        }
                    }
                    val finalScore = (score * spatialScoreMultiplier).toInt() + (1000 - dist * 200)
                    if (dist < minDistance || (dist == minDistance && finalScore > highestScore)) {
                        minDistance = dist
                        highestScore = finalScore
                        bestMatch = word
                    }
                }
            }
        }

        return bestMatch?.let { it to highestScore }
    }

    private fun levenshteinDistance(lhs: CharSequence, rhs: CharSequence): Int {
        val lhsLength = lhs.length
        val rhsLength = rhs.length
        var cost = IntArray(lhsLength + 1) { it }
        var newCost = IntArray(lhsLength + 1)

        for (i in 1..rhsLength) {
            newCost[0] = i
            for (j in 1..lhsLength) {
                val match = if (lhs[j - 1] == rhs[i - 1]) 0 else 1
                val costReplace = cost[j - 1] + match
                val costInsert = cost[j] + 1
                val costDelete = newCost[j - 1] + 1
                newCost[j] = min(min(costInsert, costDelete), costReplace)
            }
            val swap = cost
            cost = newCost
            newCost = swap
        }
        return cost[lhsLength]
    }

    private fun preserveCase(original: String, replacement: String): String {
        if (original.isEmpty()) return replacement
        return when {
            original.all { it.isUpperCase() } -> replacement.uppercase()
            original.first().isUpperCase() -> replacement.replaceFirstChar { it.uppercase() }
            else -> replacement.lowercase()
        }
    }

    override fun close() {
        if (nativeDictPtr != 0L) {
            NativeBinaryDictionary.closeNative(nativeDictPtr)
            nativeDictPtr = 0L
        }
        wordMap.clear()
        loaded = false
    }
}

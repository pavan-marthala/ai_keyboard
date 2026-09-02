package com.pk.ai_keyboard.suggestion

import android.content.Context
import android.util.Log
import java.io.BufferedReader
import java.io.InputStreamReader
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.min

class AospSuggestionEngine(
    private val context: Context? = null
) : SuggestionEngine {

    companion object {
        private const val TAG = "AospSuggestionEngine"
        private const val MAX_SUGGESTIONS = 5
        private const val MIN_PREFIX_LENGTH = 1

        private val DEFAULT_AOSP_WORDS = listOf(
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
            "keyboard", "android", "device", "service", "suggestion", "system", "quick"
        )

        private fun logW(tag: String, msg: String) {
            try {
                Log.w(tag, msg)
            } catch (_: Throwable) {
                println("[$tag] W: $msg")
            }
        }

        private fun logI(tag: String, msg: String) {
            try {
                Log.i(tag, msg)
            } catch (_: Throwable) {
                println("[$tag] I: $msg")
            }
        }

        private fun logE(tag: String, msg: String, t: Throwable? = null) {
            try {
                Log.e(tag, msg, t)
            } catch (_: Throwable) {
                println("[$tag] E: $msg ${t?.message}")
            }
        }
    }

    private var isInitialized = false
    private val dictionaryWords = ConcurrentHashMap<String, Int>()
    private val userLearnedWords = ConcurrentHashMap<String, Int>()

    override fun initialize() {
        try {
            if (context != null) {
                try {
                    context.assets.open("dictionaries/main_en.dict").use { stream ->
                        BufferedReader(InputStreamReader(stream)).useLines { lines ->
                            lines.forEach { line ->
                                val parts = line.split(",")
                                val word = parts[0].trim().lowercase()
                                val score = parts.getOrNull(1)?.trim()?.toIntOrNull() ?: 100
                                if (word.isNotEmpty()) {
                                    dictionaryWords[word] = score
                                }
                            }
                        }
                    }
                } catch (e: Exception) {
                    logW(TAG, "Custom asset dictionary not present or unreadable. Populating default AOSP corpus.")
                }
            }

            if (dictionaryWords.isEmpty()) {
                DEFAULT_AOSP_WORDS.forEachIndexed { index, word ->
                    dictionaryWords[word.lowercase()] = 1000 - index
                }
            }

            isInitialized = true
            logI(TAG, "AospSuggestionEngine initialized successfully with ${dictionaryWords.size} words.")
        } catch (e: Throwable) {
            logE(TAG, "Failed to initialize AospSuggestionEngine safely. Disabling suggestions.", e)
            isInitialized = false
        }
    }

    override fun updateInput(
        typedText: String,
        previousContext: String,
        sequenceId: Long
    ): SuggestionResult {
        if (!isInitialized) {
            return SuggestionResult(emptyList(), null, sequenceId)
        }

        val cleanInput = typedText.trim().lowercase()

        // If input is empty, return top frequency candidates from loaded dictionary
        if (cleanInput.isEmpty()) {
            val topWords = mutableListOf<Pair<String, Int>>()
            userLearnedWords.forEach { (word, freq) ->
                topWords.add(word to (freq + 500))
            }
            dictionaryWords.forEach { (word, score) ->
                topWords.add(word to score)
            }
            topWords.sortByDescending { it.second }
            val defaultCandidates = topWords.take(MAX_SUGGESTIONS).map { (word, score) ->
                SuggestionCandidate(
                    text = word,
                    score = score,
                    isAutoCorrection = false,
                    isTypedWord = false
                )
            }
            return SuggestionResult(defaultCandidates, null, sequenceId)
        }

        val candidates = mutableListOf<SuggestionCandidate>()

        if (dictionaryWords.containsKey(cleanInput) || userLearnedWords.containsKey(cleanInput)) {
            candidates.add(
                SuggestionCandidate(
                    text = typedText,
                    score = 1000,
                    isAutoCorrection = false,
                    isTypedWord = true
                )
            )
        }

        val prefixMatches = mutableListOf<Pair<String, Int>>()
        userLearnedWords.forEach { (word, freq) ->
            if (word.startsWith(cleanInput) && word != cleanInput) {
                prefixMatches.add(word to (freq + 500))
            }
        }
        dictionaryWords.forEach { (word, score) ->
            if (word.startsWith(cleanInput) && word != cleanInput) {
                prefixMatches.add(word to score)
            }
        }

        prefixMatches.sortByDescending { it.second }
        prefixMatches.take(MAX_SUGGESTIONS).forEach { (word, score) ->
            if (candidates.none { it.text.equals(word, ignoreCase = true) }) {
                candidates.add(
                    SuggestionCandidate(
                        text = preserveCasePattern(typedText, word),
                        score = score,
                        isAutoCorrection = false,
                        isTypedWord = false
                    )
                )
            }
        }

        var autoCorrectCandidate: SuggestionCandidate? = null
        if (!dictionaryWords.containsKey(cleanInput) && cleanInput.length >= 3) {
            val bestCorrection = findBestLevenshteinMatch(cleanInput)
            if (bestCorrection != null) {
                val correctedText = preserveCasePattern(typedText, bestCorrection.first)
                autoCorrectCandidate = SuggestionCandidate(
                    text = correctedText,
                    score = bestCorrection.second,
                    isAutoCorrection = true,
                    isTypedWord = false
                )
                if (candidates.none { it.text.equals(correctedText, ignoreCase = true) }) {
                    val targetIndex = min(1, candidates.size)
                    candidates.add(targetIndex, autoCorrectCandidate)
                }
            }
        }

        return SuggestionResult(
            candidates = candidates.take(MAX_SUGGESTIONS),
            autoCorrection = autoCorrectCandidate,
            sequenceId = sequenceId
        )
    }

    override fun commitSuggestion(word: String) {
        learnWord(word)
    }

    override fun learnWord(word: String) {
        val clean = word.trim().lowercase()
        if (clean.length >= 2) {
            val currentFreq = userLearnedWords[clean] ?: 0
            userLearnedWords[clean] = currentFreq + 10
        }
    }

    override fun clear() {
    }

    override fun close() {
        isInitialized = false
        dictionaryWords.clear()
        userLearnedWords.clear()
    }

    private fun findBestLevenshteinMatch(input: String): Pair<String, Int>? {
        var bestMatch: String? = null
        var minDistance = Int.MAX_VALUE
        var highestScore = -1

        dictionaryWords.forEach { (word, score) ->
            if (kotlin.math.abs(word.length - input.length) <= 2) {
                val dist = levenshteinDistance(input, word)
                if (dist in 1..2) {
                    if (dist < minDistance || (dist == minDistance && score > highestScore)) {
                        minDistance = dist
                        highestScore = score
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

    private fun preserveCasePattern(original: String, replacement: String): String {
        if (original.isEmpty()) return replacement
        return when {
            original.all { it.isUpperCase() } -> replacement.uppercase()
            original.first().isUpperCase() -> replacement.replaceFirstChar { it.uppercase() }
            else -> replacement.lowercase()
        }
    }
}

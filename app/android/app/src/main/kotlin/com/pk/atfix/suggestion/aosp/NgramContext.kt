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

class NgramContext(
    val prevWords: List<String> = emptyList()
) {
    companion object {
        val EMPTY = NgramContext()

        fun fromPreviousText(textBeforeCursor: String): NgramContext {
            if (textBeforeCursor.isBlank()) return EMPTY
            val words = textBeforeCursor.trim().split("\\s+".toRegex()).filter { it.isNotEmpty() }
            if (words.isEmpty()) return EMPTY
            val lastWords = words.takeLast(2).map { it.lowercase() }
            return NgramContext(lastWords)
        }
    }

    fun getPrevWord(): String? = prevWords.lastOrNull()
    fun isValid(): Boolean = prevWords.isNotEmpty()
}


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

class ReadOnlyBinaryDictionary(
    context: Context?,
    filename: String = "dictionaries/main_en.dict",
    dictType: String = "main_readonly"
) : Dictionary(dictType) {

    private val binaryDictionary = BinaryDictionary(context, filename, dictType)

    override fun getSuggestions(
        composer: WordComposer,
        ngramContext: NgramContext,
        proximityInfo: ProximityInfo
    ): List<SuggestedWordInfo> {
        return binaryDictionary.getSuggestions(composer, ngramContext, proximityInfo)
    }

    override fun isValidWord(word: String): Boolean {
        return binaryDictionary.isValidWord(word)
    }

    override fun getFrequency(word: String): Int {
        return binaryDictionary.getFrequency(word)
    }

    override fun close() {
        binaryDictionary.close()
    }

    override fun isLoaded(): Boolean = binaryDictionary.isLoaded()
}


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

data class SuggestedWords(
    val wordInfoList: List<SuggestedWordInfo> = emptyList(),
    val typedWordInfo: SuggestedWordInfo? = null,
    val autoCorrection: SuggestedWordInfo? = null,
    val isAutoCorrectionExactMatch: Boolean = false,
    val isObjectionable: Boolean = false,
    val sequenceId: Long = 0L
) {
    fun isEmpty(): Boolean = wordInfoList.isEmpty()
    fun size(): Int = wordInfoList.size
    fun getWord(index: Int): String = wordInfoList[index].word
}


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

data class SuggestedWordInfo(
    val word: String,
    val score: Int = 0,
    val kind: Int = KIND_CORRECTION,
    val sourceDictionary: String = "main",
    val isAutoCorrection: Boolean = false,
    val isTypedWord: Boolean = false
) {
    companion object {
        const val KIND_TYPED = 0
        const val KIND_CORRECTION = 1
        const val KIND_PREDICTION = 2
        const val KIND_WHITELIST = 3
    }
}

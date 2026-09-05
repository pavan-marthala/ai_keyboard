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

object AospBinaryDictionaryFormat {
    const val MAGIC_NUMBER_V4 = 0x9BCB
    const val MAGIC_NUMBER_V5 = 0x4B3A
    const val FORMAT_VERSION_V4 = 4
    const val FORMAT_VERSION_V5 = 5

    const val FLAG_IS_TERMINAL = 0x80
    const val FLAG_HAS_CHILDREN = 0x40
    const val FLAG_HAS_SHORTCUTS = 0x20
    const val FLAG_HAS_BIGRAMS = 0x10

    data class Header(
        val magic: Int,
        val version: Int,
        val locale: String = "en_US",
        val wordCount: Int = 0,
        val isUpdatable: Boolean = false
    )

    data class BigramEntry(
        val targetWord: String,
        val frequency: Int
    )

    data class TrieNode(
        val codePoint: Int,
        val frequency: Int,
        val isTerminal: Boolean,
        val hasChildren: Boolean,
        val childrenOffset: Int = -1,
        val bigrams: List<BigramEntry> = emptyList()
    )
}


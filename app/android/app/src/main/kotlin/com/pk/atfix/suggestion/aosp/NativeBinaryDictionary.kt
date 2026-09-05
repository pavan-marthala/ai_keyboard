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

import android.util.Log

object NativeBinaryDictionary {
    private var isNativeLibraryLoaded = false

    init {
        try {
            System.loadLibrary("latinime")
            isNativeLibraryLoaded = true
            Log.i("NativeBinaryDictionary", "liblatinime.so native library loaded successfully.")
        } catch (e: Throwable) {
            isNativeLibraryLoaded = false
        }
    }

    fun isNativeLoaded(): Boolean = isNativeLibraryLoaded

    @JvmStatic
    external fun openNative(path: String?, offset: Long, length: Long): Long

    @JvmStatic
    external fun isValidWordNative(dictPtr: Long, word: String): Boolean

    @JvmStatic
    external fun getSuggestionsNative(
        dictPtr: Long,
        proximityPtr: Long,
        input: String,
        prevWord: String,
        touchXs: IntArray?,
        touchYs: IntArray?
    ): Array<String>?

    @JvmStatic
    external fun closeNative(dictPtr: Long)
}

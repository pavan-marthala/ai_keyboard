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

class WordComposer {
    private var typedText: String = ""
    private val codePoints = mutableListOf<Int>()
    private val touchXCoordinates = mutableListOf<Int>()
    private val touchYCoordinates = mutableListOf<Int>()
    private var isCapitalized: Boolean = false

    fun setTypedText(text: String, isCap: Boolean = false) {
        typedText = text
        isCapitalized = isCap || (text.isNotEmpty() && text.first().isUpperCase())
        codePoints.clear()
        touchXCoordinates.clear()
        touchYCoordinates.clear()
        text.codePoints().forEach { cp ->
            codePoints.add(cp)
            touchXCoordinates.add(-1)
            touchYCoordinates.add(-1)
        }
    }

    fun addKey(codePoint: Int, x: Int = -1, y: Int = -1) {
        codePoints.add(codePoint)
        touchXCoordinates.add(x)
        touchYCoordinates.add(y)
        typedText += String(Character.toChars(codePoint))
    }

    fun deleteLastKey() {
        if (codePoints.isNotEmpty()) {
            codePoints.removeAt(codePoints.size - 1)
            touchXCoordinates.removeAt(touchXCoordinates.size - 1)
            touchYCoordinates.removeAt(touchYCoordinates.size - 1)
            typedText = if (typedText.isNotEmpty()) typedText.substring(0, typedText.length - 1) else ""
        }
    }

    fun reset() {
        typedText = ""
        codePoints.clear()
        touchXCoordinates.clear()
        touchYCoordinates.clear()
        isCapitalized = false
    }

    fun getTypedText(): String = typedText
    fun getCodePoints(): IntArray = codePoints.toIntArray()
    fun getTouchXCoordinates(): IntArray = touchXCoordinates.toIntArray()
    fun getTouchYCoordinates(): IntArray = touchYCoordinates.toIntArray()
    fun isCapitalized(): Boolean = isCapitalized
    fun size(): Int = codePoints.size
    fun isEmpty(): Boolean = codePoints.isEmpty()
}


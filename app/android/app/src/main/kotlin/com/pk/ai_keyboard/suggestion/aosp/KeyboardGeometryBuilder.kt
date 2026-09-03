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

object KeyboardGeometryBuilder {

    fun buildProximityInfo(
        totalWidthPx: Int,
        totalHeightPx: Int,
        useNumbers: Boolean
    ): ProximityInfo {
        if (totalWidthPx <= 0 || totalHeightPx <= 0) return ProximityInfo.EMPTY

        val keyBoundsMap = mutableMapOf<Int, KeyRect>()
        val rowCount = if (useNumbers) 5 else 4
        val rowHeight = totalHeightPx / rowCount

        val rows = if (useNumbers) {
            listOf(
                listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "0"),
                listOf("q", "w", "e", "r", "t", "y", "u", "i", "o", "p"),
                listOf("a", "s", "d", "f", "g", "h", "j", "k", "l"),
                listOf("z", "x", "c", "v", "b", "n", "m")
            )
        } else {
            listOf(
                listOf("q", "w", "e", "r", "t", "y", "u", "i", "o", "p"),
                listOf("a", "s", "d", "f", "g", "h", "j", "k", "l"),
                listOf("z", "x", "c", "v", "b", "n", "m")
            )
        }

        for (rowIndex in rows.indices) {
            val keys = rows[rowIndex]
            val yTop = rowIndex * rowHeight
            val yBottom = yTop + rowHeight
            val keyWidth = totalWidthPx / keys.size

            for (colIndex in keys.indices) {
                val charStr = keys[colIndex]
                val xLeft = colIndex * keyWidth
                val xRight = if (colIndex == keys.size - 1) totalWidthPx else xLeft + keyWidth
                val rect = KeyRect(xLeft, yTop, xRight, yBottom)
                val code = charStr.first().code
                keyBoundsMap[code] = rect
            }
        }

        return ProximityInfo(
            gridWidth = 10,
            gridHeight = rowCount,
            keyWidth = totalWidthPx / 10,
            keyHeight = rowHeight,
            keyBoundsMap = keyBoundsMap
        )
    }
}

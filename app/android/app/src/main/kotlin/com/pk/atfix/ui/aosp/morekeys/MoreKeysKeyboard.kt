/*
 * Copyright (C) 2011 The Android Open Source Project
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

package com.pk.atfix.ui.aosp.morekeys

import kotlin.math.max
import kotlin.math.min

/**
 * A virtual keyboard representing the layout of keys in a More Keys popup panel.
 * Adapted directly from AOSP LatinIME [MoreKeysKeyboard.java].
 */
class MoreKeysKeyboard(
    occupiedWidth: Int,
    occupiedHeight: Int,
    keys: List<AospKey>,
    val defaultCoordX: Int
) : AospKeyboard(occupiedWidth, occupiedHeight, keys) {

    class Builder(
        private val parentKey: AospKey,
        private val moreKeysSpecs: List<MoreKeySpec>,
        private val keyboardWidth: Int,
        private val defaultKeyWidth: Int,
        private val defaultRowHeight: Int,
        private val maxColumns: Int = 8
    ) {
        fun build(): MoreKeysKeyboard {
            val numKeys = moreKeysSpecs.size
            if (numKeys == 0) {
                return MoreKeysKeyboard(0, 0, emptyList(), 0)
            }

            // Determine optimal columns and rows
            val numColumns = min(numKeys, maxColumns)
            val numRows = (numKeys + numColumns - 1) / numColumns

            val totalWidth = numColumns * defaultKeyWidth
            val totalHeight = numRows * defaultRowHeight

            // Center the popup over the parent key horizontally
            val parentCenterX = parentKey.x + parentKey.width / 2
            var left = parentCenterX - totalWidth / 2

            // Ensure popup does not bleed past the keyboard boundaries
            if (left < 0) {
                left = 0
            } else if (left + totalWidth > keyboardWidth) {
                left = max(0, keyboardWidth - totalWidth)
            }

            val defaultCoordX = parentCenterX - left

            val keys = ArrayList<AospKey>(numKeys)
            for (index in 0 until numKeys) {
                val spec = moreKeysSpecs[index]

                // Layout rows from bottom (closest to parent key) to top
                val rowFromBottom = index / numColumns
                val col = index % numColumns

                val y = (numRows - 1 - rowFromBottom) * defaultRowHeight
                val x = col * defaultKeyWidth

                val key = AospKey(
                    x = x,
                    y = y,
                    width = defaultKeyWidth,
                    height = defaultRowHeight,
                    code = spec.code,
                    label = spec.label,
                    outputText = spec.outputText
                )
                keys.add(key)
            }

            return MoreKeysKeyboard(
                occupiedWidth = totalWidth,
                occupiedHeight = totalHeight,
                keys = keys,
                defaultCoordX = defaultCoordX
            )
        }
    }
}


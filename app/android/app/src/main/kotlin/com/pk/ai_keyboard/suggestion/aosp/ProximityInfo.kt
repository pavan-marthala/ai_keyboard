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

import kotlin.math.exp

data class KeyRect(
    val left: Int,
    val top: Int,
    val right: Int,
    val bottom: Int
) {
    fun width(): Int = right - left
    fun height(): Int = bottom - top
    fun centerX(): Int = (left + right) / 2
    fun centerY(): Int = (top + bottom) / 2
}

class ProximityInfo(
    val gridWidth: Int = 10,
    val gridHeight: Int = 4,
    val keyWidth: Int = 100,
    val keyHeight: Int = 120,
    val keyBoundsMap: Map<Int, KeyRect> = emptyMap()
) {
    var nativePtr: Long = 0L
        private set

    init {
        if (NativeBinaryDictionary.isNativeLoaded() && keyBoundsMap.isNotEmpty()) {
            try {
                val codes = keyBoundsMap.keys.toIntArray()
                val lefts = keyBoundsMap.values.map { it.left }.toIntArray()
                val tops = keyBoundsMap.values.map { it.top }.toIntArray()
                val rights = keyBoundsMap.values.map { it.right }.toIntArray()
                val bottoms = keyBoundsMap.values.map { it.bottom }.toIntArray()

                nativePtr = NativeProximityInfo.setProximityInfoNative(
                    displayWidth = keyWidth * gridWidth,
                    displayHeight = keyHeight * gridHeight,
                    gridWidth = gridWidth,
                    gridHeight = gridHeight,
                    keyWidth = keyWidth,
                    keyHeight = keyHeight,
                    keyCodes = codes,
                    keyLefts = lefts,
                    keyTops = tops,
                    keyRights = rights,
                    keyBottoms = bottoms
                )
            } catch (e: Throwable) {
                nativePtr = 0L
            }
        }
    }

    companion object {
        val EMPTY = ProximityInfo()
    }

    fun getKeyBounds(codePoint: Int): KeyRect? = keyBoundsMap[codePoint]

    fun calculateSpatialDistanceScore(codePoint: Int, touchX: Int, touchY: Int): Double {
        if (touchX < 0 || touchY < 0 || keyBoundsMap.isEmpty()) return 1.0
        val rect = keyBoundsMap[codePoint] ?: return 0.5
        val centerX = rect.centerX()
        val centerY = rect.centerY()
        val dx = (touchX - centerX).toDouble()
        val dy = (touchY - centerY).toDouble()
        val distSq = dx * dx + dy * dy
        val sigmaSq = (keyWidth * keyWidth / 4.0)
        return exp(-distSq / (2.0 * sigmaSq))
    }

    fun release() {
        if (nativePtr != 0L) {
            NativeProximityInfo.releaseProximityInfoNative(nativePtr)
            nativePtr = 0L
        }
    }
}

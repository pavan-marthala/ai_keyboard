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

package com.pk.ai_keyboard.ui.aosp.morekeys

/**
 * A key detector for [MoreKeysKeyboardView] that provides sliding hit-detection
 * with a customizable slide allowance margin.
 * Adapted from AOSP LatinIME [MoreKeysDetector.java].
 */
class MoreKeysDetector(
    private val slideAllowance: Float = 40f
) {
    private var keyboard: MoreKeysKeyboard? = null

    fun setKeyboard(keyboard: MoreKeysKeyboard) {
        this.keyboard = keyboard
    }

    /**
     * Detects which key is hit by the touch point at (x, y).
     *
     * @param x Touch X coordinate in the keyboard's coordinate system.
     * @param y Touch Y coordinate in the keyboard's coordinate system.
     * @return The hit [AospKey], or null if touch is outside allowable bounds.
     */
    fun detectHitKey(x: Int, y: Int): AospKey? {
        val currentKeyboard = keyboard ?: return null
        val keys = currentKeyboard.keys
        if (keys.isEmpty()) return null

        // 1. Direct hit check
        for (key in keys) {
            if (key.contains(x, y)) {
                return key
            }
        }

        // 2. Sliding allowance check (nearest key within slide allowance)
        var nearestKey: AospKey? = null
        var minDistance = Float.MAX_VALUE

        for (key in keys) {
            val dist = key.distanceTo(x, y)
            if (dist <= slideAllowance && dist < minDistance) {
                minDistance = dist
                nearestKey = key
            }
        }

        return nearestKey
    }
}


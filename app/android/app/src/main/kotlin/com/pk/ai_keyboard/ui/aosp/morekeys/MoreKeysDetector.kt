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

import kotlin.math.max

/**
 * A key detector for [MoreKeysKeyboardView] that provides sliding hit-detection
 * with a customizable slide allowance margin.
 * Adapted from AOSP LatinIME [MoreKeysDetector.java].
 */
class MoreKeysDetector(
    private val slideAllowance: Float = 48f
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

        // 2. Cancellation boundary checks:
        // Allow the user to drag horizontally and vertically within reasonable reach.
        // Below the popup: allow sliding anywhere on the keyboard below the popup (up to 400px).
        // Above the popup: allow up to 2 * slideAllowance.
        // Left / right: allow up to 2 * slideAllowance.
        val maxVerticalReachBelow = 400
        if (y > currentKeyboard.occupiedHeight + maxVerticalReachBelow ||
            y < -slideAllowance * 2 ||
            x < -slideAllowance * 2 ||
            x > currentKeyboard.occupiedWidth + slideAllowance * 2
        ) {
            return null
        }

        // 3. Project touch onto keys grid:
        // When touch is below the popup (e.g. finger still on the parent key or sliding across
        // the keyboard below), project y to the bottom row of keys.
        val effectiveY = when {
            y > currentKeyboard.occupiedHeight -> currentKeyboard.occupiedHeight - 1
            y < 0 -> 0
            else -> y
        }
        val effectiveX = x.coerceIn(0, max(0, currentKeyboard.occupiedWidth - 1))

        // Direct hit on projected coordinates
        for (key in keys) {
            if (key.contains(effectiveX, effectiveY)) {
                return key
            }
        }

        // Nearest key fallback
        var nearestKey: AospKey? = null
        var minDistance = Float.MAX_VALUE

        for (key in keys) {
            val dist = key.distanceTo(effectiveX, effectiveY)
            if (dist < minDistance) {
                minDistance = dist
                nearestKey = key
            }
        }

        return nearestKey
    }
}


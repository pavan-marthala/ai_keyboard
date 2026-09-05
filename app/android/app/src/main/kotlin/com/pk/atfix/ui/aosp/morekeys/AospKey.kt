/*
 * Copyright (C) 2010 The Android Open Source Project
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
import kotlin.math.hypot

/**
 * Lightweight representation of a virtual key used by [MoreKeysKeyboard] and [MoreKeysKeyboardView].
 */
open class AospKey(
    var x: Int = 0,
    var y: Int = 0,
    var width: Int = 0,
    var height: Int = 0,
    val code: Int = 0,
    val label: String = "",
    val outputText: String? = null,
    val moreKeys: List<MoreKeySpec> = emptyList(),
    val hasNoPanelAutoMoreKey: Boolean = false
) {
    var isPressed: Boolean = false
        private set

    fun onPressed() {
        isPressed = true
    }

    fun onReleased() {
        isPressed = false
    }

    fun contains(px: Int, py: Int): Boolean {
        return px in x until (x + width) && py in y until (y + height)
    }

    fun distanceTo(px: Int, py: Int): Float {
        val cx = x + width / 2f
        val cy = y + height / 2f
        val dx = max(0f, kotlin.math.abs(px - cx) - width / 2f)
        val dy = max(0f, kotlin.math.abs(py - cy) - height / 2f)
        return hypot(dx, dy)
    }
}


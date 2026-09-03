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

package com.pk.ai_keyboard.ui.aosp.morekeys

interface KeyboardActionListener {
    /**
     * Called when the user presses a key.
     */
    fun onPressKey(primaryCode: Int, repeatCount: Int, isSinglePointer: Boolean)

    /**
     * Called when the user releases a key.
     */
    fun onReleaseKey(primaryCode: Int, withSliding: Boolean)

    /**
     * Send a key code to the listener.
     */
    fun onCodeInput(primaryCode: Int, x: Int, y: Int, isKeyRepeat: Boolean)

    /**
     * Sends a sequence of characters to the listener.
     */
    fun onTextInput(text: CharSequence?)

    companion object {
        @JvmField
        val EMPTY_LISTENER: KeyboardActionListener = object : KeyboardActionListener {
            override fun onPressKey(primaryCode: Int, repeatCount: Int, isSinglePointer: Boolean) {}
            override fun onReleaseKey(primaryCode: Int, withSliding: Boolean) {}
            override fun onCodeInput(primaryCode: Int, x: Int, y: Int, isKeyRepeat: Boolean) {}
            override fun onTextInput(text: CharSequence?) {}
        }
    }
}


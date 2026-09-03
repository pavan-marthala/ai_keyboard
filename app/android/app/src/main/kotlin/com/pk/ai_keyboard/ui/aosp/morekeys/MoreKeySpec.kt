/*
 * Copyright (C) 2012 The Android Open Source Project
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
 * Encapsulates the specification for a single alternative key in the More Keys popup.
 *
 * Supports AOSP specification semantics:
 * - Comma-delimited list of keys (e.g. "1,¹,₁")
 * - Escaped commas with backslash ("\\,")
 * - Escaped backslashes ("\\\\")
 * - "!noPanelAutoMoreKey!" marker indicating that the single alternative should auto-commit
 *   directly upon long-press timeout without opening the popup panel.
 */
data class MoreKeySpec(
    val code: Int,
    val label: String,
    val outputText: String? = null
) {
    companion object {
        const val NO_PANEL_AUTO_MORE_KEY = "!noPanelAutoMoreKey!"

        /**
         * Parses a moreKeys specification string into a list of [MoreKeySpec]s and determines
         * whether the "!noPanelAutoMoreKey!" directive was specified.
         */
        fun parseMoreKeys(spec: String?): Pair<List<MoreKeySpec>, Boolean> {
            if (spec.isNullOrEmpty()) {
                return Pair(emptyList(), false)
            }

            val tokens = splitTokens(spec)
            var hasNoPanelAuto = false
            val specs = mutableListOf<MoreKeySpec>()

            for (rawToken in tokens) {
                val token = rawToken.trim()
                if (token.isEmpty()) continue

                if (token == NO_PANEL_AUTO_MORE_KEY) {
                    hasNoPanelAuto = true
                    continue
                }

                // If token contains a '|' separator (e.g., "label|outputText") and isn't just the pipe symbol itself
                val label: String
                val outputText: String?
                if (token.length > 1 && token.contains('|') && !token.startsWith("\\|")) {
                    val parts = token.split('|', limit = 2)
                    if (parts[0].isNotEmpty()) {
                        label = parts[0]
                        outputText = parts[1]
                    } else {
                        label = token
                        outputText = null
                    }
                } else {
                    label = token
                    outputText = if (token.length > 1) token else null
                }

                if (label.isEmpty()) continue

                val code = if (label.length == 1) {
                    label[0].code
                } else {
                    label.codePointAt(0)
                }

                specs.add(MoreKeySpec(code = code, label = label, outputText = outputText))
            }

            // Deduplicate alternatives based on output text/label so no redundant entries exist
            val uniqueSpecs = mutableListOf<MoreKeySpec>()
            val seen = mutableSetOf<String>()
            for (spec in specs) {
                val keyId = spec.outputText ?: spec.label
                if (seen.add(keyId)) {
                    uniqueSpecs.add(spec)
                }
            }

            return Pair(uniqueSpecs, hasNoPanelAuto)
        }

        /**
         * Splits a string by unescaped commas.
         */
        private fun splitTokens(spec: String): List<String> {
            val tokens = mutableListOf<String>()
            val current = StringBuilder()
            var escaping = false

            for (i in 0 until spec.length) {
                val c = spec[i]
                if (escaping) {
                    current.append(c)
                    escaping = false
                } else if (c == '\\') {
                    escaping = true
                } else if (c == ',') {
                    tokens.add(current.toString())
                    current.setLength(0)
                } else {
                    current.append(c)
                }
            }
            if (escaping) {
                current.append('\\')
            }
            if (current.isNotEmpty()) {
                tokens.add(current.toString())
            }

            return tokens
        }
    }
}


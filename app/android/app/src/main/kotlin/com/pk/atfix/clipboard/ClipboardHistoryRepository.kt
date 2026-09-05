package com.pk.atfix.clipboard

class ClipboardHistoryRepository(
    private val maxItems: Int = MAX_HISTORY_ITEMS
) {
    companion object {
        const val MAX_HISTORY_ITEMS = 20
    }

    private val items = mutableListOf<String>()

    fun getItems(): List<String> {
        return items.toList()
    }

    fun addClip(text: String): Boolean {
        val trimmed = text.trim()
        if (trimmed.isEmpty()) return false

        items.remove(trimmed)
        items.add(0, trimmed)

        while (items.size > maxItems) {
            items.removeAt(items.size - 1)
        }
        return true
    }

    fun clear() {
        items.clear()
    }

    fun toJson(): String {
        val sb = StringBuilder()
        sb.append("[")
        for (i in items.indices) {
            sb.append("\"").append(escapeJson(items[i])).append("\"")
            if (i < items.size - 1) {
                sb.append(",")
            }
        }
        sb.append("]")
        return sb.toString()
    }

    fun loadFromJson(jsonStr: String?) {
        items.clear()
        if (jsonStr.isNullOrBlank() || jsonStr.trim() == "[]") return

        try {
            val content = jsonStr.trim()
            if (content.startsWith("[") && content.endsWith("]")) {
                val inner = content.substring(1, content.length - 1).trim()
                if (inner.isEmpty()) return

                val tokens = parseJsonStringArray(inner)
                for (token in tokens.reversed()) {
                    addClip(token)
                }
            }
        } catch (e: Exception) {
            // Ignore parse failures
        }
    }

    private fun escapeJson(str: String): String {
        return str.replace("\\", "\\\\")
            .replace("\"", "\\\"")
            .replace("\n", "\\n")
            .replace("\r", "\\r")
            .replace("\t", "\\t")
    }

    private fun parseJsonStringArray(raw: String): List<String> {
        val result = mutableListOf<String>()
        val sb = StringBuilder()
        var inQuotes = false
        var isEscaped = false

        for (i in raw.indices) {
            val c = raw[i]
            if (isEscaped) {
                when (c) {
                    'n' -> sb.append('\n')
                    'r' -> sb.append('\r')
                    't' -> sb.append('\t')
                    '"' -> sb.append('"')
                    '\\' -> sb.append('\\')
                    else -> sb.append(c)
                }
                isEscaped = false
            } else if (c == '\\') {
                isEscaped = true
            } else if (c == '"') {
                if (inQuotes) {
                    result.add(sb.toString())
                    sb.setLength(0)
                    inQuotes = false
                } else {
                    inQuotes = true
                }
            } else if (inQuotes) {
                sb.append(c)
            }
        }
        return result
    }
}


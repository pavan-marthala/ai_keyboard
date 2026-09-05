package com.pk.atfix.gif

import org.json.JSONArray
import org.json.JSONObject

class RecentGifRepository(private val maxItems: Int = 20) {

    private val items = mutableListOf<GifItem>()

    fun getItems(): List<GifItem> = items.toList()

    fun addRecent(gif: GifItem) {
        items.removeAll { it.id == gif.id }
        items.add(0, gif)
        while (items.size > maxItems) {
            items.removeAt(items.size - 1)
        }
    }

    fun clear() {
        items.clear()
    }

    fun toJson(): String {
        val array = JSONArray()
        for (gif in items) {
            val obj = JSONObject().apply {
                put("id", gif.id)
                put("previewUrl", gif.previewUrl)
                put("contentUrl", gif.contentUrl)
                put("width", gif.width)
                put("height", gif.height)
                if (gif.title != null) put("title", gif.title)
                if (gif.sendAnalyticsUrl != null) put("sendAnalyticsUrl", gif.sendAnalyticsUrl)
            }
            array.put(obj)
        }
        return array.toString()
    }

    fun loadFromJson(jsonStr: String?) {
        items.clear()
        if (jsonStr.isNullOrBlank()) return
        try {
            val array = JSONArray(jsonStr)
            for (i in 0 until array.length()) {
                val obj = array.optJSONObject(i) ?: continue
                items.add(
                    GifItem(
                        id = obj.optString("id"),
                        previewUrl = obj.optString("previewUrl"),
                        contentUrl = obj.optString("contentUrl"),
                        width = obj.optInt("width", 200),
                        height = obj.optInt("height", 200),
                        title = obj.optString("title", null),
                        sendAnalyticsUrl = obj.optString("sendAnalyticsUrl", null)
                    )
                )
            }
        } catch (e: Exception) {
            items.clear()
        }
    }
}


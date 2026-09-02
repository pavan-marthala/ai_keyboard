package com.pk.ai_keyboard.gif

import android.net.Uri
import android.util.Log
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL

class GiphyGifProvider(
    private val apiKeyProvider: () -> String = { GiphyConfig.apiKey }
) : GifProvider {

    companion object {
        private const val TAG = "GiphyGifProvider"
    }

    override suspend fun getTrending(offset: Int, limit: Int): GifPage {
        val urlStr = Uri.parse("${GiphyConfig.BASE_URL}/trending").buildUpon()
            .appendQueryParameter("api_key", apiKeyProvider())
            .appendQueryParameter("limit", limit.toString())
            .appendQueryParameter("offset", offset.toString())
            .appendQueryParameter("rating", GiphyConfig.RATING)
            .build().toString()

        return executeRequest(urlStr, offset)
    }

    override suspend fun searchGifs(query: String, offset: Int, limit: Int): GifPage {
        val trimmedQuery = query.trim()
        if (trimmedQuery.isEmpty()) {
            return getTrending(offset, limit)
        }

        val urlStr = Uri.parse("${GiphyConfig.BASE_URL}/search").buildUpon()
            .appendQueryParameter("api_key", apiKeyProvider())
            .appendQueryParameter("q", trimmedQuery)
            .appendQueryParameter("limit", limit.toString())
            .appendQueryParameter("offset", offset.toString())
            .appendQueryParameter("rating", GiphyConfig.RATING)
            .build().toString()

        return executeRequest(urlStr, offset)
    }

    private fun executeRequest(urlStr: String, requestedOffset: Int): GifPage {
        var connection: HttpURLConnection? = null
        try {
            val url = URL(urlStr)
            connection = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "GET"
                connectTimeout = GiphyConfig.CONNECT_TIMEOUT_MS
                readTimeout = GiphyConfig.READ_TIMEOUT_MS
                doInput = true
            }

            val responseCode = connection.responseCode
            if (responseCode !in 200..299) {
                Log.w(TAG, "GIPHY API HTTP Error Code: $responseCode")
                return GifPage(emptyList(), 0, requestedOffset, 0)
            }

            val reader = BufferedReader(InputStreamReader(connection.inputStream))
            val sb = StringBuilder()
            var line: String?
            while (reader.readLine().also { line = it } != null) {
                sb.append(line)
            }

            return parseJsonResponse(sb.toString(), requestedOffset)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to fetch GIFs from GIPHY")
            return GifPage(emptyList(), 0, requestedOffset, 0)
        } finally {
            connection?.disconnect()
        }
    }

    private fun parseJsonResponse(jsonStr: String, requestedOffset: Int): GifPage {
        val root = JSONObject(jsonStr)
        val dataArray = root.optJSONArray("data") ?: return GifPage(emptyList(), 0, requestedOffset, 0)

        val items = mutableListOf<GifItem>()
        for (i in 0 until dataArray.length()) {
            val obj = dataArray.optJSONObject(i) ?: continue
            val id = obj.optString("id", "")
            val title = obj.optString("title", null)

            val images = obj.optJSONObject("images") ?: continue
            val previewObj = images.optJSONObject("fixed_width_small")
                ?: images.optJSONObject("fixed_width")
                ?: images.optJSONObject("downsized_thumbnail")
                ?: continue

            val contentObj = images.optJSONObject("downsized")
                ?: images.optJSONObject("original")
                ?: previewObj

            val previewUrl = previewObj.optString("url", "")
            val contentUrl = contentObj.optString("url", "")

            if (previewUrl.isEmpty() || contentUrl.isEmpty()) continue

            val width = previewObj.optInt("width", 200)
            val height = previewObj.optInt("height", 200)

            val analyticsObj = obj.optJSONObject("analytics")
            val onSendObj = analyticsObj?.optJSONObject("onsend")
            val sendAnalyticsUrl = onSendObj?.optString("url", null)

            items.add(
                GifItem(
                    id = id,
                    previewUrl = previewUrl,
                    contentUrl = contentUrl,
                    width = width,
                    height = height,
                    title = title,
                    sendAnalyticsUrl = sendAnalyticsUrl
                )
            )
        }

        val paginationObj = root.optJSONObject("pagination")
        val totalCount = paginationObj?.optInt("total_count", items.size) ?: items.size
        val offset = paginationObj?.optInt("offset", requestedOffset) ?: requestedOffset
        val count = paginationObj?.optInt("count", items.size) ?: items.size

        return GifPage(items, totalCount, offset, count)
    }
}


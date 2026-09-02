package com.pk.ai_keyboard.gif

import com.pk.ai_keyboard.BuildConfig

object GiphyConfig {
    val apiKey: String
        get() = BuildConfig.GIPHY_API_KEY.ifEmpty { "dc6zaTOxFJmzC" }

    const val BASE_URL = "https://api.giphy.com/v1/gifs"
    const val RATING = "g"
    const val CONNECT_TIMEOUT_MS = 10000
    const val READ_TIMEOUT_MS = 10000
}


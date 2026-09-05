package com.pk.atfix.gif

interface GifProvider {
    suspend fun getTrending(offset: Int = 0, limit: Int = 20): GifPage
    suspend fun searchGifs(query: String, offset: Int = 0, limit: Int = 20): GifPage
}


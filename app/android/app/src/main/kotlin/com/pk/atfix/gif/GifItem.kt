package com.pk.atfix.gif

data class GifItem(
    val id: String,
    val previewUrl: String,
    val contentUrl: String,
    val width: Int = 200,
    val height: Int = 200,
    val title: String? = null,
    val sendAnalyticsUrl: String? = null
)

data class GifPage(
    val items: List<GifItem>,
    val totalCount: Int,
    val offset: Int,
    val count: Int
)

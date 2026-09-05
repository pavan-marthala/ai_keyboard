package com.pk.atfix.keyboard

import android.content.Context

interface KeyValueStorage {
    fun getInt(key: String, defaultValue: Int): Int
    fun putInt(key: String, value: Int)
    fun remove(key: String)
}

class SharedPreferencesKeyValueStorage(
    private val context: Context,
    private val name: String
) : KeyValueStorage {
    private val prefs by lazy {
        context.getSharedPreferences(name, Context.MODE_PRIVATE)
    }

    override fun getInt(key: String, defaultValue: Int): Int {
        return prefs.getInt(key, defaultValue)
    }

    override fun putInt(key: String, value: Int) {
        prefs.edit().putInt(key, value).apply()
    }

    override fun remove(key: String) {
        prefs.edit().remove(key).apply()
    }
}

class InMemoryKeyValueStorage : KeyValueStorage {
    private val map = mutableMapOf<String, Int>()

    override fun getInt(key: String, defaultValue: Int): Int {
        return map[key] ?: defaultValue
    }

    override fun putInt(key: String, value: Int) {
        map[key] = value
    }

    override fun remove(key: String) {
        map.remove(key)
    }
}

class KeyboardHeightRepository(
    private val storage: KeyValueStorage,
    val defaultHeightDp: Int = DEFAULT_HEIGHT_DP,
    val minHeightDp: Int = MIN_HEIGHT_DP,
    val maxHeightDp: Int = MAX_HEIGHT_DP
) {
    constructor(context: Context) : this(
        SharedPreferencesKeyValueStorage(context, PREFS_NAME)
    )

    companion object {
        const val PREFS_NAME = "atfix_height_prefs"
        const val KEY_HEIGHT_DP = "keyboard_height_dp"

        const val DEFAULT_HEIGHT_DP = 216
        const val MIN_HEIGHT_DP = 150
        const val MAX_HEIGHT_DP = 350
    }

    fun getHeight(): Int {
        val saved = storage.getInt(KEY_HEIGHT_DP, defaultHeightDp)
        return saved.coerceIn(minHeightDp, maxHeightDp)
    }

    fun setHeight(heightDp: Int): Int {
        val sanitized = heightDp.coerceIn(minHeightDp, maxHeightDp)
        storage.putInt(KEY_HEIGHT_DP, sanitized)
        return sanitized
    }

    fun reset(): Int {
        storage.remove(KEY_HEIGHT_DP)
        return defaultHeightDp
    }
}

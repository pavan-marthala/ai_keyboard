package com.pk.ai_keyboard.gif

import android.content.Context
import android.content.SharedPreferences
import android.util.Log

class RecentGifManager(
    private val context: Context,
    maxItems: Int = 20
) {
    companion object {
        private const val TAG = "RecentGifManager"
        private const val PREFS_NAME = "ai_keyboard_recent_gifs_prefs"
        private const val KEY_RECENTS = "recent_gifs_json"
    }

    private val repository = RecentGifRepository(maxItems)

    private val prefs: SharedPreferences by lazy {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    init {
        loadRecents()
    }

    fun getRecents(): List<GifItem> {
        return repository.getItems()
    }

    fun addRecent(gif: GifItem) {
        repository.addRecent(gif)
        saveRecents()
    }

    private fun loadRecents() {
        try {
            val json = prefs.getString(KEY_RECENTS, null)
            repository.loadFromJson(json)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to load recent GIFs")
        }
    }

    private fun saveRecents() {
        try {
            prefs.edit().putString(KEY_RECENTS, repository.toJson()).apply()
        } catch (e: Exception) {
            Log.w(TAG, "Failed to save recent GIFs")
        }
    }
}

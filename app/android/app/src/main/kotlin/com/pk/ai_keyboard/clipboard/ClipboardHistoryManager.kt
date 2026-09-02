package com.pk.ai_keyboard.clipboard

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.SharedPreferences
import android.util.Log

class ClipboardHistoryManager(
    private val context: Context,
    val repository: ClipboardHistoryRepository = ClipboardHistoryRepository()
) {

    companion object {
        private const val TAG = "ClipboardHistoryManager"
        private const val PREFS_NAME = "ai_keyboard_clipboard_prefs"
        private const val KEY_HISTORY = "clipboard_history_json"
    }

    private var clipboardManager: ClipboardManager? = null
    private val prefs: SharedPreferences by lazy {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    var onHistoryUpdated: ((List<String>) -> Unit)? = null

    private val clipChangedListener = ClipboardManager.OnPrimaryClipChangedListener {
        checkCurrentPrimaryClip()
    }

    init {
        loadPersistedHistory()
        setupClipboardListener()
    }

    private fun setupClipboardListener() {
        try {
            clipboardManager = context.getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
            clipboardManager?.addPrimaryClipChangedListener(clipChangedListener)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to register ClipboardManager listener")
        }
    }

    fun checkCurrentPrimaryClip() {
        try {
            val clip: ClipData? = clipboardManager?.primaryClip
            if (clip != null && clip.itemCount > 0) {
                val item = clip.getItemAt(0)
                val text = item.coerceToText(context)?.toString()
                if (!text.isNullOrBlank()) {
                    val added = repository.addClip(text)
                    if (added) {
                        savePersistedHistory()
                        onHistoryUpdated?.invoke(repository.getItems())
                    }
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to read primary clip")
        }
    }

    fun getHistory(): List<String> {
        return repository.getItems()
    }

    fun clearHistory() {
        repository.clear()
        savePersistedHistory()
        onHistoryUpdated?.invoke(repository.getItems())
    }

    fun close() {
        try {
            clipboardManager?.removePrimaryClipChangedListener(clipChangedListener)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to unregister ClipboardManager listener")
        }
    }

    private fun loadPersistedHistory() {
        try {
            val json = prefs.getString(KEY_HISTORY, null)
            repository.loadFromJson(json)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to load persisted clipboard history")
        }
    }

    private fun savePersistedHistory() {
        try {
            val json = repository.toJson()
            prefs.edit().putString(KEY_HISTORY, json).apply()
        } catch (e: Exception) {
            Log.w(TAG, "Failed to save persisted clipboard history")
        }
    }
}


package com.pk.atfix.keyboard

import android.content.Context
import android.content.SharedPreferences

class NumberRowRepository(
    context: Context
) {
    private val prefs: SharedPreferences by lazy {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    companion object {
        private const val PREFS_NAME = "atfix_settings_prefs"
        private const val KEY_USE_NUMBERS = "use_numbers_enabled"
        private const val DEFAULT_USE_NUMBERS = false
    }

    fun getUseNumbers(): Boolean {
        return prefs.getBoolean(KEY_USE_NUMBERS, DEFAULT_USE_NUMBERS)
    }

    fun setUseNumbers(enabled: Boolean): Boolean {
        prefs.edit().putBoolean(KEY_USE_NUMBERS, enabled).apply()
        return true
    }
}

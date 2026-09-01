package com.pk.ai_keyboard.ui.theme

import android.content.Context
import android.content.res.Configuration
import android.graphics.Color

data class KeyboardTheme(
    val backgroundColor: Int,
    val toolbarColor: Int,
    val keyColor: Int,
    val keyPressedColor: Int,
    val specialKeyColor: Int,
    val textColor: Int,
    val secondaryTextColor: Int,
    val accentColor: Int,
    val dividerColor: Int
) {
    companion object {
        val Light = KeyboardTheme(
            backgroundColor = Color.parseColor("#ECEFF1"),
            toolbarColor = Color.parseColor("#FFFFFF"),
            keyColor = Color.parseColor("#FFFFFF"),
            keyPressedColor = Color.parseColor("#CFD8DC"),
            specialKeyColor = Color.parseColor("#D6DBDF"),
            textColor = Color.parseColor("#263238"),
            secondaryTextColor = Color.parseColor("#546E7A"),
            accentColor = Color.parseColor("#673AB7"),
            dividerColor = Color.parseColor("#CFD8DC")
        )

        val Dark = KeyboardTheme(
            backgroundColor = Color.parseColor("#1E1E2E"),
            toolbarColor = Color.parseColor("#282A36"),
            keyColor = Color.parseColor("#313244"),
            keyPressedColor = Color.parseColor("#45475A"),
            specialKeyColor = Color.parseColor("#3B4252"),
            textColor = Color.parseColor("#F8F8F2"),
            secondaryTextColor = Color.parseColor("#A6ADC8"),
            accentColor = Color.parseColor("#BD93F9"),
            dividerColor = Color.parseColor("#44475A")
        )

        fun current(context: Context): KeyboardTheme {
            val nightModeFlags = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
            return if (nightModeFlags == Configuration.UI_MODE_NIGHT_YES) Dark else Light
        }
    }
}


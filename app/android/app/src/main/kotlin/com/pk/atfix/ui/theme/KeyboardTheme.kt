package com.pk.atfix.ui.theme

import android.content.Context
import android.content.res.Configuration
import android.graphics.Color

data class KeyboardTheme(
    val backgroundColor: Int,
    val toolbarColor: Int,
    val keyColor: Int,
    val keyPressedColor: Int,
    val specialKeyColor: Int,
    val specialKeyPressedColor: Int,
    val spaceKeyColor: Int,
    val textColor: Int,
    val secondaryTextColor: Int,
    val accentColor: Int,
    val accentColorAlt: Int,
    val dividerColor: Int,
    val keyStrokeColor: Int,
    val chipTextColor: Int
) {
    companion object {
        // Soft, iOS/Material-3-inspired light palette — off-white background so
        // white key caps read as "floating" cards rather than blending flat.
        val Light = KeyboardTheme(
            backgroundColor = Color.parseColor("#E4E7EC"),
            toolbarColor = Color.parseColor("#F7F8FA"),
            keyColor = Color.parseColor("#FFFFFF"),
            keyPressedColor = Color.parseColor("#E1DFFB"),
            specialKeyColor = Color.parseColor("#DEE1E8"),
            specialKeyPressedColor = Color.parseColor("#CBD0DA"),
            spaceKeyColor = Color.parseColor("#FFFFFF"),
            textColor = Color.parseColor("#1C1D21"),
            secondaryTextColor = Color.parseColor("#6B7280"),
            accentColor = Color.parseColor("#6C5CE7"),
            accentColorAlt = Color.parseColor("#8E7CFF"),
            dividerColor = Color.parseColor("#D6D9E0"),
            keyStrokeColor = Color.parseColor("#00000000"),
            chipTextColor = Color.parseColor("#FFFFFF")
        )

        // Deep, slightly desaturated dark palette with a soft violet accent.
        // Keys get a subtle stroke since fill vs. background contrast is low.
        val Dark = KeyboardTheme(
            backgroundColor = Color.parseColor("#16161F"),
            toolbarColor = Color.parseColor("#1D1E29"),
            keyColor = Color.parseColor("#2A2B38"),
            keyPressedColor = Color.parseColor("#3D3A54"),
            specialKeyColor = Color.parseColor("#23242F"),
            specialKeyPressedColor = Color.parseColor("#34364A"),
            spaceKeyColor = Color.parseColor("#23242F"),
            textColor = Color.parseColor("#F2F2F7"),
            secondaryTextColor = Color.parseColor("#9A9CB0"),
            accentColor = Color.parseColor("#9C8CFF"),
            accentColorAlt = Color.parseColor("#7C6CF0"),
            dividerColor = Color.parseColor("#2C2D3A"),
            keyStrokeColor = Color.parseColor("#33FFFFFF"),
            chipTextColor = Color.parseColor("#16161F")
        )

        fun current(context: Context): KeyboardTheme {
            val nightModeFlags = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
            return if (nightModeFlags == Configuration.UI_MODE_NIGHT_YES) Dark else Light
        }
    }
}
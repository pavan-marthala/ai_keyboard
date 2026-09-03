package com.pk.ai_keyboard.voice

import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.provider.Settings
import android.util.Log
import android.view.inputmethod.InputMethodInfo
import android.view.inputmethod.InputMethodManager
import android.view.inputmethod.InputMethodSubtype
import com.pk.ai_keyboard.keyboard.KeyboardService
import java.util.Locale

/**
 * Dedicated helper responsible for:
 * 1. Discovering enabled input methods on the device.
 * 2. Identifying voice-capable IMEs across diverse Android vendors and configurations.
 * 3. Deterministically selecting the best candidate (preferring the system default voice IME).
 * 4. Dispatching safe input method switches via [VoiceImeSwitcher].
 */
class VoiceImeHelper(
    private val context: Context,
    private val switcher: VoiceImeSwitcher? = null
) {

    companion object {
        private const val TAG = "VoiceImeHelper"
        private const val MODE_VOICE = "voice"
        private const val SETTING_DEFAULT_VOICE_IME = "default_voice_input_method"

        // Priority score weights
        private const val SCORE_DEFAULT_VOICE_IME = 10000
        private const val SCORE_SHORTCUT_IME = 5000
        private const val SCORE_VOICE_SUBTYPE = 2000
        private const val SCORE_AUXILIARY = 1000
        private const val SCORE_VOICE_NAME = 500
    }

    private fun getInputMethodManager(): InputMethodManager? {
        return try {
            context.getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
        } catch (t: Throwable) {
            Log.w(TAG, "Failed to obtain InputMethodManager service", t)
            null
        }
    }

    /**
     * Retrieves the list of currently enabled input methods on the device.
     */
    fun getEnabledInputMethods(): List<InputMethodInfo> {
        val imm = getInputMethodManager() ?: return emptyList()
        return try {
            (imm.enabledInputMethodList ?: emptyList()).filterNotNull()
        } catch (t: Throwable) {
            Log.w(TAG, "Failed to retrieve enabledInputMethodList", t)
            emptyList()
        }
    }

    /**
     * Checks the system secure setting for the configured default voice input method ID.
     */
    private fun getDefaultVoiceInputMethodId(): String? {
        return try {
            Settings.Secure.getString(context.contentResolver, SETTING_DEFAULT_VOICE_IME)
        } catch (t: Throwable) {
            Log.w(TAG, "Failed to read $SETTING_DEFAULT_VOICE_IME from Settings.Secure", t)
            null
        }
    }

    /**
     * Queries Android's shortcut input methods map if available.
     */
    private fun getShortcutInputMethods(imm: InputMethodManager): Map<InputMethodInfo, List<InputMethodSubtype>> {
        return try {
            imm.shortcutInputMethodsAndSubtypes ?: emptyMap()
        } catch (t: Throwable) {
            Log.w(TAG, "Failed to retrieve shortcutInputMethodsAndSubtypes", t)
            emptyMap()
        }
    }

    /**
     * Discovers all enabled voice-capable input methods on the device,
     * sorted deterministically by priority score descending, then by IME ID ascending.
     */
    fun findAllVoiceImes(): List<VoiceImeCandidate> {
        val imm = getInputMethodManager() ?: return emptyList()
        val enabledImes = getEnabledInputMethods()
        Log.d(TAG, "Enabled IMEs discovered: ${enabledImes.size}")
        if (enabledImes.isEmpty()) return emptyList()

        val myPackageName = context.packageName
        val myImeId = runCatching {
            ComponentName(context, KeyboardService::class.java).flattenToShortString()
        }.getOrNull()

        val defaultVoiceId = getDefaultVoiceInputMethodId()
        val shortcutMap = getShortcutInputMethods(imm)
        val currentLocale = getCurrentSystemLocale()

        val candidates = mutableListOf<VoiceImeCandidate>()

        for (imi in enabledImes) {
            // Never select our own keyboard
            if (imi.packageName == myPackageName) continue
            if (myImeId != null && imi.id.equals(myImeId, ignoreCase = true)) continue

            val isDefault = defaultVoiceId != null && (
                imi.id.equals(defaultVoiceId, ignoreCase = true) ||
                imi.packageName.equals(defaultVoiceId, ignoreCase = true)
            )

            val isShortcut = shortcutMap.keys.any { it.id == imi.id }
            val shortcutSubtypes = shortcutMap.entries.firstOrNull { it.key.id == imi.id }?.value

            // Collect enabled subtypes
            val enabledSubtypes = try {
                (imm.getEnabledInputMethodSubtypeList(imi, true) ?: emptyList()).filterNotNull()
            } catch (t: Throwable) {
                emptyList()
            }

            // Collect declared subtypes from manifest/resource
            val declaredSubtypes = try {
                (0 until imi.subtypeCount).mapNotNull { index ->
                    runCatching { imi.getSubtypeAt(index) }.getOrNull()
                }
            } catch (t: Throwable) {
                emptyList()
            }

            val allSubtypes = (enabledSubtypes + declaredSubtypes + (shortcutSubtypes ?: emptyList())).distinct()

            // Find all voice subtypes
            val voiceSubtypes = allSubtypes.filter { subtype ->
                MODE_VOICE.equals(subtype.mode, ignoreCase = true)
            }

            // Pick the best subtype matching the user's current locale if possible
            val bestVoiceSubtype = findMatchingLocaleSubtype(voiceSubtypes, currentLocale)
                ?: voiceSubtypes.firstOrNull()
                ?: shortcutSubtypes?.firstOrNull()

            val hasVoiceSubtype = bestVoiceSubtype != null && MODE_VOICE.equals(bestVoiceSubtype.mode, ignoreCase = true)
            val isAuxiliary = bestVoiceSubtype?.isAuxiliary == true

            // Heuristic check on service name / package name / label
            val serviceName = imi.serviceName?.lowercase() ?: ""
            val packageName = imi.packageName?.lowercase() ?: ""
            val label = runCatching {
                imi.loadLabel(context.packageManager)?.toString()?.lowercase()
            }.getOrNull() ?: ""

            val hasVoiceName = serviceName.contains("voice") || serviceName.contains("speech") || serviceName.contains("dictat") ||
                              packageName.contains("voice") || packageName.contains("speech") ||
                              label.contains("voice") || label.contains("speech") || label.contains("dictat")

            val isVoiceCapable = isDefault || hasVoiceSubtype || isShortcut || hasVoiceName

            if (isVoiceCapable) {
                var score = 0
                if (isDefault) score += SCORE_DEFAULT_VOICE_IME
                if (isShortcut) score += SCORE_SHORTCUT_IME
                if (hasVoiceSubtype) score += SCORE_VOICE_SUBTYPE
                if (isAuxiliary) score += SCORE_AUXILIARY
                if (hasVoiceName) score += SCORE_VOICE_NAME

                candidates.add(
                    VoiceImeCandidate(
                        imeId = imi.id,
                        packageName = imi.packageName,
                        voiceSubtype = bestVoiceSubtype,
                        isDefaultVoiceIme = isDefault,
                        isShortcutIme = isShortcut,
                        hasVoiceSubtype = hasVoiceSubtype,
                        isAuxiliary = isAuxiliary,
                        priorityScore = score,
                        imi = imi
                    )
                )
            }
        }

        candidates.sortWith(
            compareByDescending<VoiceImeCandidate> { it.priorityScore }
                .thenBy { it.imeId }
        )

        return candidates
    }

    /**
     * Finds the highest-ranked voice-capable IME candidate, or null if none is available.
     */
    fun findBestVoiceIme(): VoiceImeCandidate? {
        val candidates = findAllVoiceImes()
        if (candidates.isEmpty()) {
            Log.d(TAG, "No voice-capable IME found among enabled IMEs")
            return null
        }
        val selected = candidates.first()
        Log.i(TAG, "Selected voice IME: id=${selected.imeId}, package=${selected.packageName}, default=${selected.isDefaultVoiceIme}, shortcut=${selected.isShortcutIme}, subtype=${selected.voiceSubtype?.hashCode()}")
        return selected
    }

    /**
     * Checks if a suitable voice-capable IME is currently enabled on the device.
     */
    fun isVoiceImeAvailable(): Boolean {
        return findBestVoiceIme() != null
    }

    /**
     * Attempts to switch to the highest-priority enabled voice IME.
     *
     * @return true if the switch request was dispatched without errors, false otherwise.
     */
    fun switchToVoiceIme(): Boolean {
        val candidate = findBestVoiceIme()
        if (candidate == null) {
            Log.d(TAG, "Switch attempt aborted: no voice IME available")
            return false
        }
        return switchToCandidate(candidate)
    }

    /**
     * Switches to a specific voice IME candidate.
     */
    fun switchToCandidate(candidate: VoiceImeCandidate): Boolean {
        Log.i(TAG, "Attempting switch to voice IME: ${candidate.imeId}")
        val effectiveSwitcher = switcher ?: (KeyboardService.activeInstance as? VoiceImeSwitcher)
        if (effectiveSwitcher == null) {
            Log.w(TAG, "No VoiceImeSwitcher or active KeyboardService available to perform switch")
            return false
        }

        return try {
            val success = effectiveSwitcher.switchToVoiceIme(candidate.imeId, candidate.voiceSubtype)
            if (success) {
                Log.i(TAG, "Switch to voice IME successful: ${candidate.imeId}")
            } else {
                Log.w(TAG, "Switch to voice IME failed: ${candidate.imeId}")
            }
            success
        } catch (t: Throwable) {
            Log.e(TAG, "Exception during switch to voice IME: ${candidate.imeId}", t)
            false
        }
    }

    private fun getCurrentSystemLocale(): Locale {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                context.resources.configuration.locales.get(0) ?: Locale.getDefault()
            } else {
                @Suppress("DEPRECATION")
                context.resources.configuration.locale ?: Locale.getDefault()
            }
        } catch (_: Throwable) {
            Locale.getDefault()
        }
    }

    private fun findMatchingLocaleSubtype(
        subtypes: List<InputMethodSubtype>,
        targetLocale: Locale
    ): InputMethodSubtype? {
        if (subtypes.isEmpty()) return null
        val targetLanguage = targetLocale.language.lowercase()
        val targetTag = targetLocale.toLanguageTag().lowercase()

        // 1. Exact language tag match (e.g. en-US)
        subtypes.firstOrNull {
            val tag = it.languageTag
            !tag.isNullOrEmpty() && tag.lowercase() == targetTag
        }?.let { return it }

        // 2. Language code match (e.g. en)
        subtypes.firstOrNull {
            @Suppress("DEPRECATION")
            val loc = it.locale
            val tag = it.languageTag
            (!loc.isNullOrEmpty() && loc.lowercase().startsWith(targetLanguage)) ||
            (!tag.isNullOrEmpty() && tag.lowercase().startsWith(targetLanguage))
        }?.let { return it }

        return null
    }
}

package com.pk.ai_keyboard.config

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * NativeSecureStorage manages hardware-backed Android KeyStore AES-256 GCM encryption
 * for user API keys and shared preferences for AI provider configurations.
 * Accessible by both Flutter Activity and Native InputMethodService.
 */
object NativeSecureStorage {

    private const val KEY_ALIAS = "AiKeyboardKeyStoreKey"
    private const val ANDROID_KEY_STORE = "AndroidKeyStore"
    private const val TRANSFORMATION = "AES/GCM/NoPadding"
    private const val GCM_TAG_LENGTH = 128

    private const val SECURE_PREFS = "ai_keyboard_secure_prefs"
    private const val CONFIG_PREFS = "ai_keyboard_config_prefs"

    private const val KEY_ACTIVE_PROVIDER = "active_provider"
    private const val KEY_ACTIVE_MODEL = "active_model"
    private const val KEY_CUSTOM_BASE_URL = "custom_base_url"

    @Synchronized
    private fun getSecretKey(): SecretKey {
        val keyStore = KeyStore.getInstance(ANDROID_KEY_STORE).apply { load(null) }
        if (!keyStore.containsAlias(KEY_ALIAS)) {
            val keyGenerator = KeyGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_AES,
                ANDROID_KEY_STORE
            )
            val keyGenParameterSpec = KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build()

            keyGenerator.init(keyGenParameterSpec)
            return keyGenerator.generateKey()
        }
        return (keyStore.getEntry(KEY_ALIAS, null) as KeyStore.SecretKeyEntry).secretKey
    }

    fun saveApiKey(context: Context, provider: String, apiKey: String) {
        val secretKey = getSecretKey()
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, secretKey)
        val iv = cipher.iv
        val encryptedBytes = cipher.doFinal(apiKey.toByteArray(Charsets.UTF_8))

        // Store IV length (1 byte) + IV + Encrypted bytes
        val combined = ByteArray(1 + iv.size + encryptedBytes.size)
        combined[0] = iv.size.toByte()
        System.arraycopy(iv, 0, combined, 1, iv.size)
        System.arraycopy(encryptedBytes, 0, combined, 1 + iv.size, encryptedBytes.size)

        val encoded = Base64.encodeToString(combined, Base64.NO_WRAP)
        val prefs = context.getSharedPreferences(SECURE_PREFS, Context.MODE_PRIVATE)
        prefs.edit().putString("key_${provider.lowercase()}", encoded).apply()
    }

    fun getApiKey(context: Context, provider: String): String? {
        val prefs = context.getSharedPreferences(SECURE_PREFS, Context.MODE_PRIVATE)
        val encoded = prefs.getString("key_${provider.lowercase()}", null) ?: return null

        return try {
            val combined = Base64.decode(encoded, Base64.NO_WRAP)
            val ivSize = combined[0].toInt()
            val iv = ByteArray(ivSize)
            System.arraycopy(combined, 1, iv, 0, ivSize)

            val encryptedSize = combined.size - 1 - ivSize
            val encryptedBytes = ByteArray(encryptedSize)
            System.arraycopy(combined, 1 + ivSize, encryptedBytes, 0, encryptedSize)

            val secretKey = getSecretKey()
            val cipher = Cipher.getInstance(TRANSFORMATION)
            val spec = GCMParameterSpec(GCM_TAG_LENGTH, iv)
            cipher.init(Cipher.DECRYPT_MODE, secretKey, spec)

            val decryptedBytes = cipher.doFinal(encryptedBytes)
            String(decryptedBytes, Charsets.UTF_8)
        } catch (e: Exception) {
            deleteApiKey(context, provider)
            null
        }
    }

    fun deleteApiKey(context: Context, provider: String) {
        val prefs = context.getSharedPreferences(SECURE_PREFS, Context.MODE_PRIVATE)
        prefs.edit().remove("key_${provider.lowercase()}").apply()
    }

    fun hasApiKey(context: Context, provider: String): Boolean {
        val key = getApiKey(context, provider)
        return !key.isNullOrBlank()
    }

    fun saveConfig(context: Context, provider: String, modelId: String, baseUrl: String? = null) {
        val prefs = context.getSharedPreferences(CONFIG_PREFS, Context.MODE_PRIVATE)
        prefs.edit()
            .putString(KEY_ACTIVE_PROVIDER, provider.lowercase())
            .putString(KEY_ACTIVE_MODEL, modelId)
            .putString(KEY_CUSTOM_BASE_URL, baseUrl)
            .apply()
    }

    fun getConfig(context: Context): AiConfiguration? {
        val prefs = context.getSharedPreferences(CONFIG_PREFS, Context.MODE_PRIVATE)
        val provider = prefs.getString(KEY_ACTIVE_PROVIDER, "openai") ?: "openai"
        val model = prefs.getString(KEY_ACTIVE_MODEL, "gpt-4o-mini") ?: "gpt-4o-mini"
        val baseUrl = prefs.getString(KEY_CUSTOM_BASE_URL, null)

        val apiKey = getApiKey(context, provider) ?: return null

        return AiConfiguration(
            provider = provider,
            apiKey = apiKey,
            model = model,
            baseUrl = baseUrl
        )
    }
}


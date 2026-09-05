package com.pk.atfix

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.pk.atfix.config.NativeSecureStorage
import com.pk.atfix.keyboard.KeyboardHeightRepository

class MainActivity : FlutterActivity() {
    private val CREDENTIALS_CHANNEL = "com.pk.atfix/credentials"
    private val KEYBOARD_CHANNEL = "com.pk.atfix/keyboard"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CREDENTIALS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveApiKey" -> {
                    val provider = call.argument<String>("provider") ?: "openai"
                    val apiKey = call.argument<String>("apiKey") ?: ""
                    NativeSecureStorage.saveApiKey(context, provider, apiKey)
                    result.success(true)
                }
                "deleteApiKey" -> {
                    val provider = call.argument<String>("provider") ?: "openai"
                    NativeSecureStorage.deleteApiKey(context, provider)
                    result.success(true)
                }
                "hasApiKey" -> {
                    val provider = call.argument<String>("provider") ?: "openai"
                    val exists = NativeSecureStorage.hasApiKey(context, provider)
                    result.success(exists)
                }
                "getApiKey" -> {
                    val provider = call.argument<String>("provider") ?: "openai"
                    val key = NativeSecureStorage.getApiKey(context, provider)
                    result.success(key)
                }
                "saveConfig" -> {
                    val provider = call.argument<String>("provider") ?: "openai"
                    val modelId = call.argument<String>("modelId") ?: "gpt-4o-mini"
                    val baseUrl = call.argument<String>("baseUrl")
                    NativeSecureStorage.saveConfig(context, provider, modelId, baseUrl)
                    result.success(true)
                }
                "saveDisabledCommands" -> {
                    val disabledList = call.argument<List<String>>("disabledTriggers") ?: emptyList()
                    com.pk.atfix.command.NativeCommandRegistry.saveDisabledCommands(context, disabledList.toSet())
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, KEYBOARD_CHANNEL).setMethodCallHandler { call, result ->
            val heightRepo = KeyboardHeightRepository(context)
            when (call.method) {
                "isAtFixActive" -> {
                    try {
                        val currentIme = Settings.Secure.getString(
                            contentResolver,
                            Settings.Secure.DEFAULT_INPUT_METHOD
                        )
                        val isActive = currentIme != null && currentIme.contains(packageName)
                        result.success(isActive)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "getCurrentInputMethod" -> {
                    try {
                        val currentIme = Settings.Secure.getString(
                            contentResolver,
                            Settings.Secure.DEFAULT_INPUT_METHOD
                        )
                        result.success(currentIme ?: "")
                    } catch (e: Exception) {
                        result.success("")
                    }
                }
                "openKeyboardSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_INPUT_METHOD_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INTENT_ERROR", e.message, null)
                    }
                }
                "getKeyboardHeight" -> {
                    result.success(heightRepo.getHeight())
                }
                "setKeyboardHeight" -> {
                    val heightDp = call.argument<Int>("height") ?: KeyboardHeightRepository.DEFAULT_HEIGHT_DP
                    val applied = heightRepo.setHeight(heightDp)
                    result.success(applied)
                }
                "resetKeyboardHeight" -> {
                    val defaultHeight = heightRepo.reset()
                    result.success(defaultHeight)
                }
                "getUseNumbers" -> {
                    val numberRepo = com.pk.atfix.keyboard.NumberRowRepository(context)
                    result.success(numberRepo.getUseNumbers())
                }
                "setUseNumbers" -> {
                    val enabled = call.argument<Boolean>("useNumbers") ?: false
                    val numberRepo = com.pk.atfix.keyboard.NumberRowRepository(context)
                    val applied = numberRepo.setUseNumbers(enabled)
                    com.pk.atfix.keyboard.KeyboardService.activeInstance?.updateUseNumbers(enabled)
                    result.success(applied)
                }
                else -> result.notImplemented()
            }
        }
    }
}

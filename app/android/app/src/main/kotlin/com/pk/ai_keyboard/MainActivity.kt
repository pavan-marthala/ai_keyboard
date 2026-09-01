package com.pk.ai_keyboard

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.pk.ai_keyboard.config.NativeSecureStorage

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.pk.ai_keyboard/credentials"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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
                "saveConfig" -> {
                    val provider = call.argument<String>("provider") ?: "openai"
                    val modelId = call.argument<String>("modelId") ?: "gpt-4o-mini"
                    val baseUrl = call.argument<String>("baseUrl")
                    NativeSecureStorage.saveConfig(context, provider, modelId, baseUrl)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}

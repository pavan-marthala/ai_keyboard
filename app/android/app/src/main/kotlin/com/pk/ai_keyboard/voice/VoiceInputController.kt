package com.pk.ai_keyboard.voice

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import androidx.core.content.ContextCompat
import java.util.Locale

class VoiceInputController(
    private val context: Context
) {

    companion object {
        private const val TAG = "VoiceInputController"
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private var speechRecognizer: SpeechRecognizer? = null
    private var currentSessionId: Long = 0L

    var currentState: VoiceState = VoiceState.IDLE
        private set

    var onStateChanged: ((VoiceState) -> Unit)? = null
    var onTextRecognized: ((String) -> Unit)? = null

    fun toggleVoiceInput() {
        if (currentState == VoiceState.LISTENING || currentState == VoiceState.PROCESSING) {
            stopListening()
        } else {
            startListening()
        }
    }

    fun startListening() {
        if (!mainThreadCheck { startListening() }) return

        if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            PermissionRequestActivity.onPermissionResult = { granted ->
                if (granted) {
                    startListening()
                } else {
                    setState(VoiceState.IDLE)
                }
            }
            PermissionRequestActivity.requestMicPermission(context)
            return
        }

        if (!SpeechRecognizer.isRecognitionAvailable(context)) {
            Log.w(TAG, "Speech recognition is not available on this device.")
            setState(VoiceState.ERROR)
            mainHandler.postDelayed({ setState(VoiceState.IDLE) }, 1500L)
            return
        }

        val session = ++currentSessionId
        destroyRecognizerQuietly()

        try {
            val recognizer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && SpeechRecognizer.isOnDeviceRecognitionAvailable(context)) {
                Log.i(TAG, "Using Android on-device SpeechRecognizer.")
                SpeechRecognizer.createOnDeviceSpeechRecognizer(context)
            } else {
                Log.i(TAG, "Using standard system SpeechRecognizer.")
                SpeechRecognizer.createSpeechRecognizer(context)
            }

            this.speechRecognizer = recognizer
            recognizer.setRecognitionListener(createRecognitionListener(session))

            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            }

            setState(VoiceState.LISTENING)
            recognizer.startListening(intent)
        } catch (e: Throwable) {
            Log.e(TAG, "Failed to start SpeechRecognizer", e)
            setState(VoiceState.ERROR)
            mainHandler.postDelayed({ setState(VoiceState.IDLE) }, 1500L)
        }
    }

    fun stopListening() {
        if (!mainThreadCheck { stopListening() }) return
        try {
            if (currentState == VoiceState.LISTENING) {
                setState(VoiceState.PROCESSING)
                speechRecognizer?.stopListening()
            }
        } catch (e: Throwable) {
            Log.e(TAG, "Error stopping SpeechRecognizer", e)
            setState(VoiceState.IDLE)
        }
    }

    fun destroy() {
        currentSessionId++
        if (Looper.myLooper() == Looper.getMainLooper()) {
            destroyRecognizerQuietly()
            setState(VoiceState.IDLE)
        } else {
            mainHandler.post {
                destroyRecognizerQuietly()
                setState(VoiceState.IDLE)
            }
        }
    }

    private fun setState(state: VoiceState) {
        if (currentState != state) {
            currentState = state
            onStateChanged?.invoke(state)
        }
    }

    private fun destroyRecognizerQuietly() {
        try {
            speechRecognizer?.apply {
                stopListening()
                cancel()
                destroy()
            }
        } catch (e: Throwable) {
            Log.w(TAG, "Exception during SpeechRecognizer destruction", e)
        } finally {
            speechRecognizer = null
        }
    }

    private fun mainThreadCheck(action: () -> Unit): Boolean {
        if (Looper.myLooper() != Looper.getMainLooper()) {
            mainHandler.post { action() }
            return false
        }
        return true
    }

    private fun createRecognitionListener(session: Long): RecognitionListener {
        return object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {
                if (session != currentSessionId) return
                Log.d(TAG, "SpeechRecognizer onReadyForSpeech")
            }

            override fun onBeginningOfSpeech() {
                if (session != currentSessionId) return
                Log.d(TAG, "SpeechRecognizer onBeginningOfSpeech")
                setState(VoiceState.LISTENING)
            }

            override fun onRmsChanged(rmsdB: Float) {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEndOfSpeech() {
                if (session != currentSessionId) return
                Log.d(TAG, "SpeechRecognizer onEndOfSpeech")
                setState(VoiceState.PROCESSING)
            }

            override fun onError(error: Int) {
                if (session != currentSessionId) return
                Log.w(TAG, "SpeechRecognizer onError code: $error")
                setState(VoiceState.ERROR)
                mainHandler.postDelayed({
                    if (session == currentSessionId) {
                        setState(VoiceState.IDLE)
                    }
                }, 1500L)
            }

            override fun onResults(results: Bundle?) {
                if (session != currentSessionId) return
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                val recognizedText = matches?.firstOrNull()?.trim()
                Log.i(TAG, "SpeechRecognizer onResults: $recognizedText")

                if (!recognizedText.isNullOrEmpty()) {
                    onTextRecognized?.invoke(recognizedText)
                }

                setState(VoiceState.IDLE)
            }

            override fun onPartialResults(partialResults: Bundle?) {
                if (session != currentSessionId) return
                val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                val partial = matches?.firstOrNull()?.trim()
                if (!partial.isNullOrEmpty()) {
                    Log.d(TAG, "SpeechRecognizer onPartialResults (preview only): $partial")
                }
            }

            override fun onEvent(eventType: Int, params: Bundle?) {}
        }
    }
}


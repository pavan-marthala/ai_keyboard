package com.pk.atfix.voice

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
        const val INITIAL_SILENCE_TIMEOUT_MS = 3000L
        const val LONG_IDLE_TIMEOUT_MS = 7000L
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private var speechRecognizer: SpeechRecognizer? = null
    private var currentSessionId: Long = 0L

    var isDictationModeActive: Boolean = false
        private set

    var currentState: VoiceState = VoiceState.IDLE
        private set

    var onStateChanged: ((VoiceState) -> Unit)? = null
    var onTextRecognized: ((String) -> Unit)? = null

    private val initialSilenceRunnable = Runnable {
        if (isDictationModeActive && currentState == VoiceState.LISTENING) {
            setState(VoiceState.SPEAK_NOW)
        }
    }

    private val longIdleRunnable = Runnable {
        if (isDictationModeActive && (currentState == VoiceState.LISTENING || currentState == VoiceState.SPEAK_NOW)) {
            Log.i(TAG, "Long idle timeout reached. Stopping microphone without exiting Dictation Mode.")
            stopMicrophoneKeepDictation()
        }
    }

    fun startDictationMode() {
        isDictationModeActive = true
        startListening()
    }

    fun exitDictationMode() {
        isDictationModeActive = false
        cancelTimers()
        currentSessionId++
        destroyRecognizerQuietly()
        setState(VoiceState.IDLE)
    }

    fun restartDictationFromStopped() {
        if (!isDictationModeActive) {
            isDictationModeActive = true
        }
        startListening()
    }

    fun startListening() {
        if (!mainThreadCheck { startListening() }) return

        if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            setState(VoiceState.LOADING)
            PermissionRequestActivity.onPermissionResult = { granted ->
                if (granted) {
                    startListening()
                } else {
                    if (isDictationModeActive) {
                        setState(VoiceState.MIC_STOPPED)
                    } else {
                        setState(VoiceState.IDLE)
                    }
                }
            }
            PermissionRequestActivity.requestMicPermission(context)
            return
        }

        if (!SpeechRecognizer.isRecognitionAvailable(context)) {
            Log.w(TAG, "Speech recognition is not available on this device.")
            setState(VoiceState.ERROR)
            mainHandler.postDelayed({
                if (isDictationModeActive) {
                    setState(VoiceState.MIC_STOPPED)
                } else {
                    setState(VoiceState.IDLE)
                }
            }, 1500L)
            return
        }

        val session = ++currentSessionId
        cancelTimers()
        destroyRecognizerQuietly()

        try {
            setState(VoiceState.LOADING)

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
            scheduleInitialSilenceTimer()
            scheduleLongIdleTimer()
            recognizer.startListening(intent)
        } catch (e: Throwable) {
            Log.e(TAG, "Failed to start SpeechRecognizer", e)
            setState(VoiceState.ERROR)
            mainHandler.postDelayed({
                if (isDictationModeActive) {
                    setState(VoiceState.MIC_STOPPED)
                } else {
                    setState(VoiceState.IDLE)
                }
            }, 1500L)
        }
    }

    fun stopMicrophoneKeepDictation() {
        if (!mainThreadCheck { stopMicrophoneKeepDictation() }) return
        cancelTimers()
        try {
            speechRecognizer?.stopListening()
        } catch (e: Throwable) {
            Log.w(TAG, "Error stopping SpeechRecognizer", e)
        }
        setState(VoiceState.MIC_STOPPED)
    }

    fun destroy() {
        exitDictationMode()
    }

    private fun setState(state: VoiceState) {
        if (currentState != state) {
            currentState = state
            onStateChanged?.invoke(state)
        }
    }

    private fun cancelTimers() {
        mainHandler.removeCallbacks(initialSilenceRunnable)
        mainHandler.removeCallbacks(longIdleRunnable)
    }

    private fun scheduleInitialSilenceTimer() {
        mainHandler.removeCallbacks(initialSilenceRunnable)
        mainHandler.postDelayed(initialSilenceRunnable, INITIAL_SILENCE_TIMEOUT_MS)
    }

    private fun scheduleLongIdleTimer() {
        mainHandler.removeCallbacks(longIdleRunnable)
        mainHandler.postDelayed(longIdleRunnable, LONG_IDLE_TIMEOUT_MS)
    }

    private fun resetLongIdleTimerOnSpeechActivity() {
        mainHandler.removeCallbacks(initialSilenceRunnable)
        scheduleLongIdleTimer()
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
                Log.d(TAG, "SpeechRecognizer onBeginningOfSpeech - Speech detected")
                resetLongIdleTimerOnSpeechActivity()
                setState(VoiceState.LISTENING)
            }

            override fun onRmsChanged(rmsdB: Float) {
                if (session != currentSessionId) return
                if (rmsdB > 2.0f) {
                    resetLongIdleTimerOnSpeechActivity()
                }
            }

            override fun onBufferReceived(buffer: ByteArray?) {
                if (session != currentSessionId) return
                resetLongIdleTimerOnSpeechActivity()
            }

            override fun onEndOfSpeech() {
                if (session != currentSessionId) return
                Log.d(TAG, "SpeechRecognizer onEndOfSpeech")
                cancelTimers()
                setState(VoiceState.PROCESSING)
            }

            override fun onError(error: Int) {
                if (session != currentSessionId) return
                Log.w(TAG, "SpeechRecognizer onError code: $error")
                cancelTimers()
                setState(VoiceState.ERROR)
                mainHandler.postDelayed({
                    if (session == currentSessionId && isDictationModeActive) {
                        setState(VoiceState.MIC_STOPPED)
                    }
                }, 1500L)
            }

            override fun onResults(results: Bundle?) {
                if (session != currentSessionId) return
                cancelTimers()

                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                val recognizedText = matches?.firstOrNull()?.trim()
                Log.i(TAG, "SpeechRecognizer onResults authoritative final: $recognizedText")

                if (!recognizedText.isNullOrEmpty()) {
                    setState(VoiceState.PROCESSING)
                    onTextRecognized?.invoke(recognizedText)
                }

                if (isDictationModeActive) {
                    setState(VoiceState.LISTENING)
                    scheduleInitialSilenceTimer()
                    scheduleLongIdleTimer()
                } else {
                    setState(VoiceState.IDLE)
                }
            }

            override fun onPartialResults(partialResults: Bundle?) {
                if (session != currentSessionId) return
                resetLongIdleTimerOnSpeechActivity()
                val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                val partial = matches?.firstOrNull()?.trim()
                if (!partial.isNullOrEmpty()) {
                    Log.d(TAG, "SpeechRecognizer onPartialResults (log only, not committed): $partial")
                }
            }

            override fun onEvent(eventType: Int, params: Bundle?) {}
        }
    }
}

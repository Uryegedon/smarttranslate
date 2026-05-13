package com.smartpath.smarttranslate

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var speechRecognizer: SpeechRecognizer? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "smarttranslate/native_speech"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isOnDeviceRecognitionAvailable" -> {
                    result.success(isOnDeviceRecognitionAvailable())
                }

                "startOnDeviceRecognition" -> {
                    val localeId = call.argument<String>("localeId") ?: "en-US"
                    result.success(startOnDeviceRecognition(localeId))
                }

                "stopOnDeviceRecognition" -> {
                    speechRecognizer?.stopListening()
                    emitStatus("processing")
                    result.success(null)
                }

                "cancelOnDeviceRecognition" -> {
                    cancelOnDeviceRecognition()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "smarttranslate/native_speech/events"
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    private fun isOnDeviceRecognitionAvailable(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            SpeechRecognizer.isOnDeviceRecognitionAvailable(this)
    }

    private fun startOnDeviceRecognition(localeId: String): Boolean {
        if (!isOnDeviceRecognitionAvailable()) {
            emitError("On-device speech recognition is not available on this device.")
            return false
        }

        speechRecognizer?.destroy()
        speechRecognizer = SpeechRecognizer.createOnDeviceSpeechRecognizer(this).apply {
            setRecognitionListener(nativeRecognitionListener)
        }

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
            )
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, localeId)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, localeId)
        }

        speechRecognizer?.startListening(intent)
        emitStatus("listening")
        return true
    }

    private fun cancelOnDeviceRecognition() {
        speechRecognizer?.cancel()
        speechRecognizer?.destroy()
        speechRecognizer = null
        emitStatus("cancelled")
    }

    private val nativeRecognitionListener = object : RecognitionListener {
        override fun onReadyForSpeech(params: Bundle?) {
            emitStatus("ready")
        }

        override fun onBeginningOfSpeech() {
            emitStatus("listening")
        }

        override fun onRmsChanged(rmsdB: Float) = Unit

        override fun onBufferReceived(buffer: ByteArray?) = Unit

        override fun onEndOfSpeech() {
            emitStatus("processing")
        }

        override fun onError(error: Int) {
            emitError(errorMessage(error))
            speechRecognizer?.destroy()
            speechRecognizer = null
        }

        override fun onResults(results: Bundle?) {
            emitResult(results, true)
            emitStatus("done")
            speechRecognizer?.destroy()
            speechRecognizer = null
        }

        override fun onPartialResults(partialResults: Bundle?) {
            emitResult(partialResults, false)
        }

        override fun onEvent(eventType: Int, params: Bundle?) = Unit
    }

    private fun emitResult(bundle: Bundle?, isFinal: Boolean) {
        val matches = bundle
            ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            ?.filter { it.isNotBlank() }
            .orEmpty()

        if (matches.isEmpty()) {
            return
        }

        eventSink?.success(
            mapOf(
                "type" to "result",
                "text" to matches.first(),
                "final" to isFinal
            )
        )
    }

    private fun emitStatus(value: String) {
        eventSink?.success(
            mapOf(
                "type" to "status",
                "value" to value
            )
        )
    }

    private fun emitError(message: String) {
        eventSink?.success(
            mapOf(
                "type" to "error",
                "message" to message
            )
        )
    }

    private fun errorMessage(error: Int): String {
        return when (error) {
            SpeechRecognizer.ERROR_AUDIO -> "Speech recognizer audio input failed."
            SpeechRecognizer.ERROR_CLIENT -> "Speech recognizer client error."
            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS ->
                "Microphone permission is required for speech recognition."
            SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED ->
                "This speech language is not supported by the on-device recognizer."
            SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE ->
                "This speech language is not downloaded for on-device recognition."
            SpeechRecognizer.ERROR_NETWORK,
            SpeechRecognizer.ERROR_NETWORK_TIMEOUT ->
                "The device recognizer reported a network error."
            SpeechRecognizer.ERROR_NO_MATCH -> "No speech match was found."
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Speech recognizer is busy."
            SpeechRecognizer.ERROR_SERVER,
            SpeechRecognizer.ERROR_SERVER_DISCONNECTED ->
                "Speech recognizer service is unavailable."
            SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech was detected."
            SpeechRecognizer.ERROR_TOO_MANY_REQUESTS ->
                "Speech recognizer is receiving too many requests."
            else -> "Speech recognition failed."
        }
    }

    override fun onDestroy() {
        speechRecognizer?.destroy()
        speechRecognizer = null
        super.onDestroy()
    }
}

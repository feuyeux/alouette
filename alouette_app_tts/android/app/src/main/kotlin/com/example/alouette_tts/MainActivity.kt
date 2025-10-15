package com.example.alouette_tts

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.media.AudioManager
import android.content.Context

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.alouette_tts/audio"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setAudioStreamType" -> {
                    setAudioStreamType()
                    result.success(null)
                }
                "getMaxVolume" -> {
                    val maxVolume = getMaxVolume()
                    result.success(maxVolume)
                }
                "getCurrentVolume" -> {
                    val currentVolume = getCurrentVolume()
                    result.success(currentVolume)
                }
                "setVolume" -> {
                    val volume = call.argument<Int>("volume") ?: 0
                    setSystemVolume(volume)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun setAudioStreamType() {
        volumeControlStream = AudioManager.STREAM_MUSIC
    }

    private fun getMaxVolume(): Int {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        return audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
    }

    private fun getCurrentVolume(): Int {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        return audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
    }

    private fun setSystemVolume(volume: Int) {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, volume, 0)
    }
}

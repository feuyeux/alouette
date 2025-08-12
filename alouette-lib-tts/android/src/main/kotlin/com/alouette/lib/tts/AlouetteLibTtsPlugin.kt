package com.alouette.lib.tts

import android.content.Context
import android.media.AudioManager
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** AlouetteLibTtsPlugin */
class AlouetteLibTtsPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel
  private lateinit var context: Context
  private lateinit var audioManager: AudioManager

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.alouette.lib.tts/audio")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
    audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "setAudioStreamType" -> {
        try {
          // This method is deprecated but still needed for older Android versions
          // The audio stream type is now handled by flutter_tts internally
          result.success(true)
        } catch (e: Exception) {
          result.error("AUDIO_ERROR", "Failed to set audio stream type", e.message)
        }
      }
      "getMaxVolume" -> {
        try {
          val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
          result.success(maxVolume)
        } catch (e: Exception) {
          result.error("AUDIO_ERROR", "Failed to get max volume", e.message)
        }
      }
      "getCurrentVolume" -> {
        try {
          val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
          result.success(currentVolume)
        } catch (e: Exception) {
          result.error("AUDIO_ERROR", "Failed to get current volume", e.message)
        }
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
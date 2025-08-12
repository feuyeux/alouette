/// TTS State enumeration representing the current state of text-to-speech engine
enum TTSState {
  /// TTS engine is stopped and not speaking
  stopped,
  
  /// TTS engine is currently playing/speaking
  playing,
  
  /// TTS engine is paused
  paused,
  
  /// TTS engine has continued from pause
  continued,
}
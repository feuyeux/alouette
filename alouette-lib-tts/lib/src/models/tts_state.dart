/// Enumeration of TTS playback states
enum TTSState {
  /// TTS service is stopped and ready for new operations
  stopped,
  
  /// TTS service is ready and initialized
  ready,
  
  /// TTS service is currently playing audio
  playing,
  
  /// TTS service is paused and can be resumed
  paused,
  
  /// TTS service is currently synthesizing audio
  synthesizing,
  
  /// TTS service encountered an error
  error,
  
  /// TTS service has been disposed and is no longer usable
  disposed;

  /// Returns true if the TTS service is currently active
  bool get isActive {
    switch (this) {
      case TTSState.playing:
      case TTSState.synthesizing:
        return true;
      case TTSState.stopped:
      case TTSState.ready:
      case TTSState.paused:
      case TTSState.error:
      case TTSState.disposed:
        return false;
    }
  }

  /// Returns true if the TTS service can be paused
  bool get canPause {
    switch (this) {
      case TTSState.playing:
      case TTSState.synthesizing:
        return true;
      case TTSState.stopped:
      case TTSState.ready:
      case TTSState.paused:
      case TTSState.error:
      case TTSState.disposed:
        return false;
    }
  }

  /// Returns true if the TTS service can be resumed
  bool get canResume {
    return this == TTSState.paused;
  }

  /// Returns true if the TTS service can be stopped
  bool get canStop {
    switch (this) {
      case TTSState.playing:
      case TTSState.paused:
      case TTSState.synthesizing:
        return true;
      case TTSState.stopped:
      case TTSState.ready:
      case TTSState.error:
      case TTSState.disposed:
        return false;
    }
  }

  /// Returns the state name as a string
  String get stateName {
    switch (this) {
      case TTSState.stopped:
        return 'Stopped';
      case TTSState.ready:
        return 'Ready';
      case TTSState.playing:
        return 'Playing';
      case TTSState.paused:
        return 'Paused';
      case TTSState.synthesizing:
        return 'Synthesizing';
      case TTSState.error:
        return 'Error';
      case TTSState.disposed:
        return 'Disposed';
    }
  }
}
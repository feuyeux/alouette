/// TTS Status model representing the current state of TTS operations
///
/// This is the standardized data model used across all Alouette applications
/// for TTS status reporting. It includes comprehensive validation and serialization.
class TTSStatus {
  /// Whether TTS is currently speaking
  final bool isSpeaking;

  /// Whether TTS is currently paused
  final bool isPaused;

  /// Whether TTS is currently initializing
  final bool isInitializing;

  /// Whether TTS is ready for use
  final bool isReady;

  /// Current engine being used
  final String? currentEngine;

  /// Current voice being used
  final String? currentVoice;

  /// Current speech rate (0.1 to 3.0)
  final double speechRate;

  /// Current pitch (0.5 to 2.0)
  final double pitch;

  /// Current volume (0.0 to 1.0)
  final double volume;

  /// Error message if any
  final String? errorMessage;

  /// Timestamp of status update
  final DateTime timestamp;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  TTSStatus({
    this.isSpeaking = false,
    this.isPaused = false,
    this.isInitializing = false,
    this.isReady = false,
    this.currentEngine,
    this.currentVoice,
    this.speechRate = 1.0,
    this.pitch = 1.0,
    this.volume = 1.0,
    this.errorMessage,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create an idle status
  factory TTSStatus.idle({
    String? currentEngine,
    String? currentVoice,
    double speechRate = 1.0,
    double pitch = 1.0,
    double volume = 1.0,
  }) {
    return TTSStatus(
      isReady: true,
      currentEngine: currentEngine,
      currentVoice: currentVoice,
      speechRate: speechRate,
      pitch: pitch,
      volume: volume,
      timestamp: DateTime.now(),
    );
  }

  /// Create a speaking status
  factory TTSStatus.speaking({
    required String currentEngine,
    required String currentVoice,
    double speechRate = 1.0,
    double pitch = 1.0,
    double volume = 1.0,
  }) {
    return TTSStatus(
      isSpeaking: true,
      isReady: true,
      currentEngine: currentEngine,
      currentVoice: currentVoice,
      speechRate: speechRate,
      pitch: pitch,
      volume: volume,
      timestamp: DateTime.now(),
    );
  }

  /// Create a paused status
  factory TTSStatus.paused({
    required String currentEngine,
    required String currentVoice,
    double speechRate = 1.0,
    double pitch = 1.0,
    double volume = 1.0,
  }) {
    return TTSStatus(
      isPaused: true,
      isReady: true,
      currentEngine: currentEngine,
      currentVoice: currentVoice,
      speechRate: speechRate,
      pitch: pitch,
      volume: volume,
      timestamp: DateTime.now(),
    );
  }

  /// Create an initializing status
  factory TTSStatus.initializing({String? currentEngine}) {
    return TTSStatus(
      isInitializing: true,
      currentEngine: currentEngine,
      timestamp: DateTime.now(),
    );
  }

  /// Create an error status
  factory TTSStatus.error({
    required String errorMessage,
    String? currentEngine,
    String? currentVoice,
  }) {
    return TTSStatus(
      errorMessage: errorMessage,
      currentEngine: currentEngine,
      currentVoice: currentVoice,
      timestamp: DateTime.now(),
    );
  }

  /// Convert to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'is_speaking': isSpeaking,
      'is_paused': isPaused,
      'is_initializing': isInitializing,
      'is_ready': isReady,
      'current_engine': currentEngine,
      'current_voice': currentVoice,
      'speech_rate': speechRate,
      'pitch': pitch,
      'volume': volume,
      'error_message': errorMessage,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create from JSON representation
  factory TTSStatus.fromJson(Map<String, dynamic> json) {
    return TTSStatus(
      isSpeaking: json['is_speaking'] ?? false,
      isPaused: json['is_paused'] ?? false,
      isInitializing: json['is_initializing'] ?? false,
      isReady: json['is_ready'] ?? false,
      currentEngine: json['current_engine'],
      currentVoice: json['current_voice'],
      speechRate: (json['speech_rate'] ?? 1.0).toDouble(),
      pitch: (json['pitch'] ?? 1.0).toDouble(),
      volume: (json['volume'] ?? 1.0).toDouble(),
      errorMessage: json['error_message'],
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  /// Create a copy with modified fields
  TTSStatus copyWith({
    bool? isSpeaking,
    bool? isPaused,
    bool? isInitializing,
    bool? isReady,
    String? currentEngine,
    String? currentVoice,
    double? speechRate,
    double? pitch,
    double? volume,
    String? errorMessage,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return TTSStatus(
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isPaused: isPaused ?? this.isPaused,
      isInitializing: isInitializing ?? this.isInitializing,
      isReady: isReady ?? this.isReady,
      currentEngine: currentEngine ?? this.currentEngine,
      currentVoice: currentVoice ?? this.currentVoice,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
      errorMessage: errorMessage ?? this.errorMessage,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Validate the TTS status
  Map<String, dynamic> validate() {
    final errors = <String>[];
    final warnings = <String>[];

    // Rate validation
    if (speechRate < 0.1 || speechRate > 3.0) {
      errors.add('Speech rate must be between 0.1 and 3.0');
    }

    // Pitch validation
    if (pitch < 0.5 || pitch > 2.0) {
      errors.add('Pitch must be between 0.5 and 2.0');
    }

    // Volume validation
    if (volume < 0.0 || volume > 1.0) {
      errors.add('Volume must be between 0.0 and 1.0');
    }

    // State consistency validation
    if (isSpeaking && isPaused) {
      errors.add('Cannot be both speaking and paused simultaneously');
    }

    if (isInitializing && (isSpeaking || isPaused)) {
      errors.add('Cannot be initializing while speaking or paused');
    }

    if ((isSpeaking || isPaused) && !isReady) {
      warnings.add(
        'Speaking or paused state without being ready may indicate an issue',
      );
    }

    if (errorMessage != null &&
        errorMessage!.isNotEmpty &&
        (isSpeaking || isReady)) {
      warnings.add(
        'Error message present but status indicates normal operation',
      );
    }

    return {'isValid': errors.isEmpty, 'errors': errors, 'warnings': warnings};
  }

  /// Check if the status is valid (no validation errors)
  bool get isValid => validate()['isValid'] as bool;

  /// Check if TTS has an error
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  /// Get current state as a string
  String get stateDescription {
    if (hasError) return 'Error';
    if (isInitializing) return 'Initializing';
    if (isSpeaking) return 'Speaking';
    if (isPaused) return 'Paused';
    if (isReady) return 'Ready';
    return 'Not Ready';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TTSStatus &&
        other.isSpeaking == isSpeaking &&
        other.isPaused == isPaused &&
        other.isInitializing == isInitializing &&
        other.isReady == isReady &&
        other.currentEngine == currentEngine &&
        other.currentVoice == currentVoice &&
        other.speechRate == speechRate &&
        other.pitch == pitch &&
        other.volume == volume &&
        other.errorMessage == errorMessage &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(
      isSpeaking,
      isPaused,
      isInitializing,
      isReady,
      currentEngine,
      currentVoice,
      speechRate,
      pitch,
      volume,
      errorMessage,
      timestamp,
    );
  }

  @override
  String toString() {
    return 'TTSStatus(state: $stateDescription, engine: $currentEngine, voice: $currentVoice)';
  }
}

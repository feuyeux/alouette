/// Alouette TTS - A unified text-to-speech platform for Flutter
///
/// This library provides consistent TTS functionality across all major platforms
/// by intelligently selecting the optimal TTS implementation based on the target platform.
library alouette_tts;

// Core interfaces
export 'src/interfaces/i_tts_service.dart';
export 'src/interfaces/i_platform_detector.dart';
export 'src/interfaces/i_tts_factory.dart';

// Data models
export 'src/models/alouette_tts_config.dart';
export 'src/models/alouette_voice.dart';
export 'src/models/tts_request.dart';
export 'src/models/tts_result.dart';
export 'src/models/tts_state.dart';

// Enums
export 'src/enums/tts_platform.dart';
export 'src/enums/voice_gender.dart';
export 'src/enums/voice_quality.dart';
export 'src/enums/audio_format.dart';

// Exceptions
export 'src/exceptions/tts_exception.dart';

// Main service
export 'src/alouette_tts_service.dart';

// Error recovery services
export 'src/services/error_recovery_service.dart';
export 'src/services/retry_tts_service.dart';

// Dependency injection
export 'src/di/service_locator.dart';

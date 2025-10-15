/// Alouette TTS - Multi-platform TTS library following Flutter naming conventions
///
/// This library provides text-to-speech functionality through multiple implementations:
/// - Edge TTS: Microsoft Edge's TTS engine via command line
/// - Flutter TTS: Cross-platform TTS using system engines
///
/// ## Main API (Recommended)
///
/// The main API provides a consistent interface across all TTS engines:
///
/// ```dart
/// import 'package:alouette_tts/alouette_tts.dart';
///
/// // Create a TTS service with automatic platform detection
/// final ttsService = TTSService();
/// await ttsService.initialize();
///
/// // Get available voices
/// final voices = await ttsService.getVoices();
///
/// // Synthesize text to audio data
/// final audioData = await ttsService.synthesizeText('Hello world', voices.first.id);
///
/// // Play audio using the built-in player
/// final audioPlayer = AudioPlayer();
/// await audioPlayer.playBytes(audioData);
/// ```
///
/// ## Platform-Specific Engine Selection
///
/// You can also manually select engines or use the unified engine factory:
///
/// ```dart
/// // Automatic platform-based selection
/// final processor = await TTSEngineFactory.instance.createForPlatform();
///
/// // Manual engine selection
/// final edgeProcessor = await TTSEngineFactory.instance.createForEngine(TTSEngineType.edge);
/// final flutterProcessor = await TTSEngineFactory.instance.createForEngine(TTSEngineType.flutter);
/// ```
library alouette_lib_tts;

// Core Services (Main API)
export 'src/core/tts_service_interface.dart';
export 'src/core/tts_service.dart';
export 'src/core/tts_engine_factory.dart';
export 'src/core/voice_service.dart';
export 'src/core/audio_player.dart';

// TTS Engines
export 'src/engines/base_tts_processor.dart';
export 'src/engines/edge_tts_processor.dart';
export 'src/engines/flutter_tts_processor.dart';

// Models
export 'src/models/voice_model.dart';
export 'src/models/tts_request.dart';
export 'src/models/tts_config.dart';
export 'src/models/tts_status.dart';
export 'src/models/tts_error.dart';

// Exceptions (includes TTSError and TTSErrorCodes)
export 'src/exceptions/tts_exceptions.dart';

// Enums
export 'src/enums/voice_gender.dart';
export 'src/enums/voice_quality.dart';
export 'src/enums/tts_engine_type.dart';

// Core Utilities (Most Commonly Used)
export 'src/utils/core_utils.dart';

// Specialized Utilities (Available for advanced usage)
export 'src/utils/platform_utils.dart';
export 'src/utils/file_utils.dart';
export 'src/utils/tts_diagnostics.dart';
export 'src/utils/logger_config.dart';

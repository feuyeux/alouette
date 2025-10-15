import 'dart:io' show Process;
import '../utils/platform_utils.dart';
import '../utils/logger_config.dart';
import '../models/tts_error.dart';
import '../enums/tts_engine_type.dart';
import '../exceptions/tts_exceptions.dart';
import '../engines/edge_tts_processor.dart';
import '../engines/flutter_tts_processor.dart';
import '../engines/base_tts_processor.dart';

/// TTS Engine Factory for platform-specific engine selection
/// Follows Flutter naming conventions and provides unified engine creation
class TTSEngineFactory {
  static TTSEngineFactory? _instance;
  static TTSEngineFactory get instance => _instance ??= TTSEngineFactory._();

  TTSEngineFactory._();

  /// Create TTS processor for current platform automatically
  Future<TTSProcessor> createForPlatform() async {
    ttsLogger.d('[TTS] Creating TTS processor for current platform');

    try {
      final strategy = PlatformUtils.getTTSStrategy();
      final fallbackEngines = strategy.getFallbackEngines();

      ttsLogger.d('[TTS] Platform strategy: ${strategy.runtimeType}');
      ttsLogger.d('[TTS] Fallback engines: ${fallbackEngines.map((e) => e.name).join(', ')}');

      // Try engines in order of preference
      for (final engine in fallbackEngines) {
        try {
          if (strategy.isEngineSupported(engine) &&
              await isEngineAvailable(engine)) {
            ttsLogger.d('[TTS] Using engine: ${engine.name}');
            return await createForEngine(engine);
          } else {
            ttsLogger.d('[TTS] Engine ${engine.name} not available, trying next...');
          }
        } catch (e) {
          ttsLogger.w('[TTS] Failed to create ${engine.name} engine', error: e);
          continue; // Try next engine
        }
      }

      // If no engines from strategy work, try any available engine
      final availableEngines = await getAvailableEngines();
      if (availableEngines.isNotEmpty) {
        ttsLogger.w('[TTS] Using fallback engine: ${availableEngines.first.name}');
        return await createForEngine(availableEngines.first);
      }

      throw TTSError(
        'No TTS engines available for this platform. '
        'Platform: ${PlatformUtils.platformName}, '
        'Tried engines: ${fallbackEngines.map((e) => e.name).join(', ')}',
        code: TTSErrorCodes.initializationFailed,
      );
    } catch (e) {
      ttsLogger.e('[TTS] Failed to create processor for platform', error: e);
      rethrow;
    }
  }

  /// Create TTS processor for specific engine type
  Future<TTSProcessor> createForEngine(TTSEngineType engineType) async {
    ttsLogger.d('[TTS] Creating TTS processor for engine: ${engineType.name}');

    // Check availability first
    final available = await isEngineAvailable(engineType);
    if (!available) {
      String errorMessage =
          '${engineType.name} TTS is not available on this system.';

      // Provide installation suggestions
      if (engineType == TTSEngineType.edge) {
        errorMessage +=
            '\nTo install: pip install edge-tts\nEnsure Python and pip are in your PATH.';
      }

      throw TTSError(errorMessage, code: TTSErrorCodes.initializationFailed);
    }

    // Create processor based on engine type
    switch (engineType) {
      case TTSEngineType.edge:
        return EdgeTTSProcessor();
      case TTSEngineType.flutter:
        return FlutterTTSProcessor();
    }
  }

  /// Check if specific engine is available on current platform
  Future<bool> isEngineAvailable(TTSEngineType engineType) async {
    switch (engineType) {
      case TTSEngineType.edge:
        return await _isEdgeTTSAvailable();
      case TTSEngineType.flutter:
        return _isFlutterTTSAvailable();
    }
  }

  /// Get all available engines for current platform
  Future<List<TTSEngineType>> getAvailableEngines() async {
    final availableEngines = <TTSEngineType>[];

    for (final engineType in TTSEngineType.values) {
      try {
        final available = await isEngineAvailable(engineType);
        if (available) {
          availableEngines.add(engineType);
        }
      } catch (e) {
        ttsLogger.w('[TTS] Failed to check availability for ${engineType.name}', error: e);
      }
    }

    return availableEngines;
  }

  /// Get platform information and engine availability
  Future<Map<String, dynamic>> getPlatformInfo() async {
    final availableEngines = await getAvailableEngines();
    final platformInfo = PlatformUtils.getPlatformInfo();

    return {
      ...platformInfo,
      'recommendedEngine': PlatformUtils.recommendedEngine.name,
      'availableEngines': availableEngines.map((e) => e.name).toList(),
    };
  }

  /// Check Edge TTS availability
  Future<bool> _isEdgeTTSAvailable() async {
    if (!PlatformUtils.supportsProcessExecution) {
      ttsLogger.d('[TTS] Edge TTS not supported: platform does not support process execution');
      return false;
    }

    try {
      ttsLogger.d('[TTS] Checking Edge TTS availability...');
      final available = await PlatformUtils.isEdgeTTSAvailableWithTimeout(
        timeout: const Duration(seconds: 12),
      );
      ttsLogger.d('[TTS] Edge TTS availability check result: $available');

      if (!available) {
        // Get diagnostic information
        final edgePath = await PlatformUtils.getEdgeTTSPath();
        ttsLogger.d('[TTS] Edge TTS path check result: $edgePath');

        // Try version command for more info
        try {
          final result = await Process.run(
            'edge-tts',
            ['--version'],
            environment: {
              'NO_PROXY': 'speech.platform.bing.com,.bing.com,*bing.com',
              'HTTP_PROXY': '',
              'HTTPS_PROXY': '',
              'ALL_PROXY': '',
              'http_proxy': '',
              'https_proxy': '',
              'all_proxy': '',
            },
            includeParentEnvironment: true,
          ).timeout(const Duration(seconds: 5));
          ttsLogger.d('[TTS] edge-tts --version exit code: ${result.exitCode}');
          ttsLogger.d('[TTS] edge-tts --version stdout: ${result.stdout}');
          ttsLogger.d('[TTS] edge-tts --version stderr: ${result.stderr}');
          final stderrStr = result.stderr.toString();
          if (!available && stderrStr.contains('usage:')) {
            ttsLogger.d('[TTS] edge-tts CLI present (usage output detected); treating as available');
            return true;
          }
        } catch (e) {
          ttsLogger.d('[TTS] edge-tts --version command failed', error: e);
        }
      }

      return available;
    } catch (e) {
      ttsLogger.w('[TTS] Edge TTS availability check failed', error: e);
      return false;
    }
  }

  /// Check Flutter TTS availability
  bool _isFlutterTTSAvailable() {
    return PlatformUtils.isFlutterTTSSupported;
  }
}

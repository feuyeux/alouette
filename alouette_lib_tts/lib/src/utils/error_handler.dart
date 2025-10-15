import '../models/tts_error.dart';
import '../exceptions/tts_exceptions.dart';
import 'logger_config.dart';

/// 统一的错误处理工具类
/// 避免在各个组件中重复编写相同的错误处理逻辑
class ErrorHandler {
  /// 处理初始化错误的统一方法
  static TTSError handleInitializationError(dynamic error, String component) {
    if (error is TTSError) {
      return TTSError(
        'Failed to initialize $component: ${error.message}',
        code: TTSErrorCodes.initializationFailed,
        originalError: error,
      );
    }

    return TTSError(
      'Failed to initialize $component: $error',
      code: TTSErrorCodes.initializationFailed,
      originalError: error,
    );
  }

  /// 处理语音相关错误的统一方法
  static TTSError handleVoiceError(dynamic error, String operation) {
    if (error is TTSError) {
      return error; // 直接返回已经包装好的错误
    }

    return TTSError(
      'Voice $operation failed: $error',
      code: TTSErrorCodes.voiceListFailed,
      originalError: error,
    );
  }

  /// 处理合成错误的统一方法
  static TTSError handleSynthesisError(
    dynamic error, {
    String? additionalInfo,
  }) {
    if (error is TTSError) {
      return error;
    }

    final message = additionalInfo != null
        ? 'Text synthesis failed: $error. $additionalInfo'
        : 'Text synthesis failed: $error';

    return TTSError(
      message,
      code: TTSErrorCodes.synthesisError,
      originalError: error,
    );
  }

  /// 处理播放错误的统一方法
  static TTSError handlePlaybackError(dynamic error, {String? context}) {
    if (error is TTSError) {
      return error;
    }

    final message = context != null
        ? 'Audio playback failed in $context: $error'
        : 'Audio playback failed: $error';

    return TTSError(
      message,
      code: TTSErrorCodes.playbackFailed,
      originalError: error,
    );
  }

  /// 处理资源释放错误的统一方法
  static TTSError handleDisposeError(dynamic error, String component) {
    if (error is TTSError) {
      return error;
    }

    return TTSError(
      'Failed to dispose $component: $error',
      code: TTSErrorCodes.disposeFailed,
      originalError: error,
    );
  }

  /// 收集多个错误并创建复合错误
  static TTSError createCompositeError(
    List<String> errors,
    String operation,
    String code,
  ) {
    return TTSError(
      '$operation completed with errors: ${errors.join('; ')}',
      code: code,
      originalError: errors,
    );
  }

  /// 处理处理器初始化错误的统一方法
  static TTSError handleProcessorInitializationError(
    dynamic error,
    String processorType,
  ) {
    ttsLogger.e('[TTS] Failed to initialize $processorType processor', error: error);

    if (error is TTSError) {
      return TTSError(
        'Failed to initialize $processorType processor: ${error.message}',
        code: TTSErrorCodes.initializationFailed,
        originalError: error,
      );
    }

    return TTSError(
      'Failed to initialize $processorType processor: $error',
      code: TTSErrorCodes.initializationFailed,
      originalError: error,
    );
  }

  /// 处理语音列表获取错误的统一方法
  static TTSError handleVoiceListError(dynamic error, String processorType) {
    ttsLogger.e('[TTS] Failed to get voices from $processorType', error: error);

    if (error is TTSError) {
      return error; // 直接返回已经包装好的错误
    }

    // 根据错误类型提供特定的建议
    String suggestion = '';
    final errorStr = error.toString().toLowerCase();

    if (processorType.toLowerCase() == 'edge' &&
        (errorStr.contains('edge-tts') ||
            errorStr.contains('command not found'))) {
      suggestion =
          ' Please ensure edge-tts is properly installed and accessible. '
          'Try running "pip install edge-tts" to install or update it.';
    } else if (processorType.toLowerCase() == 'flutter' &&
        (errorStr.contains('no voices') || errorStr.contains('tts'))) {
      suggestion =
          ' This usually indicates a problem with the system TTS configuration.';
    }

    return TTSError(
      'Error loading $processorType TTS voices: $error.$suggestion',
      code: TTSErrorCodes.voiceListError,
      originalError: error,
    );
  }

  /// 处理文本合成错误的统一方法
  static TTSError handleTextSynthesisError(
    dynamic error,
    String processorType,
    String text,
    String voiceName,
  ) {
    ttsLogger.e('[TTS] Text synthesis failed with $processorType - textLength: ${text.length}, voiceName: $voiceName', error: error);

    if (error is TTSError) {
      return error;
    }

    // 提供处理器特定的错误信息
    String suggestion = '';
    final errorStr = error.toString().toLowerCase();

    if (processorType.toLowerCase() == 'edge') {
      if (errorStr.contains('synthesis failed') ||
          errorStr.contains('edge-tts')) {
        suggestion =
            ' Please check that the voice name "$voiceName" is valid and supported. '
            'Use getVoices() to see available voices.';
      }
    } else if (processorType.toLowerCase() == 'flutter') {
      if (errorStr.contains('not found') ||
          errorStr.contains('not available')) {
        suggestion =
            ' Voice "$voiceName" is not supported on this platform/browser. '
            'Try using a different browser or the desktop version.';
      }
    }

    return TTSError(
      'Failed to synthesize text via $processorType TTS: $error.$suggestion',
      code: TTSErrorCodes.synthesisError,
      originalError: error,
    );
  }

  /// 处理文件操作错误的统一方法
  static TTSError handleFileError(
    dynamic error,
    String operation,
    String? filePath,
  ) {
    ttsLogger.e('[TTS] File operation failed - operation: $operation, filePath: $filePath', error: error);

    if (error is TTSError) {
      return error;
    }

    String message = 'File $operation failed';
    if (filePath != null) {
      message += ' for $filePath';
    }
    message += ': $error';

    String code = TTSErrorCodes.tempFileCreationFailed;
    if (operation.toLowerCase().contains('cleanup') ||
        operation.toLowerCase().contains('delete')) {
      code = TTSErrorCodes.tempFileCleanupFailed;
    } else if (operation.toLowerCase().contains('read')) {
      code = 'FILE_READ_FAILED';
    } else if (operation.toLowerCase().contains('write')) {
      code = 'FILE_WRITE_FAILED';
    }

    return TTSError(message, code: code, originalError: error);
  }

  /// 执行操作并统一处理错误
  static Future<T> wrapAsync<T>(
    Future<T> Function() operation,
    String context,
    String errorCode, {
    Map<String, dynamic>? logContext,
  }) async {
    try {
      final result = await operation();
      ttsLogger.d('[TTS] Operation completed successfully: $context');
      return result;
    } catch (e) {
      ttsLogger.e('[TTS] Operation failed: $context', error: e);

      if (e is TTSError) {
        rethrow;
      }

      throw TTSError('$context failed: $e', code: errorCode, originalError: e);
    }
  }

  /// 执行同步操作并统一处理错误
  static T wrapSync<T>(
    T Function() operation,
    String context,
    String errorCode, {
    Map<String, dynamic>? logContext,
  }) {
    try {
      final result = operation();
      ttsLogger.d('[TTS] Operation completed successfully: $context');
      return result;
    } catch (e) {
      ttsLogger.e('[TTS] Operation failed: $context', error: e);

      if (e is TTSError) {
        rethrow;
      }

      throw TTSError('$context failed: $e', code: errorCode, originalError: e);
    }
  }
}

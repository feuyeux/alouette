import '../exceptions/tts_exceptions.dart';

/// Legacy TTS Error class for backward compatibility
///
/// This class provides a simpler interface for TTS errors while using
/// the standardized error codes from the exceptions module.
class TTSError extends Error {
  /// 错误消息
  final String message;

  /// 错误代码 (可选)
  final String? code;

  /// 原始错误对象 (可选)
  final dynamic originalError;

  TTSError(this.message, {this.code, this.originalError});

  /// 检查是否为特定类型的错误
  bool isErrorType(String errorCode) {
    return code == errorCode;
  }

  /// 检查是否为初始化相关错误
  bool get isInitializationError => code == TTSErrorCodes.initializationFailed;

  /// 检查是否为语音相关错误
  bool get isVoiceError => code == TTSErrorCodes.voiceNotFound;

  /// 检查是否为合成相关错误
  bool get isSynthesisError => code == TTSErrorCodes.synthesisFailure;

  /// 检查是否为播放相关错误
  bool get isPlaybackError => code == TTSErrorCodes.audioPlaybackError;

  /// 检查是否为资源相关错误
  bool get isResourceError => code == TTSErrorCodes.resourceNotFound;

  @override
  String toString() {
    return 'TTSError: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

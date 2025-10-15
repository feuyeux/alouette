import 'package:logger/logger.dart';

/// TTS 库统一日志配置
/// 
/// 使用示例：
/// ```dart
/// ttsLogger.i('[TTS] Engine initialized');
/// ttsLogger.e('[TTS] Synthesis failed', error: error);
/// ```
final ttsLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTime,
  ),
);

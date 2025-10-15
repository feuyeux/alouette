import 'package:logger/logger.dart';

/// UI 库统一日志配置
/// 
/// 使用示例：
/// ```dart
/// uiLogger.i('[UI] Theme changed');
/// uiLogger.w('[UI] Invalid input detected');
/// ```
final uiLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTime,
  ),
);

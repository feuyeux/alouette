import 'package:logger/logger.dart';

/// Translation 库统一日志配置
/// 
/// 使用示例：
/// ```dart
/// transLogger.i('[TRANS] Translation started');
/// transLogger.e('[TRANS] API request failed', error: error);
/// ```
final transLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTime,
  ),
);

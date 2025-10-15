import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// 应用统一日志配置
/// 
/// 根据构建模式自动调整日志级别：
/// - Debug 模式：显示所有日志
/// - Release 模式：只显示警告和错误
/// 
/// 使用示例：
/// ```dart
/// appLogger.i('[APP] Application started');
/// appLogger.e('[APP] Initialization failed', error: error);
/// ```
final appLogger = Logger(
  filter: ProductionFilter(),
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTime,
  ),
  level: kReleaseMode ? Level.warning : Level.debug,
);

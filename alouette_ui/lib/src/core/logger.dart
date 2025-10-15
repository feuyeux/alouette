import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Global logger instance for alouette_ui package
final logger = Logger(
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

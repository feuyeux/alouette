# Alouette 项目日志标准

## 概述

所有 Alouette 子项目统一使用 [logger](https://pub.dev/packages/logger) 包进行日志输出。

## 日志级别

```dart
Level.trace    // 最详细的跟踪信息
Level.debug    // 调试信息
Level.info     // 一般信息
Level.warning  // 警告信息
Level.error    // 错误信息
Level.fatal    // 致命错误
```

## 统一配置

### 1. 创建全局 Logger 实例

在每个子项目的入口文件中配置：

```dart
import 'package:logger/logger.dart';

// 全局 Logger 实例
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,           // 不显示调用栈
    errorMethodCount: 5,      // 错误时显示5层调用栈
    lineLength: 80,           // 每行长度
    colors: true,             // 彩色输出
    printEmojis: true,        // 使用表情符号
    dateTimeFormat: DateTimeFormat.onlyTime,
  ),
);
```

### 2. 根据环境配置日志级别

```dart
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

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
```

## 使用规范

### 基础用法

```dart
// 调试信息
logger.d('调试信息');

// 一般信息
logger.i('操作成功');

// 警告
logger.w('这是一个警告');

// 错误
logger.e('发生错误', error: error);

// 带堆栈跟踪的错误
logger.e('发生错误', error: error, stackTrace: stackTrace);

// 致命错误
logger.f('致命错误', error: error, stackTrace: stackTrace);
```

### 结构化日志

使用统一的前缀标识不同模块：

```dart
// TTS 模块
logger.i('[TTS] Engine initialized: EdgeTTS');
logger.e('[TTS] Synthesis failed', error: error);

// Translation 模块
logger.i('[TRANS] Translation completed: zh -> en');
logger.e('[TRANS] API request failed', error: error);

// UI 模块
logger.d('[UI] Theme changed: dark mode');
logger.w('[UI] Invalid input detected');

// Cache 模块
logger.d('[CACHE] Cache hit: key=abc123');
logger.d('[CACHE] Cache miss: key=xyz789');

// Network 模块
logger.d('[NET] Request: GET /api/voices');
logger.d('[NET] Response: 200 OK');
```

### 性能日志

```dart
final stopwatch = Stopwatch()..start();
// ... 执行操作 ...
stopwatch.stop();
logger.d('[PERF] Operation completed in ${stopwatch.elapsedMilliseconds}ms');
```

## 输出格式示例

```
💡 12:34:56.789 | INFO | [TTS] Engine initialized: EdgeTTS
⚠️  12:34:56.790 | WARNING | [UI] Invalid input detected
❌ 12:34:56.791 | ERROR | [TRANS] API request failed
🐛 12:34:56.792 | DEBUG | [CACHE] Cache hit: key=abc123
🐛 12:34:56.793 | DEBUG | [PERF] Operation completed in 150ms
```

## 各子项目配置

### alouette_lib_tts

```dart
// lib/src/core/tts_service.dart
import 'package:logger/logger.dart';

final _logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTime,
  ),
);

class TTSService {
  Future<void> initialize() async {
    _logger.i('[TTS] Initializing TTS service');
    // ...
  }
}
```

### alouette_lib_trans

```dart
// lib/src/core/translation_service.dart
import 'package:logger/logger.dart';

final _logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTime,
  ),
);

class TranslationService {
  Future<String> translate(String text) async {
    _logger.i('[TRANS] Translating text: ${text.substring(0, 20)}...');
    // ...
  }
}
```

### alouette_ui

```dart
// lib/src/services/service_manager.dart
import 'package:logger/logger.dart';

final _logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTime,
  ),
);
```

### alouette_app / alouette_app_tts / alouette_app_trans

```dart
// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

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

void main() {
  logger.i('[APP] Application starting');
  runApp(MyApp());
}
```

## 最佳实践

1. **使用合适的日志级别**
   - `debug`: 开发调试信息
   - `info`: 重要的业务流程
   - `warning`: 可恢复的异常情况
   - `error`: 需要关注的错误
   - `fatal`: 导致程序崩溃的错误

2. **提供上下文信息**
   ```dart
   // ❌ 不好
   logger.e('失败');
   
   // ✅ 好
   logger.e('[TTS] Synthesis failed', error: error);
   ```

3. **使用统一的模块前缀**
   - `[TTS]` - TTS 相关
   - `[TRANS]` - 翻译相关
   - `[UI]` - UI 相关
   - `[CACHE]` - 缓存相关
   - `[NET]` - 网络相关
   - `[PERF]` - 性能相关
   - `[APP]` - 应用级别

4. **避免敏感信息**
   ```dart
   // ❌ 不要记录敏感信息
   logger.d('API Key: $apiKey');
   
   // ✅ 只记录必要信息
   logger.d('[NET] API request authenticated');
   ```

5. **记录错误时包含堆栈跟踪**
   ```dart
   try {
     // ...
   } catch (e, stackTrace) {
     logger.e('[TTS] Operation failed', error: e, stackTrace: stackTrace);
   }
   ```

## 禁止使用

❌ 不要使用以下方式输出日志：
- `print()`
- `debugPrint()`
- `stdout.writeln()`
- 自定义的日志类（如旧的 TTSLogger）

✅ 统一使用 `logger` 包

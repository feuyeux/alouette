# 日志快速参考

## 导入和使用

### alouette_lib_tts
```dart
import 'package:alouette_tts/alouette_tts.dart';

ttsLogger.i('[TTS] Engine initialized');
ttsLogger.e('[TTS] Synthesis failed', error: error);
```

### alouette_lib_trans
```dart
import 'package:alouette_lib_trans/alouette_lib_trans.dart';

transLogger.i('[TRANS] Translation started');
transLogger.e('[TRANS] API failed', error: error);
```

### alouette_ui
```dart
import 'package:alouette_ui/alouette_ui.dart';

uiLogger.i('[UI] Theme changed');
uiLogger.w('[UI] Invalid input');
```

### alouette_app / alouette_app_tts / alouette_app_trans
```dart
import 'package:logger/logger.dart';
import 'utils/logger_config.dart';

appLogger.i('[APP] Application started');
appLogger.e('[APP] Error occurred', error: error);
```

## 日志级别

```dart
logger.t('trace');    // 💡 最详细
logger.d('debug');    // 🐛 调试
logger.i('info');     // 💡 信息
logger.w('warning');  // ⚠️  警告
logger.e('error');    // ❌ 错误
logger.f('fatal');    // 👾 致命
```

## 模块前缀

- `[TTS]` - TTS 相关
- `[TRANS]` - 翻译相关
- `[UI]` - UI 相关
- `[APP]` - 应用级别
- `[CACHE]` - 缓存相关
- `[NET]` - 网络相关
- `[PERF]` - 性能相关

## 常用模式

```dart
// 基础日志
logger.i('[TTS] Operation completed');

// 带错误
logger.e('[TTS] Operation failed', error: error);

// 带堆栈跟踪
logger.e('[TTS] Critical error', error: error, stackTrace: stackTrace);

// 性能日志
final sw = Stopwatch()..start();
// ... operation ...
sw.stop();
logger.d('[PERF] Operation took ${sw.elapsedMilliseconds}ms');

// Try-catch 模式
try {
  // ...
} catch (e, stackTrace) {
  logger.e('[TTS] Operation failed', error: e, stackTrace: stackTrace);
  rethrow;
}
```

## 输出示例

```
💡 12:34:56.789 | INFO | [TTS] Engine initialized: EdgeTTS
🐛 12:34:56.790 | DEBUG | [CACHE] Cache hit: key=abc123
⚠️  12:34:56.791 | WARNING | [UI] Invalid input detected
❌ 12:34:56.792 | ERROR | [TRANS] API request failed
```

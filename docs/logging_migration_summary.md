# 日志标准化迁移总结

## 完成的工作

### 1. 添加 logger 依赖到所有子项目

所有6个子项目已添加 `logger: ^2.6.2` 依赖：
- ✅ alouette_lib_tts
- ✅ alouette_lib_trans
- ✅ alouette_ui
- ✅ alouette_app
- ✅ alouette_app_tts
- ✅ alouette_app_trans

### 2. 创建统一的日志配置文件

每个子项目都有自己的 logger 配置文件：

| 项目 | 配置文件 | Logger 实例名 |
|------|---------|--------------|
| alouette_lib_tts | `lib/src/utils/logger_config.dart` | `ttsLogger` |
| alouette_lib_trans | `lib/src/utils/logger_config.dart` | `transLogger` |
| alouette_ui | `lib/src/utils/logger_config.dart` | `uiLogger` |
| alouette_app | `lib/utils/logger_config.dart` | `appLogger` |
| alouette_app_tts | `lib/utils/logger_config.dart` | `appLogger` |
| alouette_app_trans | `lib/utils/logger_config.dart` | `appLogger` |

### 3. 删除旧的日志实现

- ❌ 删除了 `alouette_lib_tts/lib/src/utils/tts_logger.dart`
- ❌ 删除了 `alouette_lib_tts/lib/src/utils/app_logger.dart`

### 4. 替换代码中的日志调用

已更新的文件：
- ✅ `alouette_lib_tts/lib/src/core/tts_service.dart` - 17处日志调用
- ✅ `alouette_lib_tts/lib/src/engines/flutter_tts_processor.dart` - 26处日志调用

### 5. 更新导出文件

- ✅ `alouette_lib_tts/lib/alouette_tts.dart`
- ✅ `alouette_lib_trans/lib/alouette_lib_trans.dart`
- ✅ `alouette_ui/lib/alouette_ui.dart`

### 6. 创建文档

- ✅ `docs/logging_standard.md` - 完整的日志标准文档
- ✅ `docs/logging_quick_reference.md` - 快速参考指南
- ✅ `docs/logging_migration_summary.md` - 本文档

## 日志格式对比

### 旧格式（TTSLogger）
```dart
TTSLogger.info('Operation completed');
TTSLogger.warning('This is a warning');
TTSLogger.error('Error occurred', error);
TTSLogger.debug('Debug info');
TTSLogger.initialization('Component', 'status', 'details');
TTSLogger.engine('operation', 'engine', 'details');
```

### 新格式（logger）
```dart
ttsLogger.i('[TTS] Operation completed');
ttsLogger.w('[TTS] This is a warning');
ttsLogger.e('[TTS] Error occurred', error: error);
ttsLogger.d('[TTS] Debug info');
ttsLogger.i('[TTS] Component initialization: status - details');
ttsLogger.i('[TTS] Engine operation: engine - details');
```

## 统一的模块前缀

| 模块 | 前缀 | 用途 |
|------|------|------|
| TTS | `[TTS]` | TTS 相关操作 |
| Translation | `[TRANS]` | 翻译相关操作 |
| UI | `[UI]` | UI 相关操作 |
| Application | `[APP]` | 应用级别操作 |
| Cache | `[CACHE]` | 缓存相关操作 |
| Network | `[NET]` | 网络相关操作 |
| Performance | `[PERF]` | 性能相关操作 |

## 日志级别

| 级别 | 方法 | 表情 | 用途 |
|------|------|------|------|
| Trace | `logger.t()` | 💡 | 最详细的跟踪信息 |
| Debug | `logger.d()` | 🐛 | 调试信息 |
| Info | `logger.i()` | 💡 | 一般信息 |
| Warning | `logger.w()` | ⚠️ | 警告信息 |
| Error | `logger.e()` | ❌ | 错误信息 |
| Fatal | `logger.f()` | 👾 | 致命错误 |

## 使用示例

### 基础日志
```dart
import 'package:alouette_tts/alouette_tts.dart';

ttsLogger.i('[TTS] Service initialized');
ttsLogger.d('[TTS] Processing request');
ttsLogger.w('[TTS] Fallback to default engine');
ttsLogger.e('[TTS] Synthesis failed', error: error);
```

### 带堆栈跟踪的错误日志
```dart
try {
  // ...
} catch (e, stackTrace) {
  ttsLogger.e('[TTS] Critical error', error: e, stackTrace: stackTrace);
}
```

### 性能日志
```dart
final stopwatch = Stopwatch()..start();
// ... 执行操作 ...
stopwatch.stop();
ttsLogger.d('[PERF] Operation took ${stopwatch.elapsedMilliseconds}ms');
```

## 输出示例

```
💡 12:34:56.789 | INFO | [TTS] Service initialized
🐛 12:34:56.790 | DEBUG | [TTS] Processing request
⚠️  12:34:56.791 | WARNING | [TTS] Fallback to default engine
❌ 12:34:56.792 | ERROR | [TTS] Synthesis failed
🐛 12:34:56.793 | DEBUG | [PERF] Operation took 150ms
```

## 下一步

如果需要在其他文件中添加日志，请遵循以下步骤：

1. 导入 logger 配置：
   ```dart
   import '../utils/logger_config.dart';  // 或 'package:xxx/xxx.dart'
   ```

2. 使用对应的 logger 实例：
   - TTS 库：`ttsLogger`
   - Translation 库：`transLogger`
   - UI 库：`uiLogger`
   - 应用：`appLogger`

3. 添加适当的模块前缀：
   ```dart
   ttsLogger.i('[TTS] Your message here');
   ```

4. 错误日志包含 error 参数：
   ```dart
   ttsLogger.e('[TTS] Error message', error: error, stackTrace: stackTrace);
   ```

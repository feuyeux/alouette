# 日志系统迁移指南

## 迁移步骤

### 1. 替换旧的日志调用

#### 从 print 迁移

```dart
// ❌ 旧代码
print('TTS engine initialized');
print('Error: $error');

// ✅ 新代码
import 'package:alouette_tts/alouette_tts.dart';
ttsLogger.i('[TTS] Engine initialized');
ttsLogger.e('[TTS] Error oc
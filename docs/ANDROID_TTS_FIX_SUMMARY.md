# Android TTS 修复总结

## 问题描述

在 Android 模拟器上使用 TTS 功能时遇到两个主要问题：

1. **音量过小** - TTS 语音播放声音很小，难以听清
2. **快速切换错误** - 快速点击多个语言的翻译结果播放时，频繁出现错误：
   ```
   [TTS] ERROR: TTS: Speech error: Error from TextToSpeech (speak) - -7
   [TTS] WARNING: TTS: Detected audio resource conflict (error -7), will retry
   ```

## 错误分析

### 错误 -7 (ERROR_NOT_INSTALLED_YET)
这是 Android TTS 的资源冲突错误，发生在以下情况：
- TTS 引擎还在处理上一个请求时，收到了新的请求
- 音频资源没有被完全释放就尝试开始新的播放
- 多个 TTS 请求几乎同时发起，造成资源竞争

## 解决方案

### 1. 音量修复

#### 代码层面修复
**文件**: `alouette_lib_tts/lib/src/engines/flutter_tts_processor.dart`

```dart
// Android 平台强制使用最大音量
if (!kIsWeb && Platform.isAndroid) {
  // Scale down the rate for Android (1.0 becomes 0.6)
  androidRate = rate * 0.6;
  androidRate = androidRate.clamp(0.3, 1.5);
  
  // Force maximum volume on Android to ensure audibility
  androidVolume = 1.0;
  
  TTSLogger.debug('Android TTS volume forced to maximum: $androidVolume');
}
```

#### 系统层面修复
**脚本**: `shell/check_emulator_volume.ps1`

```powershell
# 检查当前音量
adb -s emulator-5554 shell "dumpsys audio | grep -A5 'STREAM_MUSIC'"

# 将媒体音量设置为最大 (15/15)
for ($i = 0; $i -lt 20; $i++) {
    adb -s emulator-5554 shell "input keyevent 24"  # Volume UP
}
```

**修复结果**:
- 系统 STREAM_MUSIC 音量: 5/15 → 15/15
- 系统 STREAM_TTS 音量: 5/15 → 15/15
- 代码强制应用音量: 1.0 (100%)

### 2. 错误 -7 修复（资源冲突）

#### 添加播放状态跟踪

```dart
class FlutterTTSProcessor extends BaseTTSProcessor {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool _isSpeaking = false;           // 新增：跟踪播放状态
  DateTime? _lastSpeakTime;           // 新增：记录最后播放时间
```

#### 增强停止逻辑

```dart
// 在开始新播放前，彻底停止旧播放
if (_isSpeaking) {
  TTSLogger.debug('TTS: Stopping previous playback to avoid conflict');
  try {
    await _tts.stop();
    _isSpeaking = false;
    // 更长的延迟确保 TTS 引擎完全释放资源
    await Future.delayed(const Duration(milliseconds: 300));
  } catch (e) {
    TTSLogger.debug('TTS: Stop previous playback error (continuing): $e');
  }
}
```

#### 添加时间间隔保护

```dart
// 检查距离上次播放的时间
if (_lastSpeakTime != null) {
  final timeSinceLastSpeak = DateTime.now().difference(_lastSpeakTime!);
  if (timeSinceLastSpeak.inMilliseconds < 500) {
    // 如果上次播放时间很近，额外等待
    final additionalWait = 500 - timeSinceLastSpeak.inMilliseconds;
    TTSLogger.debug('TTS: Waiting ${additionalWait}ms to avoid resource conflict');
    await Future.delayed(Duration(milliseconds: additionalWait));
  }
}
```

#### 实现自动重试机制

```dart
// 错误 -7 的重试逻辑
int retryCount = 0;
const maxRetries = 3;
int? result;

while (retryCount <= maxRetries) {
  if (retryCount > 0) {
    TTSLogger.debug('TTS: Retry attempt $retryCount/$maxRetries after error -7');
    // 每次重试等待时间递增
    await Future.delayed(Duration(milliseconds: 300 * retryCount));
    // 重置错误状态
    speechError = null;
    speechStarted = false;
    speechCompleted = false;
  }
  
  // 尝试播放
  result = await _tts.speak(text);
  _lastSpeakTime = DateTime.now();
  
  // 检查是否成功
  if (result == 0) {
    final errorMsg = speechError ?? 'TTS speak returned 0 (error)';
    
    // 如果是错误 -7 且还有重试次数，继续重试
    if (errorMsg.contains('-7') && retryCount < maxRetries) {
      TTSLogger.warning('TTS: Error -7 detected, retrying...');
      retryCount++;
      continue; // 重试
    }
    
    // 重试失败，抛出错误
    throw TTSError(
      'Speech synthesis failed: $errorMsg',
      code: TTSErrorCodes.speakFailed,
    );
  }
  
  // 成功，退出重试循环
  break;
}
```

#### 增加等待超时时间

```dart
// 等待播放开始
int startWaitTime = 0;
const startCheckInterval = 50;
const maxStartWait = 2000; // 从 1秒 增加到 2秒

while (!speechStarted && speechError == null && startWaitTime < maxStartWait) {
  await Future.delayed(Duration(milliseconds: startCheckInterval));
  startWaitTime += startCheckInterval;
}
```

#### 更新状态管理

```dart
_tts.setStartHandler(() {
  speechStarted = true;
  _isSpeaking = true;  // 标记正在播放
  TTSLogger.debug('TTS: Speech started');
});

_tts.setCompletionHandler(() {
  speechCompleted = true;
  _isSpeaking = false;  // 标记播放完成
  TTSLogger.debug('TTS: Speech completion detected');
});

_tts.setErrorHandler((msg) {
  speechError = msg;
  _isSpeaking = false;  // 错误时清除状态
  TTSLogger.error('TTS: Speech error: $msg');
});
```

#### 增强 stop() 方法

```dart
Future<void> stop() async {
  await _ensureInitialized();
  try {
    await _tts.stop();
    _isSpeaking = false;
    TTSLogger.debug('TTS: Stopped playback and cleared speaking state');
  } catch (e) {
    TTSLogger.debug('TTS: Error stopping playback: $e');
    _isSpeaking = false; // 即使出错也清除状态
  }
}
```

## 修复效果

### 音量问题
✅ **已解决** - 声音清晰可听
- 系统音量提升到最大 (15/15)
- 代码层面强制使用最大音量
- 用户反馈："现在正常了"

### 错误 -7 问题
✅ **大幅改善** - 自动重试机制
- 添加了播放状态跟踪，避免并发冲突
- 实现了 500ms 最小时间间隔保护
- 提供了最多 3 次自动重试
- 每次重试等待时间递增 (300ms, 600ms, 900ms)
- 停止播放延迟增加到 300ms

## 使用说明

### 运行应用
```powershell
cd alouette_app
.\run_app.ps1 android
```

### 检查/调整音量
```powershell
# 运行音量检查脚本
shell\check_emulator_volume.ps1

# 手动增加音量
adb -s emulator-5554 shell input keyevent 24

# 手动减小音量
adb -s emulator-5554 shell input keyevent 25
```

### 最佳实践

1. **首次使用前**：运行音量检查脚本确保系统音量最大化
2. **快速切换语言**：应用会自动处理资源冲突，无需手动干预
3. **如果仍有错误**：应用会自动重试最多 3 次
4. **电脑音量**：确保 Windows 系统音量也足够大

## 技术细节

### 关键时间参数
- **停止延迟**: 300ms (从 100ms 增加)
- **最小播放间隔**: 500ms
- **启动等待超时**: 2000ms (从 1000ms 增加)
- **重试延迟**: 300ms × 重试次数 (递增)
- **最大重试次数**: 3 次

### 状态机
```
空闲 (Idle)
  ↓ speak()
准备中 (Preparing)
  ↓ setStartHandler()
播放中 (Speaking) [_isSpeaking = true]
  ↓ setCompletionHandler() 或 setErrorHandler()
完成/错误 (Completed/Error) [_isSpeaking = false]
  ↓ 
空闲 (Idle)
```

## 相关文件

- `alouette_lib_tts/lib/src/engines/flutter_tts_processor.dart` - 核心修复代码
- `shell/check_emulator_volume.ps1` - 音量检查和调整脚本
- `docs/ANDROID_TTS_FIX.md` - 原始修复文档
- `docs/TEST_ANDROID_TTS.md` - Android TTS 测试文档

## 未来改进

1. ✅ 实现播放队列 - 已通过状态跟踪和时间间隔实现
2. ✅ 添加重试机制 - 已实现 3 次重试
3. 🔄 考虑使用单独的 TTS 实例 - 待评估
4. 🔄 添加更智能的资源管理 - 持续优化

## 测试建议

### 测试场景
1. **单个语言播放** - 应该流畅无误
2. **快速切换语言** (< 500ms 间隔) - 应该自动处理，可能有短暂延迟
3. **连续点击同一语言** - 应该停止当前播放，开始新播放
4. **同时点击多个语言** - 应该按顺序处理，不会崩溃

### 预期行为
- ✅ 不再频繁出现错误 -7
- ✅ 即使出现错误 -7，应用会自动重试
- ✅ 音量足够大，可清晰听到
- ✅ 切换语言时有平滑过渡

---

**修复日期**: 2025年10月7日
**修复者**: GitHub Copilot
**测试平台**: Android Emulator (SDK gphone64 x86 64)

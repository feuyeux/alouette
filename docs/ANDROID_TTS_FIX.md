# Android TTS 音量和语速修复说明

## 问题描述

在 Android 模拟器/设备上使用 Flutter TTS 时，即使代码中设置了正常参数：
- `rate = 1.0` (正常语速)
- `volume = 1.0` (100% 音量)  
- `pitch = 1.0` (正常音调)

但实际效果是：
- **声音特别小** - 即使设备音量已调至最大
- **语速特别快** - 听起来像快进播放

## 根本原因

### 1. Android TTS 语速缩放问题
Android 的 `TextToSpeech.setSpeechRate()` 使用的基准值与其他平台不同：
- **iOS/macOS**: `0.5` = 正常语速，`1.0` = 2倍速
- **Android**: `1.0` 应该是正常，但实测发现系统实现偏快
- **实际测试**: Android 上 `rate=1.0` 听起来像 1.5-2倍速

### 2. 音频流类型问题（推测）
Android 有多种音频流类型：
- `STREAM_MUSIC` - 音乐流（正常媒体音量）
- `STREAM_NOTIFICATION` - 通知流（音量较小）
- `STREAM_VOICE_CALL` - 通话流

Flutter TTS 可能使用了非 `STREAM_MUSIC` 流，导致音量控制不正常。

## 解决方案

### 修改 1: 初始化时的 Android 默认参数调整

```dart
// 为 Android 使用更慢的默认语速
final defaultRate = Platform.isAndroid ? 0.6 : 1.0;
await _tts.setSpeechRate(defaultRate);  // Android: 0.6, 其他平台: 1.0
```

**作用**: 初始化时就使用更合理的默认值

### 修改 2: 参数应用时的动态语速缩放

```dart
// Android 语速映射公式
if (Platform.isAndroid) {
  androidRate = rate * 0.6;  // 1.0 -> 0.6, 0.5 -> 0.3, 2.0 -> 1.2
  androidRate = androidRate.clamp(0.3, 1.5);
}
```

**映射表**:
| 请求语速 | iOS/macOS | Android (修复后) | Android (修复前) |
|---------|-----------|-----------------|-----------------|
| 0.5     | 0.25      | 0.3             | 0.5 (太快)      |
| 1.0     | 0.5       | 0.6             | 1.0 (非常快)    |
| 1.5     | 0.75      | 0.9             | 1.5 (极快)      |
| 2.0     | 1.0       | 1.2             | 2.0 (无法理解)  |

### 修改 3: 播放前的音量检查

```dart
// 检查系统音量并警告
if (Platform.isAndroid) {
  final currentVolume = await _tts.getVolume;
  if (currentVolume < 0.5) {
    TTSLogger.warning('System volume is low, speech may be quiet');
  }
}
```

**作用**: 帮助诊断音量问题是否来自系统设置

## 测试验证

### 测试步骤
1. 确保 Android 模拟器/设备音量已调至最大
2. 在 `alouette_app` 中测试 TTS 功能
3. 使用默认参数播放（`rate=1.0`）
4. 检查日志输出：
   ```
   Android TTS rate adjustment: requested=1.0 -> actual=0.6
   Android TTS params: rate=0.6, pitch=1.0, volume=1.0
   ```

### 预期结果
- ✅ 语速接近正常说话速度（不再像快进）
- ✅ 音量清晰可闻（与系统音量一致）
- ✅ 日志显示正确的参数缩放

### 如果问题仍存在

#### 音量问题排查
1. **检查设备音量**: Android 设置 → 声音 → 媒体音量
2. **检查 TTS 引擎设置**: Android 设置 → 辅助功能 → TTS 输出
3. **查看日志中的音量警告**: 
   ```
   TTS: Current Android system volume: 0.3
   TTS: System volume is low (0.3), speech may be quiet
   ```

#### 语速问题调整
如果 0.6 倍仍然太快或太慢，可调整缩放系数：

```dart
// 在 flutter_tts_processor.dart 的 _applyParameters 方法中
androidRate = rate * 0.5;  // 更慢 (0.6 -> 0.5)
// 或
androidRate = rate * 0.7;  // 稍快 (0.6 -> 0.7)
```

## 技术细节

### Flutter TTS 库限制
Flutter TTS 没有暴露以下 Android 原生 API：
- `setAudioStreamType()` - 设置音频流类型
- `AudioManager.STREAM_MUSIC` - 指定使用媒体流

这些需要通过 platform channel 直接调用 Android 原生代码。

### 平台差异总结
| 平台      | 正常语速值 | 音量控制  | 备注                    |
|----------|-----------|----------|------------------------|
| iOS      | 0.5       | 系统音量  | AVFoundation           |
| macOS    | 0.5       | 系统音量  | AVFoundation           |
| Android  | 0.6*      | 媒体音量* | TextToSpeech (需缩放)   |
| Web      | 0.9-1.0   | 浏览器    | Web Speech API         |

*标注值为修复后的推荐值

## 相关文件

- `alouette_lib_tts/lib/src/engines/flutter_tts_processor.dart` - 主要修改文件
- `alouette_lib_tts/lib/src/models/tts_request.dart` - 参数定义
- `alouette_lib_tts/lib/src/core/tts_service.dart` - 服务入口

## 参考资料

- [Flutter TTS Plugin](https://pub.dev/packages/flutter_tts)
- [Android TextToSpeech API](https://developer.android.com/reference/android/speech/tts/TextToSpeech)
- [Android AudioManager](https://developer.android.com/reference/android/media/AudioManager)

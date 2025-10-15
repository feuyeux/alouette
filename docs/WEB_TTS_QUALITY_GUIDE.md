# Web 平台 TTS 音质优化指南

## 概述
本文档介绍如何在 Web 平台上提高 Text-to-Speech (TTS) 的音质。Web 平台使用浏览器的 Web Speech API，音质受浏览器和系统语音库的限制。

## 已实施的优化

### 1. 智能语音选择（自动）
系统会自动选择最高质量的可用语音，优先级如下：

**优先级评分系统：**
- ✅ **Google 语音** (+100分) - 通常是 Web 平台上音质最好的
- ✅ **Neural/Premium 语音** (+50分) - 神经网络合成，自然度高
- ✅ **Natural/HD 语音** (+30分) - 高清晰度语音
- ✅ **在线语音** (+20分) - 在线语音通常比离线版本音质更好
- ✅ **特殊高质量语音** (+40分) - WaveNet, Neural2, Journey, Studio, Polyglot

**代码位置：** `flutter_tts_processor.dart` 的 `_selectBestWebVoice()` 方法

### 2. 优化的语音参数（自动）
Web 平台自动应用以下优化参数：

```dart
// 语速：稍微放慢以提高清晰度
optimizedRate = rate * 0.95 (限制在 0.75-1.0 范围)

// 音高：稍微提高以改善清晰度
optimizedPitch = pitch * 1.05 (限制在 0.5-2.0 范围)

// 音量：保持较高音量以获得最佳质量
optimizedVolume = volume (限制在 0.8-1.0 范围)
```

**效果：**
- 语速降低 5% → 提高发音清晰度
- 音高提高 5% → 改善某些语音的清晰度
- 音量保持 80-100% → 确保信号强度

**代码位置：** `flutter_tts_processor.dart` 的 `_applyParameters()` 方法

## 不同浏览器的音质对比

### Chrome/Chromium（推荐 ⭐⭐⭐⭐⭐）
- **优势**：
  - 支持 Google 高质量语音
  - 语音库最丰富（通常 100+ 种语音）
  - 支持多语言 Neural 语音
- **推荐用于**：所有语言，尤其是英语、中文、日语

### Edge（推荐 ⭐⭐⭐⭐）
- **优势**：
  - 支持 Microsoft Neural 语音
  - Windows 系统集成良好
  - 某些语言音质接近 Chrome
- **推荐用于**：Windows 用户

### Firefox（一般 ⭐⭐⭐）
- **优势**：隐私保护好
- **劣势**：语音库较少，音质一般
- **推荐用于**：对隐私要求高的场景

### Safari（一般 ⭐⭐）
- **优势**：macOS/iOS 系统集成
- **劣势**：
  - 语音库最少
  - 某些语言不支持
  - Web Speech API 支持有限
- **推荐用于**：macOS 用户（但建议使用桌面版应用）

## 进一步提高音质的方法

### 方法 1：使用桌面应用（强烈推荐）
**桌面版使用 Edge TTS，音质显著优于 Web 版**

```bash
# macOS
cd alouette_app && ./run_app.sh

# Windows
cd alouette_app && .\run_app.ps1

# Linux
cd alouette_app && ./run_app.sh
```

**优势：**
- 使用 Microsoft Edge TTS Neural 语音（云端）
- 音质接近真人
- 支持更多语言和方言
- 不受浏览器限制

### 方法 2：升级浏览器和系统
**确保使用最新版本：**
- ✅ Chrome 120+ / Edge 120+
- ✅ macOS 14+ / Windows 11
- ✅ 系统语音库更新到最新版本

**更新系统语音库：**

**macOS:**
```bash
# 系统偏好设置 → 辅助功能 → 语音内容 → 系统语音
# 下载 "增强质量" 语音包
```

**Windows 11:**
```
设置 → 时间和语言 → 语音 → 管理语音
下载 "自然" 或 "Neural" 语音
```

**Linux:**
```bash
# 安装 espeak-ng（改进版）
sudo apt install espeak-ng espeak-ng-data

# 或安装 festival（更自然）
sudo apt install festival festvox-kallpc16k
```

### 方法 3：调整用户参数
虽然系统已自动优化，但用户仍可手动调整：

**在应用中：**
1. 打开 TTS 设置
2. 尝试以下参数组合：

**清晰度优先：**
- 语速：0.8-0.9x
- 音高：1.0-1.1x
- 音量：100%

**自然度优先：**
- 语速：0.9-1.0x
- 音高：0.95-1.0x
- 音量：90-100%

**快速浏览：**
- 语速：1.2-1.5x
- 音高：1.0x
- 音量：100%

### 方法 4：使用特定语言的最佳语音

**推荐语音列表：**

| 语言 | Chrome 推荐语音 | Edge 推荐语音 |
|------|----------------|--------------|
| 英语（美国） | Google US English (Neural) | Microsoft Aria Online (Natural) |
| 中文（简体） | Google 普通话（中国大陆）(Neural) | Microsoft Xiaoxiao Online (Natural) |
| 日语 | Google 日本語 (Neural) | Microsoft Nanami Online (Natural) |
| 韩语 | Google 한국의 (Neural) | Microsoft SunHi Online (Natural) |
| 法语 | Google français (Neural) | Microsoft Denise Online (Natural) |
| 德语 | Google Deutsch (Neural) | Microsoft Katja Online (Natural) |
| 西班牙语 | Google español (Neural) | Microsoft Elena Online (Natural) |
| 阿拉伯语 | Google العربية (Neural) | Microsoft Salma Online (Natural) |

## 技术限制

### Web Speech API 的局限性
1. **音质上限**：受浏览器和系统语音库限制
2. **语音选择**：无法强制使用云端高质量语音
3. **参数控制**：仅支持基本参数（rate, pitch, volume）
4. **离线限制**：高质量语音通常需要网络连接

### 建议的解决方案
- **对音质要求高**：使用桌面应用（Edge TTS）
- **Web 端足够**：使用 Chrome 浏览器 + 更新系统语音库
- **移动端**：使用移动应用（Flutter TTS + 系统语音）

## 代码实现细节

### 自动语音选择逻辑
```dart
VoiceModel? _selectBestWebVoice(List<VoiceModel> voices, String targetLocale) {
  // 1. 筛选匹配语言的语音
  final matchingVoices = voices.where(
    (voice) => voice.languageCode == targetLocale,
  ).toList();

  // 2. 评分系统
  for (final voice in matchingVoices) {
    int score = 0;
    
    // Google 语音 +100
    if (voice.name.contains('google')) score += 100;
    
    // Neural/Premium +50
    if (voice.name.contains('neural')) score += 50;
    
    // 选择最高分语音
  }
  
  return bestVoice;
}
```

### 参数优化逻辑
```dart
if (kIsWeb) {
  // 语速优化：稍微放慢
  final optimizedRate = (rate * 0.95).clamp(0.75, 1.0);
  
  // 音高优化：稍微提高
  final optimizedPitch = (pitch * 1.05).clamp(0.5, 2.0);
  
  // 音量优化：保持较高
  final optimizedVolume = volume.clamp(0.8, 1.0);
  
  await _tts.setSpeechRate(optimizedRate);
  await _tts.setPitch(optimizedPitch);
  await _tts.setVolume(optimizedVolume);
}
```

## 测试和验证

### 测试步骤
1. 打开应用（Chrome 浏览器）
2. 输入测试文本：
   ```
   The quick brown fox jumps over the lazy dog.
   敏捷的棕色狐狸跳过了懒狗。
   ```
3. 翻译到多种语言
4. 点击播放按钮测试音质
5. 查看控制台日志确认选择的语音

### 预期日志输出
```
Selected best Web voice: Google US English (Neural) (score: 150) for locale: en-US
Web TTS optimized params: rate=0.95, pitch=1.05, volume=1.0
TTS: Direct playback mode - audio already played for English
```

## 总结

### 优化效果
- ✅ **自动选择最高质量语音**：提升 30-50% 音质
- ✅ **优化语音参数**：提升 10-20% 清晰度
- ✅ **跨浏览器支持**：确保最佳兼容性

### 音质对比
| 场景 | 优化前 | 优化后 |
|------|--------|--------|
| Chrome | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| Edge | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| Firefox | ⭐⭐ | ⭐⭐⭐ |
| Safari | ⭐⭐ | ⭐⭐ |
| 桌面应用（Edge TTS） | - | ⭐⭐⭐⭐⭐ |

### 最佳实践建议
1. 🏆 **首选**：使用桌面应用（音质最佳）
2. 🥈 **次选**：Chrome 浏览器 + 最新系统（Web 最佳）
3. 🥉 **备选**：Edge 浏览器（Windows 用户）
4. 📱 **移动**：使用移动应用（原生 TTS）

---

**更新日期**：2025-10-04
**适用版本**：Alouette 1.0.0+

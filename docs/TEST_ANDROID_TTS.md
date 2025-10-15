# Android TTS 修复测试指南

## 修复内容总结

已对 `alouette_lib_tts/lib/src/engines/flutter_tts_processor.dart` 进行以下修复：

### 1. **语速缩放调整** (主要修复)
- **问题**: Android 上 `rate=1.0` 导致语速过快（听起来像1.5-2倍速）
- **修复**: 对 Android 平台应用 0.6 倍缩放系数
  - 用户设置 `rate=1.0` → 实际调用 `setSpeechRate(0.6)`
  - 用户设置 `rate=0.5` → 实际调用 `setSpeechRate(0.3)`
  - 用户设置 `rate=2.0` → 实际调用 `setSpeechRate(1.2)`

### 2. **初始化参数优化**
- Android 默认语速从 `1.0` 改为 `0.6`
- 添加 Android 音频设置配置（为未来扩展准备）

### 3. **音量诊断**
- 播放前检查系统音量
- 如果音量 < 50% 则输出警告日志

## 测试步骤

### 准备工作

1. **确认 Android 模拟器运行中**:
   ```powershell
   # 检查模拟器状态
   adb devices
   
   # 应该看到类似输出:
   # emulator-5554   device
   ```

2. **调整 Android 音量到最大**:
   - 方法 1: 在模拟器中按音量+键
   - 方法 2: 设置 → 声音 → 媒体音量拖到最右
   - 方法 3: `adb shell media volume --show --stream 3 --set 15`

3. **检查 TTS 引擎**:
   ```powershell
   adb shell settings get secure tts_default_synth
   ```

### 运行测试

#### 方式 1: 使用 PowerShell 脚本

```powershell
cd alouette_app
.\run_app.ps1 android
```

#### 方式 2: 直接使用 Flutter CLI

```powershell
cd alouette_app
flutter run -d emulator-5554
```

### 测试场景

#### 场景 1: 默认参数测试（最重要）
1. 打开应用
2. 选择任意语言（例如：English）
3. 输入测试文本: "Hello, this is a test of text to speech."
4. **不调整任何滑块**（保持默认 rate=1.0, pitch=1.0, volume=1.0）
5. 点击播放

**预期结果**:
- ✅ 语速正常（接近人类自然说话速度）
- ✅ 音量清晰（与媒体音量一致）
- ✅ 发音清晰

**查看日志**:
```
TTS: Initialized with defaults - rate=0.6, pitch=1.0, volume=1.0
TTS: Request params - rate=1.0, pitch=1.0, volume=1.0
Android TTS rate adjustment: requested=1.0 -> actual=0.6
Android TTS params: rate=0.6, pitch=1.0, volume=1.0
```

#### 场景 2: 慢速测试
1. 将语速滑块调到 **0.5** (一半速度)
2. 播放同样文本

**预期结果**:
- ✅ 语速明显变慢（约为正常速度的一半）

**查看日志**:
```
Android TTS rate adjustment: requested=0.5 -> actual=0.3
```

#### 场景 3: 快速测试
1. 将语速滑块调到 **1.5** (1.5倍速)
2. 播放同样文本

**预期结果**:
- ✅ 语速加快但仍可理解（约为正常速度的1.5倍）

**查看日志**:
```
Android TTS rate adjustment: requested=1.5 -> actual=0.9
```

#### 场景 4: 中文测试
1. 切换到中文语言（Chinese）
2. 输入: "你好，这是一个语音合成测试。"
3. 播放

**预期结果**:
- ✅ 中文发音清晰
- ✅ 语速适中

### 检查日志

#### 查看实时日志:
```powershell
# 过滤 TTS 相关日志
adb logcat | Select-String "TTS|flutter"

# 或使用 Flutter 工具
flutter logs
```

#### 关键日志标记:

**✅ 正常日志**:
```
TTS: Initialized with defaults - rate=0.6, pitch=1.0, volume=1.0
TTS: Configuring Android audio settings
TTS: Current Android system volume: 1.0
Android TTS rate adjustment: requested=1.0 -> actual=0.6
TTS: Set language to en-US
TTS: Speech started
TTS: Direct speech playback completed successfully
```

**⚠️ 警告日志** (需要调整):
```
TTS: System volume is low (0.3), speech may be quiet
```
→ **解决**: 增加 Android 系统音量

**❌ 错误日志**:
```
TTS: Speech error: -7
TTS resource busy (error -7). Please try again.
```
→ **解决**: 等待上一个播放完成，或重启应用

## 对比测试

### 修复前 vs 修复后

| 测试项       | 修复前                | 修复后              |
|-------------|----------------------|---------------------|
| rate=1.0    | 非常快（像1.5-2倍速）  | 正常速度            |
| rate=0.5    | 仍然偏快              | 明显变慢（约0.5倍）  |
| rate=1.5    | 极快（几乎听不清）     | 快速但可理解         |
| 音量        | 可能偏小              | 正常（跟随系统音量）  |

## 问题排查

### 问题 1: 语速仍然太快

**可能原因**:
- 缩放系数 0.6 对你的设备仍然偏高

**解决方案**:
编辑 `flutter_tts_processor.dart` 第 457 行：
```dart
// 将 0.6 改为 0.5 或 0.4
androidRate = rate * 0.5;  // 更慢
```

### 问题 2: 语速太慢

**解决方案**:
```dart
// 将 0.6 改为 0.7 或 0.8
androidRate = rate * 0.7;  // 稍快
```

### 问题 3: 音量仍然很小

**排查步骤**:
1. 检查日志中的音量值:
   ```
   TTS: Current Android system volume: 0.3  // 这个值应该接近 1.0
   ```

2. 手动设置系统音量:
   ```powershell
   # 设置媒体音量到最大 (0-15)
   adb shell media volume --stream 3 --set 15
   ```

3. 检查 TTS 引擎设置:
   - 模拟器: 设置 → 辅助功能 → TTS 输出
   - 确认使用的是 Google TTS 或系统默认 TTS

### 问题 4: 播放没有声音

**排查步骤**:
1. 检查日志中是否有错误
2. 确认模拟器音频输出正常:
   ```powershell
   # 播放测试音频
   adb shell media volume --show
   ```
3. 重启应用
4. 重启模拟器

## 测试数据记录

请记录你的测试结果：

```
【设备信息】
- 模拟器/真机: _____________
- Android 版本: _____________
- TTS 引擎: _____________

【测试结果】
- rate=1.0 语速: □ 太快 □ 正常 □ 太慢
- rate=0.5 语速: □ 太快 □ 正常 □ 太慢  
- rate=1.5 语速: □ 太快 □ 正常 □ 太慢
- 音量: □ 太小 □ 正常 □ 太大
- 发音清晰度: □ 差 □ 一般 □ 好

【需要的缩放系数调整】
- 建议系数: _________ (当前 0.6)
```

## 下一步

如果测试通过：
- ✅ 提交代码
- ✅ 更新文档
- ✅ 通知团队

如果仍有问题：
- 📝 记录具体现象
- 📋 提供完整日志
- 🔧 尝试调整缩放系数

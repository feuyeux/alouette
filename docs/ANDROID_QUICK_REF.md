# Android模拟器快速参考 / Android Emulator Quick Reference

## 🚀 一键安装 / One-Click Installation

```bash
./setup_android_emulator.sh install
```

## 📱 常用命令 / Common Commands

### 模拟器管理 / Emulator Management
```bash
# 启动模拟器 / Start emulator
./setup_android_emulator.sh start

# 检查状态 / Check status
./setup_android_emulator.sh status

# 查看所有设备 / List all devices
flutter devices

# 查看模拟器列表 / List emulators
flutter emulators
```

### 应用部署 / App Deployment
```bash
# 运行应用 / Run app
flutter run -d emulator-5554

# 构建APK / Build APK
flutter build apk --debug

# 安装APK / Install APK
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# 启动应用 / Launch app
adb shell am start -n com.alouette.app/.MainActivity
```

### 调试工具 / Debugging Tools
```bash
# 查看日志 / View logs
adb logcat | grep flutter

# 查看已安装应用 / List installed apps
adb shell pm list packages | grep alouette

# 卸载应用 / Uninstall app
adb uninstall com.alouette.app

# 重启adb / Restart adb
adb kill-server && adb start-server
```

## ⚙️ 配置信息 / Configuration

| 项目 | 值 |
|-----|-----|
| 模拟器名称 | `android_pixel` |
| 设备ID | `emulator-5554` |
| Android版本 | 14 (API 34) |
| 架构 | ARM64-v8a |
| 设备型号 | Pixel 7 |

## 🔧 故障排除 / Troubleshooting

### 模拟器启动失败
```bash
# 1. 删除旧模拟器
avdmanager delete avd -n android_pixel

# 2. 重新安装
./setup_android_emulator.sh install
```

### Flutter连接失败
```bash
# 重启adb并重新运行
adb kill-server
adb start-server
flutter run -d emulator-5554
```

### MainActivity找不到
确保文件存在: `android/app/src/main/kotlin/com/alouette/app/MainActivity.kt`

```kotlin
package com.alouette.app
import io.flutter.embedding.android.FlutterActivity
class MainActivity: FlutterActivity()
```

## 📚 更多文档 / More Documentation

- 📖 [完整设置指南](./ANDROID_EMULATOR_SETUP.md)
- 🏗️ [项目架构说明](../README.md)
- 🔗 [Flutter官方文档](https://flutter.dev/docs)

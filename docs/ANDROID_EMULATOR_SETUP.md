# Android模拟器快速设置指南
# Android Emulator Quick Setup Guide

本文档说明如何使用自动化脚本在新电脑上快速设置Android模拟器用于Flutter开发。

This document explains how to quickly set up an Android emulator on a new computer for Flutter development using automation scripts.

## 📋 前置要求 / Prerequisites

### 必需 / Required:
- ✅ **Flutter SDK** - [安装指南](https://flutter.dev/docs/get-started/install)
- ✅ **Android SDK** - 通常随Flutter一起安装 / Usually installed with Flutter
- ✅ **Android SDK Command-line Tools** - 通过Android Studio或sdkmanager安装

### 推荐 / Recommended:
- 🖥️ **Apple Silicon Mac** (ARM64) - 本脚本针对ARM64优化
- 💾 **至少5GB可用磁盘空间** - 用于系统镜像和模拟器
- 🌐 **良好的网络连接** - 首次下载需要1-2GB

## 🚀 快速开始 / Quick Start

### 1. 检查Flutter环境 / Check Flutter Environment

```bash
# 确认Flutter已安装
flutter doctor

# 如果提示Android许可问题，运行:
flutter doctor --android-licenses
```

### 2. 运行安装脚本 / Run Installation Script

```bash
# 进入项目根目录
cd /path/to/alouette

# 给脚本执行权限（仅首次需要）
chmod +x setup_android_emulator.sh

# 安装模拟器
./setup_android_emulator.sh install
```

**安装过程会:**
- ✅ 检测系统架构（ARM64/x86_64）
- ✅ 验证必要工具（Flutter, sdkmanager, avdmanager）
- ✅ 下载Android 14 (API 34) ARM64系统镜像（带Google Play）
- ✅ 创建名为`android_pixel`的Pixel 7模拟器

### 3. 启动模拟器 / Start Emulator

```bash
# 启动模拟器
./setup_android_emulator.sh start

# 等待30-60秒直到看到:
# ✅ 模拟器启动成功!
# emulator-5554 • sdk gphone64 arm64 • android-arm64 • Android 14 (API 34)
```

### 4. 运行Flutter应用 / Run Flutter App

```bash
# 进入应用目录
cd alouette_app

# 方法1: 使用flutter run
flutter run -d emulator-5554

# 方法2: 使用项目脚本（如果有）
./run_app.sh android
```

## 📚 脚本命令参考 / Script Command Reference

### `install` - 安装模拟器
完整的安装流程，包括系统镜像下载和模拟器创建。

```bash
./setup_android_emulator.sh install
```

### `start` - 启动模拟器
启动已安装的模拟器。如果模拟器已在运行，会显示当前状态。

```bash
./setup_android_emulator.sh start
```

### `status` - 检查状态
显示当前Flutter设备和模拟器列表。

```bash
./setup_android_emulator.sh status
```

### `help` - 显示帮助
显示详细的使用说明和配置信息。

```bash
./setup_android_emulator.sh help
```

## ⚙️ 配置说明 / Configuration

脚本默认配置（可在脚本中修改）:

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| 模拟器名称 | `android_pixel` | AVD名称 |
| Android版本 | `34` | Android 14 |
| 系统镜像 | `google_apis_playstore` ARM64 | 带Google Play的完整镜像 |
| 设备配置 | `pixel_7` | Pixel 7手机配置 |

## 🔧 常见问题 / Troubleshooting

### 问题1: 模拟器启动失败 (CPU架构不匹配)
**错误信息:** `PANIC: Avd's CPU Architecture 'x86_64' is not supported by the QEMU2 emulator on aarch64 host`

**解决方案:**
- 确保使用ARM64系统镜像（脚本已自动处理）
- 删除旧的x86_64模拟器: `avdmanager delete avd -n <name>`
- 重新运行: `./setup_android_emulator.sh install`

### 问题2: 下载速度慢
**解决方案:**
1. 设置国内镜像源（已在Gradle配置中设置）
2. 使用VPN或代理
3. 等待一段时间，系统镜像较大（~1GB）

### 问题3: Flutter无法连接到模拟器
**症状:** `Error waiting for a debug connection`

**解决方案:**
```bash
# 1. 检查模拟器是否真正启动
adb devices

# 2. 重启adb服务
adb kill-server && adb start-server

# 3. 重新运行应用
flutter run -d emulator-5554
```

### 问题4: MainActivity类找不到
**错误信息:** `ClassNotFoundException: Didn't find class "MainActivity"`

**解决方案:**
确保MainActivity.kt文件存在且package正确:
```kotlin
// File: android/app/src/main/kotlin/com/alouette/app/MainActivity.kt
package com.alouette.app

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity()
```

## 📱 模拟器使用技巧 / Emulator Tips

### 查看已安装的应用
```bash
adb shell pm list packages | grep com.alouette
```

### 查看应用日志
```bash
adb logcat | grep flutter
```

### 卸载应用
```bash
adb uninstall com.alouette.app
```

### 重新安装APK
```bash
# 构建APK
flutter build apk --debug

# 安装
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

### 启动应用
```bash
adb shell am start -n com.alouette.app/.MainActivity
```

## 🌐 Gradle国内镜像配置 / Gradle China Mirrors

项目已配置阿里云镜像加速下载（见`android/settings.gradle.kts`）:

```kotlin
pluginManagement {
    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/jcenter") }
        
        // Flutter SDK本地仓库
        val storageUrl = System.getenv("FLUTTER_STORAGE_BASE_URL") 
            ?: "https://storage.googleapis.com"
        maven { url = uri("$storageUrl/download.flutter.io") }
        
        google()
        mavenCentral()
    }
}
```

## 📝 其他平台 / Other Platforms

### Windows PowerShell版本
如需Windows版本，可以使用PowerShell转换脚本逻辑，或使用Android Studio的AVD Manager图形界面。

### Intel Mac (x86_64)
修改脚本中的系统镜像为x86_64:
```bash
SYSTEM_IMAGE="system-images;android-34;google_apis_playstore;x86_64"
```

## 🔗 相关链接 / Related Links

- [Flutter官方文档](https://flutter.dev/docs)
- [Android模拟器文档](https://developer.android.com/studio/run/emulator)
- [AVD Manager命令行工具](https://developer.android.com/studio/command-line/avdmanager)
- [阿里云Maven仓库](https://developer.aliyun.com/mvn/guide)

## 📄 License

MIT License - 可自由修改和分发 / Free to modify and distribute

# Android Build Guide for Alouette

A comprehensive guide for building and deploying the Alouette AI translation application on Android devices across different platforms.

> **🔧 Development Note**: For daily verification and development, use **debug builds** (`npm run tauri android dev`). Release builds are only for production deployment.
> 
> **📋 正确执行顺序**: 
> 1. **配置环境变量** → 设置ANDROID_HOME和PATH
> 2. **初始化项目** → `npm run tauri android init` (仅首次)
> 3. **启动模拟器** → 使用完整路径启动AVD
> 4. **编译应用** → `npm run tauri android dev`
> 5. **部署运行** → 自动安装到模拟器
>
> **⚠️ Linux Users**: 必须使用完整路径 `$ANDROID_HOME/emulator/emulator` 而不是 `emulator` 命令。参见 [Troubleshooting](#troubleshooting)。
>
> **⚠️ Memory Warning**: Linux系统模拟器内存不要超过1GB。使用2GB+会导致系统崩溃和VS Code OOM-kill。**推荐: 1GB稳定运行**。
>
> **🚨 Critical**: 如果模拟器反复崩溃，减少到1GB内存并使用 `-gpu swiftshader_indirect` 禁用硬件加速。

## 📋 Table of Contents

1. [Status Overview](#status-overview)
2. [Platform-Specific Setup](#platform-specific-setup)
   - [macOS (Apple Silicon)](#macos-apple-silicon)
   - [Linux](#linux)
3. [Development Workflow](#development-workflow)
4. [Debug vs Release Build Guide](#-debug-vs-release-build-guide)
5. [Android Feature Verification Process](#android-feature-verification-process)
6. [Troubleshooting](#troubleshooting)
7. [Translation Feature Debugging](#translation-feature-debugging)

---

## Status Overview

### ✅ Current Status (June 24, 2025)

**Translation functionality**: **FIXED** ✅  
**Build status**: Verified working on both macOS and Linux  
**Target platforms**: Android 14 (API 34), ARM64 and x86_64  
**Verification strategy**: **Debug builds first** - Use debug builds for daily development

#### Key Achievements
- ✅ **Translation errors resolved** - Fixed "undefined" error issues
- ✅ **Cross-platform builds** - Working on macOS Apple Silicon and Linux
- ✅ **Network connectivity** - Ollima integration verified
- ✅ **Comprehensive error handling** - Enhanced debugging capabilities
- ✅ **Performance optimized** - Debug APK ~726MB, Release APK ~120MB
- 🔧 **Development workflow optimized** - Debug builds auto-signed for direct installation

#### Build Version Notes
- **Debug Build**: 726MB, auto-signed, for daily development and feature verification
- **Release Build**: 120MB, requires manual signing, only for app store deployment

---

## Platform-Specific Setup

### macOS (Apple Silicon)

#### Prerequisites
- **Hardware**: M1/M2/M3 Mac
- **macOS**: Sonoma or later
- **Xcode**: Latest version with command line tools

#### Quick Setup
If you have Android NDK files in `/Users/han/Downloads/`:

```bash
# Create development directory
mkdir -p ~/zoo && cd ~/zoo

# Setup NDK (if downloaded)
hdiutil attach /Users/han/Downloads/android-ndk-r28b-darwin.dmg
cp -R "/Volumes/Android NDK r28b 1/AndroidNDK13356709.app/Contents/NDK/" ./android-ndk-r28b
hdiutil detach "/Volumes/Android NDK r28b 1"

# Extract Platform Tools
unzip /Users/han/Downloads/platform-tools-latest-darwin.zip

# Create environment script
cat > android-env.sh << 'EOF'
export ANDROID_HOME="$HOME/zoo/android-sdk"
export NDK_HOME="$HOME/zoo/android-ndk-r28b"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin:$PATH"
EOF

# Load environment
source android-env.sh
```

#### Emulator Management (macOS)

```bash
# List available system images
sdkmanager --list | grep "system-images.*arm64"

# Create ARM64 AVD (REQUIRED for Apple Silicon)
avdmanager create avd -n Alouette_ARM64 -k "system-images;android-34;google_apis_playstore;arm64-v8a" -d "pixel_7"

# Start emulator with optimized settings
emulator -avd Alouette_ARM64 -memory 4096 -cores 4 -gpu auto -no-snapshot-save &

# Verify connection
adb wait-for-device && adb devices
```

### Linux

#### Prerequisites
- **Distribution**: Ubuntu 20.04+ or equivalent
- **Architecture**: x86_64 (Intel/AMD)
- **Memory**: 8GB+ recommended

#### Environment Setup

```bash
# Set up Android SDK in project directory
cd /path/to/your/alouette/project
export ANDROID_HOME="$PWD/android-sdk"
export GRADLE_HOME="$PWD/gradle-8.14.2"  # 使用项目本地Gradle
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$GRADLE_HOME/bin:$PATH"

# Verify ADB, Gradle and emulator are accessible
adb --version
gradle --version  # 应该显示8.14.2
which emulator || echo "emulator not in PATH, use full path: $ANDROID_HOME/emulator/emulator"

# IMPORTANT: If 'emulator' command is not found, always use the full path:
# $ANDROID_HOME/emulator/emulator [options]
```

#### Emulator Management (Linux)

```bash
# IMPORTANT: First set up environment variables if not already done
export ANDROID_HOME="$PWD/android-sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$PATH"

# Verify emulator is accessible
which emulator || echo "ERROR: emulator not found in PATH. Please run export commands above first."

# Check available AVDs
$ANDROID_HOME/emulator/emulator -list-avds

# Create x86_64 AVD for Linux (if needed)
avdmanager create avd -n Alouette_Test -k "system-images;android-34;google_apis_playstore;x86_64" -d "pixel_7"

# Start emulator with optimized settings (REDUCED memory to prevent crashes)
$ANDROID_HOME/emulator/emulator -avd Alouette_Test -memory 2048 -partition-size 4096 -cores 2 -gpu swiftshader_indirect -no-boot-anim -no-snapshot-save &

# Wait for device and verify
sleep 20 && adb wait-for-device && adb devices
```

#### Linux-Specific Troubleshooting

**ADB Detection Issue**: If you see "Could not automatically detect an ADB binary" error:

```bash
# Ensure ADB is in PATH and executable
chmod +x $ANDROID_HOME/platform-tools/adb
export PATH="$ANDROID_HOME/platform-tools:$PATH"

# Test ADB directly
$ANDROID_HOME/platform-tools/adb devices
```

**VS Code 进程崩溃（OOM-Kill）**: 在执行 Android 操作时 VS Code 突然退出:

> **⚠️ 重要警告**: 不要使用6GB以上的内存分配给模拟器，这会导致系统崩溃！推荐使用2-4GB内存。

```bash
# 1. 减少模拟器内存分配 (使用完整路径)
$ANDROID_HOME/emulator/emulator -avd Alouette_Test -memory 2048 -cores 2 -gpu auto

# 2. 增加系统交换空间（临时）
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 3. 使用低内存模式启动 VS Code
code-insiders --disable-gpu --max-old-space-size=4096

# 4. 监控内存使用
watch -n 2 'free -h && echo "=== Top Memory Users ===" && ps aux --sort=-%mem | head -5'
```

---

## Development Workflow

> **🔧 正确执行顺序**: 配置环境变量 → 初始化Android项目 → 启动模拟器 → 编译 → 部署

### 步骤1: 配置环境变量 (必须首先执行)

**For macOS:**
```bash
cd ~/zoo && source android-env.sh
```

**For Linux:**
```bash
cd /path/to/alouette
export ANDROID_HOME="$PWD/android-sdk"
export GRADLE_HOME="$PWD/gradle-8.14.2"  # 使用项目本地Gradle
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$GRADLE_HOME/bin:$PATH"

# 验证环境变量
echo "ANDROID_HOME: $ANDROID_HOME"
echo "GRADLE_HOME: $GRADLE_HOME"
echo "PATH contains emulator: $(echo $PATH | grep emulator)"
echo "PATH contains gradle: $(echo $PATH | grep gradle)"

# 验证工具版本
gradle --version  # 应该显示8.14.2
adb --version
```

### 步骤2: 初始化Android项目 (首次运行必须)

```bash
# 导航到项目目录
cd /path/to/your/alouette/project

# 初始化Tauri Android项目 (仅首次需要)
npm run tauri android init

# 验证初始化结果
ls -la src-tauri/gen/android/
```

#### 配置本地Gradle工具 (可选)

如果你想使用本地的Gradle工具而不是Gradle Wrapper (gradlew)，可以进行以下配置：

**方法1: 环境变量配置**
```bash
# 设置GRADLE_HOME指向本地Gradle安装目录
export GRADLE_HOME="/path/to/your/gradle-8.14.2"
export PATH="$GRADLE_HOME/bin:$PATH"

# 验证Gradle版本
gradle --version
```

**方法2: 修改tauri.conf.json配置**
在 `src-tauri/tauri.conf.json` 中添加Android配置：

```json
{
  // ...existing config...
  "android": {
    "gradle": {
      "useWrapper": false,
      "gradlePath": "/path/to/your/gradle-8.14.2/bin/gradle"
    },
    "minSdkVersion": 24,
    "compileSdkVersion": 34,
    "targetSdkVersion": 34
  }
}
```

**方法3: 项目本地Gradle配置**
```bash
# 在项目中使用本地Gradle
export GRADLE_HOME="$PWD/gradle-8.14.2"
export PATH="$GRADLE_HOME/bin:$PATH"

# 初始化时Tauri会自动检测到本地Gradle
npm run tauri android init

# 验证配置
cd src-tauri/gen/android
gradle wrapper --gradle-version 8.14.2
```

**方法4: 禁用Wrapper的gradle.properties配置**
在 `src-tauri/gen/android/gradle.properties` 中添加：
```properties
# 使用本地Gradle而不是Wrapper
org.gradle.java.home=/usr/lib/jvm/java-21-openjdk-amd64
android.useAndroidX=true
android.enableJetifier=true
```

#### 验证本地Gradle配置

```bash
# 检查Gradle配置
cd src-tauri/gen/android

# 方式1: 使用本地gradle命令
gradle -v

# 方式2: 检查gradle wrapper配置
cat gradle/wrapper/gradle-wrapper.properties

# 方式3: 检查构建是否使用本地gradle
gradle clean assembleDebug --info | grep "Gradle version"
```

#### Linux系统推荐配置

对于Linux系统，推荐使用项目本地的Gradle：

```bash
# 设置本地Gradle环境
export GRADLE_HOME="$PWD/gradle-8.14.2" 
export PATH="$GRADLE_HOME/bin:$PATH"

# 初始化Android项目
npm run tauri android init

# 验证使用本地Gradle
cd src-tauri/gen/android
gradle --version  # 应该显示8.14.2版本
```
### 步骤3: 启动Android模拟器

**For macOS:**
```bash
# 检查可用AVD
$ANDROID_HOME/emulator/emulator -list-avds

# 启动模拟器 (ARM64 for Apple Silicon)
$ANDROID_HOME/emulator/emulator -avd Alouette_ARM64 -memory 4096 -cores 4 -gpu auto -no-snapshot-save &

# 等待设备连接
adb wait-for-device && adb devices
```

**For Linux:**
```bash
# 检查可用AVD
$ANDROID_HOME/emulator/emulator -list-avds

# 启动模拟器 (平衡内存设置支持Ollama模型)
$ANDROID_HOME/emulator/emulator -avd Alouette_Test -memory 2048 -partition-size 4096 -cores 2 -gpu swiftshader_indirect -no-boot-anim -no-snapshot-save -no-audio &

# 等待设备连接
sleep 30 && adb wait-for-device && adb devices
```

### 步骤4: 编译应用

```bash
# 方式1: 开发模式 (推荐 - 自动编译+安装+热重载)
npm run tauri android dev

# 方式2: 手动构建
npm run tauri android build --debug

# 方式3: 使用package.json中的脚本
npm run build:android
```

### 步骤5: 部署到设备

```bash
# 如果使用开发模式，应用会自动安装
# 手动安装(如果需要)
adb install -r src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk

# 启动应用
adb shell am start -n com.alouette.app/com.alouette.app.MainActivity

# 查看应用日志
adb logcat | grep -i alouette
```

### 快速开发模式 (一键启动)

```bash
# 确保环境变量已设置且模拟器已启动，然后：
npm run tauri android dev

# 此命令会自动：
# 1. 构建Rust后端
# 2. 构建Vue前端  
# 3. 安装应用到连接的设备/模拟器
# 4. 启用前端代码热重载
```

---

## Troubleshooting

### 执行顺序相关问题

#### 跳过环境变量配置导致的错误

**错误1: emulator命令未找到**
```
Error: 找不到命令 "emulator"
bash: emulator: command not found
```
**解决方案**: 必须先配置环境变量
```bash
# 步骤1: 设置环境变量 (必须首先执行)
export ANDROID_HOME="$PWD/android-sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$PATH"

# 步骤2: 验证环境变量
echo "ANDROID_HOME: $ANDROID_HOME"
which emulator || echo "使用完整路径: $ANDROID_HOME/emulator/emulator"
```

**错误2: 跳过初始化直接编译**
```
Error: Error You must run `tauri android init` and add the `[android]` config to be able to use this command
```
**解决方案**: 必须先初始化Android项目
```bash
# 步骤1: 初始化 (仅首次需要)
npm run tauri android init

# 步骤2: 验证初始化成功
ls -la src-tauri/gen/android/
```

**错误3: 没有连接设备就编译**
```
Error: No Android devices found
Could not find a suitable device
```
**解决方案**: 必须先启动模拟器或连接设备
```bash
# 步骤1: 启动模拟器
$ANDROID_HOME/emulator/emulator -avd Alouette_Test &

# 步骤2: 等待设备连接
adb wait-for-device && adb devices

# 步骤3: 确认设备已连接后再编译
npm run tauri android dev
```

**错误4: Gradle Wrapper 下载失败或版本冲突**
```
Error: Could not download gradle-8.x.x-bin.zip
Error: Gradle wrapper did not finish downloading
```
**解决方案**: 配置使用本地Gradle工具
```bash
# 步骤1: 设置本地Gradle环境
export GRADLE_HOME="$PWD/gradle-8.14.2"
export PATH="$GRADLE_HOME/bin:$PATH"

# 步骤2: 验证本地Gradle
gradle --version

# 步骤3: 重新初始化（会使用本地Gradle）
npm run tauri android init

# 步骤4: 手动配置gradle wrapper（如果需要）
cd src-tauri/gen/android
gradle wrapper --gradle-version 8.14.2
```

**错误5: Gradle版本不兼容**
```
Error: Minimum supported Gradle version is X.X. Current version is Y.Y
```
**解决方案**: 确保Gradle版本匹配
```bash
# 检查项目要求的Gradle版本
cat src-tauri/gen/android/gradle/wrapper/gradle-wrapper.properties

# 使用匹配的本地Gradle版本
export GRADLE_HOME="$PWD/gradle-8.14.2"  # 确保版本匹配
export PATH="$GRADLE_HOME/bin:$PATH"

# 重新构建
npm run tauri android build --debug
```
### Common Issues by Platform

#### macOS Issues

**QEMU Panic Error**
```
Error: PANIC: Avd's CPU Architecture 'x86_64' is not supported by the QEMU2 emulator on aarch64 host
```
**Solution**: Use ARM64 system images only
```bash
# ✅ Correct for Apple Silicon
avdmanager create avd -k "system-images;android-34;google_apis_playstore;arm64-v8a"

# ❌ Wrong for Apple Silicon  
avdmanager create avd -k "system-images;android-34;google_apis_playstore;x86_64"
```

**OpenSSL Compilation Error**
```
Error: /bin/sh: aarch64-linux-android-ranlib: command not found
```
**Solution**: Create missing symlink
```bash
cd $NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin
ln -s llvm-ranlib aarch64-linux-android-ranlib
```

#### Linux Issues

**Emulator Command Not Found**
```
Error: 找不到命令 "emulator"，但可以通过以下软件包安装它：
sudo apt install google-android-emulator-installer
```
**Solution**: Use full path to emulator binary and set up environment correctly
```bash
# Step 1: Verify emulator exists in Android SDK
ls -la $ANDROID_HOME/emulator/emulator

# Step 2: Always use full path or ensure PATH is set
export ANDROID_HOME="$PWD/android-sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$PATH"

# Step 3: Use full path for reliable execution
$ANDROID_HOME/emulator/emulator -list-avds
$ANDROID_HOME/emulator/emulator -avd Alouette_Test [other-options]

# Step 4: Verify emulator is accessible
which emulator || echo "Use full path: $ANDROID_HOME/emulator/emulator"
```

**ADB Binary Detection**
```
Error: Could not automatically detect an ADB binary
```
**Solution**: Set proper permissions and PATH
```bash
chmod +x $ANDROID_HOME/platform-tools/adb
export PATH="$ANDROID_HOME/platform-tools:$PATH"
```

**Platform-tools Version Issue**
```
Symptom: adb version shows "minimal" without full functionality
```
**Solution**: Ensure complete platform-tools installation
```bash
# Check current adb version
adb version

# If output shows "minimal", reinstall platform-tools
cd $ANDROID_HOME
wget https://dl.google.com/android/repository/platform-tools-latest-linux.zip
rm -rf platform-tools
unzip platform-tools-latest-linux.zip
rm platform-tools-latest-linux.zip

# Verify installation
adb version  # Should show complete version (e.g., 35.0.2)
```

**Emulator Permission Denied**
```
Error: /dev/kvm permission denied
```
**Solution**: Add user to kvm group
```bash
sudo usermod -a -G kvm $USER
# Logout and login again
```

### Network Configuration

#### Ollama Server Setup

**For emulator testing**, Ollima must be accessible from the Android device:

```bash
# Start Ollima with network access
OLLIMA_HOST=0.0.0.0:11434 ollima serve

# Find your local IP
ip route get 1.1.1.1 | awk '{print $7; exit}'  # Linux
ifconfig | grep "inet " | grep -v 127.0.0.1     # macOS
```

**In Alouette app settings:**
- Server URL: `http://YOUR_LOCAL_IP:11434`
- Model: Select available model (e.g., `qwen2.5:1.5b`)

---

## Translation Feature Debugging

### Enhanced Error Handling (Fixed)

The translation functionality now includes comprehensive error handling:

#### Debug Logging
All translation attempts now generate detailed logs:

```
Android Debug - Starting translation process
Android Debug - Text: 'Hello world'
Android Debug - Target languages: ["Chinese"]
Android Debug - Provider: ollima
Android Debug - Server URL: http://192.168.1.100:11434
Android Debug - Model: qwen2.5:1.5b
```

#### Error Categories

1. **Network Errors**: Connection refused, timeouts
2. **Validation Errors**: Empty text, missing configuration
3. **Response Errors**: Empty responses, JSON parse failures
4. **Model Errors**: Model not found, insufficient resources

#### Monitoring Logs

**Android device logs:**
```bash
adb logcat | grep -E "(Android Debug|Alouette|RustStdoutStderr)"
```

**Expected successful output:**
```
Android Debug - Final translation result: '你好世界'
Android Debug - Successfully translated to Chinese: '你好世界'
Android Debug - Translation process completed successfully with 1 results
```

### Verification Steps

1. **Build latest version** with fixes
2. **Install to device/emulator**
3. **Configure Ollima connection** with local IP
4. **Test translation** with simple text
5. **Monitor logs** for detailed debugging information

---

## Build Environment Details

### Verified Configurations

#### macOS Apple Silicon
- **OS**: macOS Sonoma (M3)
- **NDK**: r28b  
- **API Level**: 34 (Android 14)
- **Target**: `aarch64-linux-android`
- **Emulator**: ARM64 system images

#### Linux x86_64
- **OS**: Ubuntu 20.04+
- **NDK**: r28b
- **API Level**: 34 (Android 14)  
- **Target**: `x86_64-linux-android`
- **Emulator**: x86_64 system images

### Performance Metrics
- **APK Size**: ~726MB (debug build)
- **Launch Time**: <3 seconds
- **Memory Usage**: 4-6GB during build
- **Build Time**: 10-15 minutes (first build)

---

**Last Updated**: June 17, 2025  
**Status**: All major issues resolved ✅
$ANDROID_HOME/emulator/emulator -avd Alouette_ARM64 -no-snapshot-save &

# 3. Wait for emulator to boot
adb wait-for-device

# 4. Navigate to your project and build
cd /path/to/your/alouette/project
npm run tauri android build

# 5. Install and run
adb install src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk
adb shell am start -n com.alouette.app/com.alouette.app.MainActivity
```

## ⚠️ Apple Silicon Mac Specific Requirements

**IMPORTANT**: On Apple Silicon Macs, you MUST use ARM64 system images for the Android emulator. x86_64 images will not work and will show a QEMU panic error.

**Correct system image**: `system-images;android-34;google_apis_playstore;arm64-v8a`  
**Incorrect**: `system-images;android-34;google_apis_playstore;x86_64` ❌

## Prerequisites

### For macOS

#### Option 1: Quick Setup with Pre-downloaded Files

If you have downloaded the following files到 `/Users/han/Downloads/`:

- `android-ndk-r28b-darwin.dmg`
- `platform-tools-latest-darwin.zip`

Run the automated setup:

```bash
# Create development directory
mkdir -p ~/zoo && cd ~/zoo

# Mount and extract NDK
hdiutil attach /Users/han/Downloads/android-ndk-r28b-darwin.dmg
cp -R "/Volumes/Android NDK r28b 1/AndroidNDK13356709.app/Contents/NDK/" ./android-ndk-r28b
hdiutil detach "/Volumes/Android NDK r28b 1"

# Extract Platform Tools
unzip /Users/han/Downloads/platform-tools-latest-darwin.zip

# Create Android SDK directory
mkdir -p android-sdk/cmdline-tools

# Download and setup Android SDK Command Line Tools
curl -o commandlinetools-mac.zip https://dl.google.com/android/repository/commandlinetools-mac-11076708_latest.zip
unzip commandlinetools-mac.zip -d android-sdk/cmdline-tools/
mv android-sdk/cmdline-tools/cmdline-tools android-sdk/cmdline-tools/latest

# Setup environment variables with NDK toolchain fixes
cat > android-env.sh << 'EOF'
#!/bin/bash
# Android Development Environment Setup for macOS (Apple Silicon)

export ANDROID_HOME="$HOME/zoo/android-sdk"
export ANDROID_SDK_ROOT="$HOME/zoo/android-sdk"
export NDK_HOME="$HOME/zoo/android-ndk-r28b"
export PATH="$HOME/zoo/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin:$PATH"

echo "Android Environment Variables Set:"
echo "ANDROID_HOME: $ANDROID_HOME"
echo "ANDROID_SDK_ROOT: $ANDROID_SDK_ROOT"
echo "NDK_HOME: $NDK_HOME"
echo "PATH updated with Android tools and NDK toolchain"
EOF

chmod +x android-env.sh
source android-env.sh

# Fix missing ranlib tool for OpenSSL compilation
cd $NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin/
ln -sf llvm-ranlib aarch64-linux-android-ranlib
ln -sf llvm-ar aarch64-linux-android-ar
ln -sf llvm-strip aarch64-linux-android-strip

# Install required Android SDK components (ARM64 for Apple Silicon)
yes | sdkmanager --licenses
sdkmanager "platforms;android-34" "build-tools;34.0.0" "emulator" "system-images;android-34;google_apis_playstore;arm64-v8a"

# Create ARM64 Android Virtual Device (compatible with Apple Silicon)
avdmanager create avd -n "Alouette_ARM64" -k "system-images;android-34;google_apis_playstore;arm64-v8a" -d "pixel_7"
```

#### Option 2: Manual Installation

Install essential build tools and Java development kit:

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install openjdk@21 wget unzip curl

# Add Java to PATH
echo 'export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"' >> ~/.zshrc
echo 'export JAVA_HOME="/opt/homebrew/opt/openjdk@21"' >> ~/.zshrc
source ~/.zshrc
```

### For Linux

Install essential build tools and Java development kit:

```bash
sudo apt update && sudo apt install -y \
  clang llvm build-essential \
  openjdk-21-jdk \
  wget unzip curl
```

### Add Rust Android Targets

Add Android targets for Rust compilation:

```bash
rustup target add \
  aarch64-linux-android \
  armv7-linux-androideabi \
  i686-linux-android \
  x86_64-linux-android

rustup target list --installed | grep android
```

### Initialize Tauri Android Project

Set up the Android project structure:

```bash
# Navigate to your Alouette project
cd /path/to/your/alouette/project

# Initialize Android support (if not already done)
npx @tauri-apps/cli android init

# Install dependencies
npm install
```

## Building the Application

### Build for Android

#### 📱 Debug vs Release Build Guide

**Important Note**: For daily development and verification, we **only use debug builds**, unless deploying to app stores.

#### 🔧 Debug Build (Recommended for Development)

Debug APKs have the following characteristics:
- ✅ **Auto-signed** - Uses debug certificate, can be installed directly
- ✅ **Fast build** - Shorter compilation time
- ✅ **Development tools** - Includes debug info and logging
- ✅ **Hot reload** - Supports live updates in development mode
- ❌ **Larger file** - Includes debug symbols, APK ~726MB

```bash
# Build debug APK (recommended)
npm run dev:android

# Or manually build debug version
npm run build:android
```

**Output path**: `src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk`

#### 🚀 Release Build (Production Only)

Release APKs have the following characteristics:
- ❌ **Requires signing** - Generates unsigned APK, cannot be installed directly
- ⚡ **Optimized build** - Code optimization, better performance
- 📦 **Smaller file** - Debug info removed, APK ~120MB
- 🔒 **Production ready** - Suitable for app store deployment

```bash
# Build release APK (requires subsequent signing)
npm run build:android -- --release

# Build AAB bundle (Google Play Store)
npm run build:android -- --bundle aab
```

**Output path**: `src-tauri/gen/android/app/build/outputs/apk/universal/release/app-universal-release-unsigned.apk`

#### 🛠️ Verification and Testing Workflow

```bash
# 1. Environment setup (once per session)
cd ~/zoo && source android-env.sh  # macOS
# or
export ANDROID_HOME="$PWD/android-sdk" && export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$PATH"  # Linux

# 2. Start emulator (if not running)
adb devices
# If no device, start emulator
$ANDROID_HOME/emulator/emulator -avd Alouette_Test -memory 4096 -cores 2 -gpu auto &

# 3. Build and install debug version (recommended)
cd /path/to/your/alouette/project
npm run dev:android

# 4. Manual debug installation (if needed)
adb install -r src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk

# 5. Launch application
adb shell am start -n com.alouette.app/com.alouette.app.MainActivity

# 6. View logs
adb logcat | grep -E "(alouette|Alouette|RustStdoutStderr)"
```

### 步骤1: 配置环境变量 (必须首先执行)

**For macOS:**
```bash
cd ~/zoo && source android-env.sh
```

**For Linux:**
```bash
cd /path/to/alouette
export ANDROID_HOME="$PWD/android-sdk"
export GRADLE_HOME="$PWD/gradle-8.14.2"  # 使用项目本地Gradle
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$GRADLE_HOME/bin:$PATH"

# 验证环境变量
echo "ANDROID_HOME: $ANDROID_HOME"
echo "GRADLE_HOME: $GRADLE_HOME"
echo "PATH contains emulator: $(echo $PATH | grep emulator)"
echo "PATH contains gradle: $(echo $PATH | grep gradle)"

# 验证工具版本
gradle --version  # 应该显示8.14.2
adb --version
```

### 步骤2: 初始化Android项目 (首次运行必须)

```bash
# 导航到项目目录
cd /path/to/your/alouette/project

# 初始化Tauri Android项目 (仅首次需要)
npm run tauri android init

# 验证初始化结果
ls -la src-tauri/gen/android/
```

#### 配置本地Gradle工具 (可选)

如果你想使用本地的Gradle工具而不是Gradle Wrapper (gradlew)，可以进行以下配置：

**方法1: 环境变量配置**
```bash
# 设置GRADLE_HOME指向本地Gradle安装目录
export GRADLE_HOME="/path/to/your/gradle-8.14.2"
export PATH="$GRADLE_HOME/bin:$PATH"

# 验证Gradle版本
gradle --version
```

**方法2: 修改tauri.conf.json配置**
在 `src-tauri/tauri.conf.json` 中添加Android配置：

```json
{
  // ...existing config...
  "android": {
    "gradle": {
      "useWrapper": false,
      "gradlePath": "/path/to/your/gradle-8.14.2/bin/gradle"
    },
    "minSdkVersion": 24,
    "compileSdkVersion": 34,
    "targetSdkVersion": 34
  }
}
```

**方法3: 项目本地Gradle配置**
```bash
# 在项目中使用本地Gradle
export GRADLE_HOME="$PWD/gradle-8.14.2"
export PATH="$GRADLE_HOME/bin:$PATH"

# 初始化时Tauri会自动检测到本地Gradle
npm run tauri android init

# 验证配置
cd src-tauri/gen/android
gradle wrapper --gradle-version 8.14.2
```

**方法4: 禁用Wrapper的gradle.properties配置**
在 `src-tauri/gen/android/gradle.properties` 中添加：
```properties
# 使用本地Gradle而不是Wrapper
org.gradle.java.home=/usr/lib/jvm/java-21-openjdk-amd64
android.useAndroidX=true
android.enableJetifier=true
```

#### 验证本地Gradle配置

```bash
# 检查Gradle配置
cd src-tauri/gen/android

# 方式1: 使用本地gradle命令
gradle -v

# 方式2: 检查gradle wrapper配置
cat gradle/wrapper/gradle-wrapper.properties

# 方式3: 检查构建是否使用本地gradle
gradle clean assembleDebug --info | grep "Gradle version"
```

#### Linux系统推荐配置

对于Linux系统，推荐使用项目本地的Gradle：

```bash
# 设置本地Gradle环境
export GRADLE_HOME="$PWD/gradle-8.14.2" 
export PATH="$GRADLE_HOME/bin:$PATH"

# 初始化Android项目
npm run tauri android init

# 验证使用本地Gradle
cd src-tauri/gen/android
gradle --version  # 应该显示8.14.2版本
```
### 步骤3: 启动Android模拟器

**For macOS:**
```bash
# 检查可用AVD
$ANDROID_HOME/emulator/emulator -list-avds

# 启动模拟器 (ARM64 for Apple Silicon)
$ANDROID_HOME/emulator/emulator -avd Alouette_ARM64 -memory 4096 -cores 4 -gpu auto -no-snapshot-save &

# 等待设备连接
adb wait-for-device && adb devices
```

**For Linux:**
```bash
# 检查可用AVD
$ANDROID_HOME/emulator/emulator -list-avds

# 启动模拟器 (平衡内存设置支持Ollama模型)
$ANDROID_HOME/emulator/emulator -avd Alouette_Test -memory 2048 -partition-size 4096 -cores 2 -gpu swiftshader_indirect -no-boot-anim -no-snapshot-save -no-audio &

# 等待设备连接
sleep 30 && adb wait-for-device && adb devices
```

### 步骤4: 编译应用

```bash
# 方式1: 开发模式 (推荐 - 自动编译+安装+热重载)
npm run tauri android dev

# 方式2: 手动构建
npm run tauri android build --debug

# 方式3: 使用package.json中的脚本
npm run build:android
```

### 步骤5: 部署到设备

```bash
# 如果使用开发模式，应用会自动安装
# 手动安装(如果需要)
adb install -r src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk

# 启动应用
adb shell am start -n com.alouette.app/com.alouette.app.MainActivity

# 查看应用日志
adb logcat | grep -i alouette
```

### 快速开发模式 (一键启动)

```bash
# 确保环境变量已设置且模拟器已启动，然后：
npm run tauri android dev

# 此命令会自动：
# 1. 构建Rust后端
# 2. 构建Vue前端  
# 3. 安装应用到连接的设备/模拟器
# 4. 启用前端代码热重载
```

---

## Troubleshooting

### 执行顺序相关问题

#### 跳过环境变量配置导致的错误

**错误1: emulator命令未找到**
```
Error: 找不到命令 "emulator"
bash: emulator: command not found
```
**解决方案**: 必须先配置环境变量
```bash
# 步骤1: 设置环境变量 (必须首先执行)
export ANDROID_HOME="$PWD/android-sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$PATH"

# 步骤2: 验证环境变量
echo "ANDROID_HOME: $ANDROID_HOME"
which emulator || echo "使用完整路径: $ANDROID_HOME/emulator/emulator"
```

**错误2: 跳过初始化直接编译**
```
Error: Error You must run `tauri android init` and add the `[android]` config to be able to use this command
```
**解决方案**: 必须先初始化Android项目
```bash
# 步骤1: 初始化 (仅首次需要)
npm run tauri android init

# 步骤2: 验证初始化成功
ls -la src-tauri/gen/android/
```

**错误3: 没有连接设备就编译**
```
Error: No Android devices found
Could not find a suitable device
```
**解决方案**: 必须先启动模拟器或连接设备
```bash
# 步骤1: 启动模拟器
$ANDROID_HOME/emulator/emulator -avd Alouette_Test &

# 步骤2: 等待设备连接
adb wait-for-device && adb devices

# 步骤3: 确认设备已连接后再编译
npm run tauri android dev
```

**错误4: Gradle Wrapper 下载失败或版本冲突**
```
Error: Could not download gradle-8.x.x-bin.zip
Error: Gradle wrapper did not finish downloading
```
**解决方案**: 配置使用本地Gradle工具
```bash
# 步骤1: 设置本地Gradle环境
export GRADLE_HOME="$PWD/gradle-8.14.2"
export PATH="$GRADLE_HOME/bin:$PATH"

# 步骤2: 验证本地Gradle
gradle --version

# 步骤3: 重新初始化（会使用本地Gradle）
npm run tauri android init

# 步骤4: 手动配置gradle wrapper（如果需要）
cd src-tauri/gen/android
gradle wrapper --gradle-version 8.14.2
```

**错误5: Gradle版本不兼容**
```
Error: Minimum supported Gradle version is X.X. Current version is Y.Y
```
**解决方案**: 确保Gradle版本匹配
```bash
# 检查项目要求的Gradle版本
cat src-tauri/gen/android/gradle/wrapper/gradle-wrapper.properties

# 使用匹配的本地Gradle版本
export GRADLE_HOME="$PWD/gradle-8.14.2"  # 确保版本匹配
export PATH="$GRADLE_HOME/bin:$PATH"

# 重新构建
npm run tauri android build --debug
```
### Common Issues by Platform

#### macOS Issues

**QEMU Panic Error**
```
Error: PANIC: Avd's CPU Architecture 'x86_64' is not supported by the QEMU2 emulator on aarch64 host
```
**Solution**: Use ARM64 system images only
```bash
# ✅ Correct for Apple Silicon
avdmanager create avd -k "system-images;android-34;google_apis_playstore;arm64-v8a"

# ❌ Wrong for Apple Silicon  
avdmanager create avd -k "system-images;android-34;google_apis_playstore;x86_64"
```

**OpenSSL Compilation Error**
```
Error: /bin/sh: aarch64-linux-android-ranlib: command not found
```
**Solution**: Create missing symlink
```bash
cd $NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin
ln -s llvm-ranlib aarch64-linux-android-ranlib
```

#### Linux Issues

**Emulator Command Not Found**
```
Error: 找不到命令 "emulator"，但可以通过以下软件包安装它：
sudo apt install google-android-emulator-installer
```
**Solution**: Use full path to emulator binary and set up environment correctly
```bash
# Step 1: Verify emulator exists in Android SDK
ls -la $ANDROID_HOME/emulator/emulator

# Step 2: Always use full path or ensure PATH is set
export ANDROID_HOME="$PWD/android-sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$PATH"

# Step 3: Use full path for reliable execution
$ANDROID_HOME/emulator/emulator -list-avds
$ANDROID_HOME/emulator/emulator -avd Alouette_Test [other-options]

# Step 4: Verify emulator is accessible
which emulator || echo "Use full path: $ANDROID_HOME/emulator/emulator"
```

**ADB Binary Detection**
```
Error: Could not automatically detect an ADB binary
```
**Solution**: Set proper permissions and PATH
```bash
chmod +x $ANDROID_HOME/platform-tools/adb
export PATH="$ANDROID_HOME/platform-tools:$PATH"
```

**Platform-tools Version Issue**
```
Symptom: adb version shows "minimal" without full functionality
```
**Solution**: Ensure complete platform-tools installation
```bash
# Check current adb version
adb version

# If output shows "minimal", reinstall platform-tools
cd $ANDROID_HOME
wget https://dl.google.com/android/repository/platform-tools-latest-linux.zip
rm -rf platform-tools
unzip platform-tools-latest-linux.zip
rm platform-tools-latest-linux.zip

# Verify installation
adb version  # Should show complete version (e.g., 35.0.2)
```

**Emulator Permission Denied**
```
Error: /dev/kvm permission denied
```
**Solution**: Add user to kvm group
```bash
sudo usermod -a -G kvm $USER
# Logout and login again
```

### Network Configuration

#### Ollima Server Setup

**For emulator testing**, Ollima must be accessible from the Android device:

```bash
# Start Ollima with network access
OLLIMA_HOST=0.0.0.0:11434 ollima serve

# Find your local IP
ip route get 1.1.1.1 | awk '{print $7; exit}'  # Linux
ifconfig | grep "inet " | grep -v 127.0.0.1     # macOS
```

**In Alouette app settings:**
- Server URL: `http://YOUR_LOCAL_IP:11434`
- Model: Select available model (e.g., `qwen2.5:1.5b`)

---

## Translation Feature Debugging

### Enhanced Error Handling (Fixed)

The translation functionality now includes comprehensive error handling:

#### Debug Logging
All translation attempts now generate detailed logs:

```
Android Debug - Starting translation process
Android Debug - Text: 'Hello world'
Android Debug - Target languages: ["Chinese"]
Android Debug - Provider: ollima
Android Debug - Server URL: http://192.168.1.100:11434
Android Debug - Model: qwen2.5:1.5b
```

#### Error Categories

1. **Network Errors**: Connection refused, timeouts
2. **Validation Errors**: Empty text, missing configuration
3. **Response Errors**: Empty responses, JSON parse failures
4. **Model Errors**: Model not found, insufficient resources

#### Monitoring Logs

**Android device logs:**
```bash
adb logcat | grep -E "(Android Debug|Alouette|RustStdoutStderr)"
```

**Expected successful output:**
```
Android Debug - Final translation result: '你好世界'
Android Debug - Successfully translated to Chinese: '你好世界'
Android Debug - Translation process completed successfully with 1 results
```

### Verification Steps

1. **Build latest version** with fixes
2. **Install to device/emulator**
3. **Configure Ollima connection** with local IP
4. **Test translation** with simple text
5. **Monitor logs** for detailed debugging information

---

## Build Environment Details

### Verified Configurations

#### macOS Apple Silicon
- **OS**: macOS Sonoma (M3)
- **NDK**: r28b  
- **API Level**: 34 (Android 14)
- **Target**: `aarch64-linux-android`
- **Emulator**: ARM64 system images

#### Linux x86_64
- **OS**: Ubuntu 20.04+
- **NDK**: r28b
- **API Level**: 34 (Android 14)  
- **Target**: `x86_64-linux-android`
- **Emulator**: x86_64 system images

### Performance Metrics
- **APK Size**: ~726MB (debug build)
- **Launch Time**: <3 seconds
- **Memory Usage**: 4-6GB during build
- **Build Time**: 10-15 minutes (first build)

---

**Last Updated**: June 17, 2025  
**Status**: All major issues resolved ✅
$ANDROID_HOME/emulator/emulator -avd Alouette_ARM64 -no-snapshot-save &

# 3. Wait for emulator to boot
adb wait-for-device

# 4. Navigate to your project and build
cd /path/to/your/alouette/project
npm run tauri android build

# 5. Install and run
adb install src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk
adb shell am start -n com.alouette.app/com.alouette.app.MainActivity
```

## ⚠️ Apple Silicon Mac Specific Requirements

**IMPORTANT**: On Apple Silicon Macs, you MUST use ARM64 system images for the Android emulator. x86_64 images will not work and will show a QEMU panic error.

**Correct system image**: `system-images;android-34;google_apis_playstore;arm64-v8a`  
**Incorrect**: `system-images;android-34;google_apis_playstore;x86_64` ❌

## Prerequisites

### For macOS

#### Option 1: Quick Setup with Pre-downloaded Files

If you have downloaded the following files到 `/Users/han/Downloads/`:

- `android-ndk-r28b-darwin.dmg`
- `platform-tools-latest-darwin.zip`

Run the automated setup:

```bash
# Create development directory
mkdir -p ~/zoo && cd ~/zoo

# Mount and extract NDK
hdiutil attach /Users/han/Downloads/android-ndk-r28b-darwin.dmg
cp -R "/Volumes/Android NDK r28b 1/AndroidNDK13356709.app/Contents/NDK/" ./android-ndk-r28b
hdiutil detach "/Volumes/Android NDK r28b 1"

# Extract Platform Tools
unzip /Users/han/Downloads/platform-tools-latest-darwin.zip

# Create Android SDK directory
mkdir -p android-sdk/cmdline-tools

# Download and setup Android SDK Command Line Tools
curl -o commandlinetools-mac.zip https://dl.google.com/android/repository/commandlinetools-mac-11076708_latest.zip
unzip commandlinetools-mac.zip -d android-sdk/cmdline-tools/
mv android-sdk/cmdline-tools/cmdline-tools android-sdk/cmdline-tools/latest

# Setup environment variables with NDK toolchain fixes
cat > android-env.sh << 'EOF'
#!/bin/bash
# Android Development Environment Setup for macOS (Apple Silicon)

export ANDROID_HOME="$HOME/zoo/android-sdk"
export ANDROID_SDK_ROOT="$HOME/zoo/android-sdk"
export NDK_HOME="$HOME/zoo/android-ndk-r28b"
export PATH="$HOME/zoo/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin:$PATH"

echo "Android Environment Variables Set:"
echo "ANDROID_HOME: $ANDROID_HOME"
echo "ANDROID_SDK_ROOT: $ANDROID_SDK_ROOT"
echo "NDK_HOME: $NDK_HOME"
echo "PATH updated with Android tools and NDK toolchain"
EOF

chmod +x android-env.sh
source android-env.sh

# Fix missing ranlib tool for OpenSSL compilation
cd $NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin/
ln -sf llvm-ranlib aarch64-linux-android-ranlib
ln -sf llvm-ar aarch64-linux-android-ar
ln -sf llvm-strip aarch64-linux-android-strip

# Install required Android SDK components (ARM64 for Apple Silicon)
yes | sdkmanager --licenses
sdkmanager "platforms;android-34" "build-tools;34.0.0" "emulator" "system-images;android-34;google_apis_playstore;arm64-v8a"

# Create ARM64 Android Virtual Device (compatible with Apple Silicon)
avdmanager create avd -n "Alouette_ARM64" -k "system-images;android-34;google_apis_playstore;arm64-v8a" -d "pixel_7"
```

#### Option 2: Manual Installation

Install essential build tools and Java development kit:

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install openjdk@21 wget unzip curl

# Add Java to PATH
echo 'export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"' >> ~/.zshrc
echo 'export JAVA_HOME="/opt/homebrew/opt/openjdk@21"' >> ~/.zshrc
source ~/.zshrc
```

### For Linux

Install essential build tools and Java development kit:

```bash
sudo apt update && sudo apt install -y \
  clang llvm build-essential \
  openjdk-21-jdk \
  wget unzip curl
```

### Add Rust Android Targets

Add Android targets for Rust compilation:

```bash
rustup target add \
  aarch64-linux-android \
  armv7-linux-androideabi \
  i686-linux-android \
  x86_64-linux-android

rustup target list --installed | grep android
```

### Initialize Tauri Android Project

Set up the Android project structure:

```bash
# Navigate to your Alouette project
cd /path/to/your/alouette/project

# Initialize Android support (if not already done)
npx @tauri-apps/cli android init

# Install dependencies
npm install
```

## Building the Application

### Build for Android

#### 📱 Debug vs Release Build Guide

**Important Note**: For daily development and verification, we **only use debug builds**, unless deploying to app stores.

#### 🔧 Debug Build (Recommended for Development)

Debug APKs have the following characteristics:
- ✅ **Auto-signed** - Uses debug certificate, can be installed directly
- ✅ **Fast build** - Shorter compilation time
- ✅ **Development tools** - Includes debug info and logging
- ✅ **Hot reload** - Supports live updates in development mode
- ❌ **Larger file** - Includes debug symbols, APK ~726MB

```bash
# Build debug APK (recommended)
npm run dev:android

# Or manually build debug version
npm run build:android
```

**Output path**: `src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk`

#### 🚀 Release Build (Production Only)

Release APKs have the following characteristics:
- ❌ **Requires signing** - Generates unsigned APK, cannot be installed directly
- ⚡ **Optimized build** - Code optimization, better performance
- 📦 **Smaller file** - Debug info removed, APK ~120MB
- 🔒 **Production ready** - Suitable for app store deployment

```bash
# Build release APK (requires subsequent signing)
npm run build:android -- --release

# Build AAB bundle (Google Play Store)
npm run build:android -- --bundle aab
```

**Output path**: `src-tauri/gen/android/app/build/outputs/apk/universal/release/app-universal-release-unsigned.apk`

#### 🛠️ Verification and Testing Workflow

```bash
# 1. Environment setup (once per session)
cd ~/zoo && source android-env.sh  # macOS
# or
export ANDROID_HOME="$PWD/android-sdk" && export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$PATH"  # Linux

# 2. Start emulator (if not running)
adb devices
# If no device, start emulator
$ANDROID_HOME/emulator/emulator -avd Alouette_Test -memory 4096 -cores 2 -gpu auto &

# 3. Build and install debug version (recommended)
cd /path/to/your/alouette/project
npm run dev:android

# 4. Manual debug installation (if needed)
adb install -r src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk

# 5. Launch application
adb shell am start -n com.alouette.app/com.alouette.app.MainActivity

# 6. View logs
adb logcat | grep -E "(alouette|Alouette|RustStdoutStderr)"
```

### 步骤1: 配置环境变量 (必须首先执行)

**For macOS:**
```bash
cd ~/zoo && source android-env.sh
```

**For Linux:**
```bash
cd /path/to/alouette
export ANDROID_HOME="$PWD/android-sdk"
export GRADLE_HOME="$PWD/gradle-8.14.2"  # 使用项目本地Gradle
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$GRADLE_HOME/bin:$PATH"

# 验证环境变量
echo "ANDROID_HOME: $ANDROID_HOME"
echo "GRADLE_HOME: $GRADLE_HOME"
echo "PATH contains emulator: $(echo $PATH | grep emulator)"
echo "PATH contains gradle: $(echo $PATH | grep gradle)"

# 验证工具版本
gradle --version  # 应该显示8.14.2
adb --version
```

### 步骤2: 初始化Android项目 (首次运行必须)

```bash
# 导航到项目目录
cd /path/to/your/alouette/project

# 初始化Tauri Android项目 (仅首次需要)
npm run tauri android init

# 验证初始化结果
ls -la src-tauri/gen/android/
```

#### 配置本地Gradle工具 (可选)

如果你想使用本地的Gradle工具而不是Gradle Wrapper (gradlew)，可以进行以下配置：

**方法1: 环境变量配置**
```bash
# 设置GRADLE_HOME指向本地Gradle安装目录
export GRADLE_HOME="/path/to/your/gradle-8.14.2"
export PATH="$GRADLE_HOME/bin:$PATH"

# 验证Gradle版本
gradle --version
```

**方法2: 修改tauri.conf.json配置**
在 `src-tauri/tauri.conf.json` 中添加Android配置：

```json
{
  // ...existing config...
  "android": {
    "gradle": {
      "useWrapper": false,
      "gradlePath": "/path/to/your/gradle-8.14.2/bin/gradle"
    },
    "minSdkVersion": 24,
    "compileSdkVersion": 34,
    "targetSdkVersion": 34
  }
}
```

**方法3: 项目本地Gradle配置**
```bash
# 在项目中使用本地Gradle
export GRADLE_HOME="$PWD/gradle-8.14.2"
export PATH="$GRADLE_HOME/bin:$PATH"

# 初始化时Tauri会自动检测到本地Gradle
npm run tauri android init

# 验证配置
cd src-tauri/gen/android
gradle wrapper --gradle-version 8.14.2
```

**方法4: 禁用Wrapper的gradle.properties配置**
在 `src-tauri/gen/android/gradle.properties` 中添加：
```properties
# 使用本地Gradle而不是Wrapper
org.gradle.java.home=/usr/lib/jvm/java-21-openjdk-amd64
android.useAndroidX=true
android.enableJetifier=true
```

#### 验证本地Gradle配置

```bash
# 检查Gradle配置
cd src-tauri/gen/android

# 方式1: 使用本地gradle命令
gradle -v

# 方式2: 检查gradle wrapper配置
cat gradle/wrapper/gradle-wrapper.properties

# 方式3: 检查构建是否使用本地gradle
gradle clean assembleDebug --info | grep "Gradle version"
```

#### Linux系统推荐配置

对于Linux系统，推荐使用项目本地的Gradle：

```bash
# 设置本地Gradle环境
export GRADLE_HOME="$PWD/gradle-8.14.2" 
export PATH="$GRADLE_HOME/bin:$PATH"

# 初始化Android项目
npm run tauri android init

# 验证使用本地Gradle
cd src-tauri/gen/android
gradle --version  # 应该显示8.14.2版本
```
### 步骤3: 启动Android模拟器

**For macOS:**
```bash
# 检查可用AVD
$ANDROID_HOME/emulator/emulator -list-avds

# 启动模拟器 (ARM64 for Apple Silicon)
$ANDROID_HOME/emulator/emulator -avd Alouette_ARM64 -memory 4096 -cores 4 -gpu auto -no-snapshot-save &

# 等待设备连接
adb wait-for-device && adb devices
```

**For Linux:**
```bash
# 检查可用AVD
$ANDROID_HOME/emulator/emulator -list-avds

# 启动模拟器 (平衡内存设置支持Ollama模型)
$ANDROID_HOME/emulator/emulator -avd Alouette_Test -memory 2048 -partition-size 4096 -cores 2 -gpu swiftshader_indirect -no-boot-anim -no-snapshot-save -no-audio &

# 等待设备连接
sleep 30 && adb wait-for-device && adb devices
```

### 步骤4: 编译应用

```bash
# 方式1: 开发模式 (推荐 - 自动编译+安装+热重载)
npm run tauri android dev

# 方式2: 手动构建
npm run tauri android build --debug

# 方式3: 使用package.json中的脚本
npm run build:android
```

### 步骤5: 部署到设备

```bash
# 如果使用开发模式，应用会自动安装
# 手动安装(如果需要)
adb install -r src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk

# 启动应用
adb shell am start -n com.alouette.app/com.alouette.app.MainActivity

# 查看应用日志
adb logcat | grep -i alouette
```

### 快速开发模式 (一键启动)

```bash
# 确保环境变量已设置且模拟器已启动，然后：
npm run tauri android dev

# 此命令会自动：
# 1. 构建Rust后端
# 2. 构建Vue前端  
# 3. 安装应用到连接的设备/模拟器
# 4. 启用前端代码热重载
```

---

## Troubleshooting

### 执行顺序相关问题

#### 跳过环境变量配置导致的错误

**错误1: emulator命令未找到**
```
Error: 找不到命令 "emulator"
bash: emulator: command not found
```
**解决方案**: 必须先配置环境变量
```bash
# 步骤1: 设置环境变量 (必须首先执行)
export ANDROID_HOME="$PWD/android-sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$PATH"

# 步骤2: 验证环境变量
echo "ANDROID_HOME: $ANDROID_HOME"
which emulator || echo "使用完整路径: $ANDROID_HOME/emulator/emulator"
```

**错误2: 跳过初始化直接编译**
```
Error: Error You must run `tauri android init` and add the `[android]` config to be able to use this command
```
**解决方案**: 必须先初始化Android项目
```bash
# 步骤1: 初始化 (仅首次需要)
npm run tauri android init

# 步骤2: 验证初始化成功
ls -la src-tauri/gen/android/
```

**错误3: 没有连接设备就编译**
```
Error: No Android devices found
Could not find a suitable device
```
**解决方案**: 必须先启动模拟器或连接设备
```bash
# 步骤1: 启动模拟器
$ANDROID_HOME/emulator/emulator -avd Alouette_Test &

# 步骤2: 等待设备连接
adb wait-for-device && adb devices

# 步骤3: 确认设备已连接后再编译
npm run tauri android dev
```

**错误4: Gradle Wrapper 下载失败或版本冲突**
```
Error: Could not download gradle-8.x.x-bin.zip
Error: Gradle wrapper did not finish downloading
```
**解决方案**: 配置使用本地Gradle工具
```bash
# 步骤1: 设置本地Gradle环境
export GRADLE_HOME="$PWD/gradle-8.14.2"
export PATH="$GRADLE_HOME/bin:$PATH"

# 步骤2: 验证本地Gradle
gradle --version

# 步骤3: 重新初始化（会使用本地Gradle）
npm run tauri android init

# 步骤4: 手动配置gradle wrapper（如果需要）
cd src-tauri/gen/android
gradle wrapper --gradle-version 8.14.2
```

**错误5: Gradle版本不兼容**
```
Error: Minimum supported Gradle version is X.X. Current version is Y.Y
```
**解决方案**: 确保Gradle版本匹配
```bash
# 检查项目要求的Gradle版本
cat src-tauri/gen/android/gradle/wrapper/gradle-wrapper.properties

# 使用匹配的本地Gradle版本
export GRADLE_HOME="$PWD/gradle-8.14.2"  # 确保版本匹配
export PATH="$GRADLE_HOME/bin:$PATH"

# 重新构建
npm run tauri android build --debug
```
### Common Issues by Platform

#### macOS Issues

**QEMU Panic Error**
```
Error: PANIC: Avd's CPU Architecture 'x86_64' is not supported by the QEMU2 emulator on aarch64 host
```
**Solution**: Use ARM64 system images only
```bash
# ✅ Correct for Apple Silicon
avdmanager create avd -k "system-images;android-34;google_apis_playstore;arm64-v8a"

# ❌ Wrong for Apple Silicon  
avdmanager create avd -k "system-images;android-34;google_apis_playstore;x86_64"
```

**OpenSSL Compilation Error**
```
Error: /bin/sh: aarch64-linux-android-ranlib: command not found
```
**Solution**: Create missing symlink
```bash
cd $NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin
ln -s llvm-ranlib aarch64-linux-android-ranlib
```

#### Linux Issues

**Emulator Command Not Found**
```
Error: 找不到命令 "emulator"，但可以通过以下软件包安装它：
sudo apt install google-android-emulator-installer
```
**Solution**: Use full path to emulator binary and set up environment correctly
```bash
# Step 1: Verify emulator exists in Android SDK
ls -la $ANDROID_HOME/emulator/emulator

# Step 2: Always use full path or ensure PATH is set
export ANDROID_HOME="$PWD/android-sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$PATH"

# Step 3: Use full path for reliable execution
$ANDROID_HOME/emulator/emulator -list-avds
$ANDROID_HOME/emulator/emulator -avd Alouette_Test [other-options]

# Step 4: Verify emulator is accessible
which emulator || echo "Use full path: $ANDROID_HOME/emulator/emulator"
```

**ADB Binary Detection**
```
Error: Could not automatically detect an ADB binary
```
**Solution**: Set proper permissions and PATH
```bash
chmod +x $ANDROID_HOME/platform-tools/adb
export PATH="$ANDROID_HOME/platform-tools:$PATH"
```

**Platform-tools Version Issue**
```
Symptom: adb version shows "minimal" without full functionality
```
**Solution**: Ensure complete platform-tools installation
```bash
# Check current adb version
adb version

# If output shows "minimal", reinstall platform-tools
cd $ANDROID_HOME
wget https://dl.google.com/android/repository/platform-tools-latest-linux.zip
rm -rf platform-tools
unzip platform-tools-latest-linux.zip
rm platform-tools-latest-linux.zip

# Verify installation
adb version  # Should show complete version (e.g., 35.0.2)
```

**Emulator Permission Denied**
```
Error: /dev/kvm permission denied
```
**Solution**: Add user to kvm group
```bash
sudo usermod -a -G kvm $USER
# Logout and login again
```

### Network Configuration

#### Ollama Server Setup

**For emulator testing**, Ollama must be accessible from the Android device:

```bash
# Start Ollama with network access
OLLAMA_HOST=0.0.0.0:11434 ollama serve

# Find your local IP
ip route get 1.1.1.1 | awk '{print $7; exit}'  # Linux
ifconfig | grep "inet " | grep -v 127.0.0.1     # macOS
```

**In Alouette app settings:**
- Server URL: `http://YOUR_LOCAL_IP:11434`
- Model: Select available model (e.g., `qwen2.5:1.5b`)

---

## Translation Feature Debugging

### Enhanced Error Handling (Fixed)

The translation functionality now includes comprehensive error handling:

#### Debug Logging
All translation attempts now generate detailed logs:

```
Android Debug - Starting translation process
Android Debug - Text: 'Hello world'
Android Debug - Target languages: ["Chinese"]
Android Debug - Provider: ollima
Android Debug - Server URL: http://192.168.1.100:11434
Android Debug - Model: qwen2.5:1.5b
```

#### Error Categories

1. **Network Errors**: Connection refused, timeouts
2. **Validation Errors**: Empty text, missing configuration
3. **Response Errors**: Empty responses, JSON parse failures
4. **Model Errors**: Model not found, insufficient resources

#### Monitoring Logs

**Android device logs:**
```bash
adb logcat | grep -E "(Android Debug|Alouette|RustStdoutStderr)"
```

**Expected successful output:**
```
Android Debug - Final translation result: '你好世界'
Android Debug - Successfully translated to Chinese: '你好世界'
Android Debug - Translation process completed successfully with 1 results
```

### Verification Steps

1. **Build latest version** with fixes
2. **Install to device/emulator**
3. **Configure Ollama connection** with local IP
4. **Test translation** with simple text
5. **Monitor logs** for detailed debugging information

---

## Build Environment Details

### Verified Configurations

#### macOS Apple Silicon
- **OS**: macOS Sonoma (M3)
- **NDK**: r28b  
- **API Level**: 34 (Android 14)
- **Target**: `aarch64-linux-android`
- **Emulator**: ARM64 system images

#### Linux x86_64
- **OS**: Ubuntu 20.04+
- **NDK**: r28b
- **API Level**: 34 (Android 14)  
- **Target**: `x86_64-linux-android`
- **Emulator**: x86_64 system images

### Performance Metrics
- **APK Size**: ~726MB (debug build)
- **Launch Time**: <3 seconds
- **Memory Usage**: 4-6GB during build
- **Build Time**: 10-15 minutes (first build)

---

**Last Updated**: June 17, 2025  
**Status**: All major issues resolved ✅
$ANDROID_HOME/emulator/emulator -avd Alouette_ARM64 -no-snapshot-save &

# 3. Wait for emulator to boot
adb wait-for-device

# 4. Navigate to your project and build
cd /path/to/your/alouette/project
npm run tauri android build

# 5. Install and run
adb install src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk
adb shell am start -n com.alouette.app/com.alouette.app.MainActivity
```

## ⚠️ Apple Silicon Mac Specific Requirements

**IMPORTANT**: On Apple Silicon Macs, you MUST use ARM64 system images for the Android emulator. x86_64 images will not work and will show a QEMU panic error.

**Correct system image**: `system-images;android-34;google_apis_playstore;arm64-v8a`  
**Incorrect**: `system-images;android-34;google_apis_playstore;x86_64` ❌

## Prerequisites

### For macOS

#### Option 1: Quick Setup with Pre-downloaded Files

If you have downloaded the following files到 `/Users/han/Downloads/`:

- `android-ndk-r28b-darwin.dmg`
- `platform-tools-latest-darwin.zip`

Run the automated setup:

```bash
# Create development directory
mkdir -p ~/zoo && cd ~/zoo

# Mount and extract NDK
hdiutil attach /Users/han/Downloads/android-ndk-r28b-darwin.dmg
cp -R "/Volumes/Android NDK r28b 1/AndroidNDK13356709.app/Contents/NDK/" ./android-ndk-r28b
hdiutil detach "/Volumes/Android NDK r28b 1"

# Extract Platform Tools
unzip /Users/han/Downloads/platform-tools-latest-darwin.zip

# Create Android SDK directory
mkdir -p android-sdk/cmdline-tools

# Download and setup Android SDK Command Line Tools
curl -o commandlinetools-mac.zip https://dl.google.com/android/repository/commandlinetools-mac-11076708_latest.zip
unzip commandlinetools-mac.zip -d android-sdk/cmdline-tools/
mv android-sdk/cmdline-tools/cmdline-tools android-sdk/cmdline-tools/latest

# Setup environment variables with NDK toolchain fixes
cat > android-env.sh << 'EOF'
#!/bin/bash
# Android Development Environment Setup for macOS (Apple Silicon)

export ANDROID_HOME="$HOME/zoo/android-sdk"
export ANDROID_SDK_ROOT="$HOME/zoo/android-sdk"
export NDK_HOME="$HOME/zoo

---

## 🧹 Code Maintenance Log

### December 2024 - TTSEngine Dead Code Cleanup ✅

**Task**: Remove all dead code warnings from TTSEngine module  
**Status**: **COMPLETED** - Zero compilation warnings

#### Cleaned Functions Removed:
- Cache management functions (ensure_cache_dir, generate_cache_key, etc.)
- Voice selection utilities (select_voice_for_language)
- Text processing functions (detect_text_script, safe_truncate, etc.)
- Audio file validation utilities  
- Unused TTS engine integrations (Edge TTS, local TTS)

#### Result:
- **Clean build**: No dead code warnings for Android target
- **Code reduced**: Removed 200+ lines of unused functions
- **Maintained functionality**: All active TTS features preserved
- **Better maintainability**: Clean separation of Android/non-Android code

```bash
# Verification: Clean compilation
cd src-tauri && cargo build --target aarch64-linux-android
# Result: Zero warnings, clean build output
```


# Android Build Guide for Alouette

A comprehensive guide for building and deploying the Alouette AI translation application on Android devices across different platforms.

> **🔧 Development Note**: For daily verification and development, use **debug builds** (`npm run dev:android`). Release builds are only for production deployment.
> 
> **Quick Verification**: `npm run dev:android` → Auto build+install+hot reload
>
> **⚠️ Linux Users**: If you see "emulator command not found", use the full path: `$ANDROID_HOME/emulator/emulator` instead of just `emulator`. See [Troubleshooting](#troubleshooting) for details.
>
> **⚠️ Memory Warning**: DO NOT allocate more than 2GB memory to the emulator on Linux systems. Using 4GB+ can cause system crashes and VS Code OOM-kill. **Recommended: 1.5-2GB for stable operation**.
>
> **🚨 Critical**: If emulator crashes repeatedly, reduce to 1GB memory and disable hardware acceleration with `-gpu swiftshader_indirect`.

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

### ✅ Current Status (June 17, 2025)

**Translation functionality**: **FIXED** ✅  
**Build status**: Verified working on both macOS and Linux  
**Target platforms**: Android 14 (API 34), ARM64 and x86_64  
**Verification strategy**: **Debug builds first** - Use debug builds for daily development

#### Key Achievements
- ✅ **Translation errors resolved** - Fixed "undefined" error issues
- ✅ **Cross-platform builds** - Working on macOS Apple Silicon and Linux
- ✅ **Network connectivity** - Ollama integration verified
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
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$PATH"

# Verify ADB and emulator are accessible
adb --version
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

### 1. Environment Preparation

**For macOS:**
```bash
cd ~/zoo && source android-env.sh
```

**For Linux:**
```bash
cd /path/to/alouette && export ANDROID_HOME="$PWD/android-sdk" && export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$PATH"
```

### 2. Emulator Startup

**Single Command for macOS:**
```bash
# Ensure environment is set up first
export ANDROID_HOME="$PWD/android-sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$PATH"
$ANDROID_HOME/emulator/emulator -avd Alouette_ARM64 -memory 4096 -cores 4 -gpu auto -no-snapshot-save & adb wait-for-device
```

**Single Command for Linux:**
```bash
# Ensure environment is set up first
export ANDROID_HOME="$PWD/android-sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$PATH"
$ANDROID_HOME/emulator/emulator -avd Alouette_Test -memory 4096 -partition-size 6144 -cores 2 -gpu auto -no-boot-anim -no-snapshot-save & sleep 10 && adb wait-for-device
```

### 3. Build and Deploy (Debug Version)

```bash
# Navigate to project directory
cd /path/to/your/alouette/project

# Recommended: One-click development mode (build+install+hot reload)
npm run dev:android

# Or: Manual debug APK build
npm run build:android

# Install to device/emulator
adb install -r src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk

# Launch application
adb shell am start -n com.alouette.app/com.alouette.app.MainActivity
```

### 4. Development Mode (Recommended)

```bash
# Live development with hot reload
npm run dev:android

# This command automatically:
# 1. Builds Rust backend
# 2. Builds Vue frontend  
# 3. Installs app to connected device/emulator
# 4. Enables hot reload for frontend code
```

---

## Troubleshooting

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
Android Debug - Provider: ollama
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

If you have downloaded the following files to `/Users/han/Downloads/`:

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
export ANDROID_HOME="$PWD/android-sdk" && export PATH="$ANDROID_HOME/platform-tools:$PATH"  # Linux

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

#### 📋 Quick Command Reference

```bash
# 🔧 Development verification - One-click build+install+launch (recommended)
npm run dev:android

# 🔧 Manual debug build
npm run build:android

# 🚀 Release build (production environment)
npm run build:android -- --release

# 📦 Google Play Bundle
npm run build:android -- --bundle aab

# 🔄 Reinstall app
adb install -r src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk

# 🚀 Quick restart app
adb shell am force-stop com.alouette.app && adb shell am start -n com.alouette.app/com.alouette.app.MainActivity
```

### Development Workflow

```bash
# Start development server with hot reload
npm run tauri android dev

# This will:
# 1. Build the Rust backend
# 2. Build the frontend
# 3. Install the app on connected device/emulator
# 4. Enable hot reload for frontend changes
```

### Common Development Workflow

Here's a typical development workflow for Alouette Android development:

```bash
# 1. Set up environment (once per session)
cd ~/zoo && source android-env.sh  # macOS
# OR
export ANDROID_HOME="$PWD/android-sdk" && export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$PATH"  # Linux

# 2. Check emulator status
adb devices

# 3. Start emulator if not running
if ! adb devices | grep -q emulator; then
    echo "Starting emulator..."
    $ANDROID_HOME/emulator/emulator -avd Alouette_Test \
        -no-snapshot-save \
        -memory 4096 \
        -partition-size 8192 \
        -no-boot-anim \
        -gpu auto &
    adb wait-for-device
fi

# 4. Navigate to project and build
cd /path/to/your/alouette/project
npm run tauri android build

# 5. Install and run
adb install -r src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk
adb shell am start -n com.alouette.app/com.alouette.app.MainActivity

# 6. Monitor logs
adb logcat | grep -E "(alouette|Alouette|RustStdoutStderr)"
```

### One-liner Commands for Quick Testing

```bash
# Quick reinstall and launch
adb install -r src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk && adb shell am start -n com.alouette.app/com.alouette.app.MainActivity

# Force stop and restart app
adb shell am force-stop com.alouette.app && adb shell am start -n com.alouette.app/com.alouette.app.MainActivity

# Check if app is running
adb shell ps | grep alouette

# Get app version
adb shell dumpsys package com.alouette.app | grep versionName
```

---

## Android Feature Verification Process

### 🎯 Quick Verification Checklist (Debug Build Priority)

When verifying Android functionality, **only use debug builds** and follow these steps:

#### 1. Environment Check

```bash
# Check Android environment
echo "Android SDK: $ANDROID_HOME"
echo "ADB Version:"
adb --version

# Check device connection
adb devices
```

#### 2. Emulator Management

```bash
# List available AVDs
$ANDROID_HOME/emulator/emulator -list-avds

# Start emulator (if not running)
$ANDROID_HOME/emulator/emulator -avd Alouette_Test -memory 4096 -cores 2 -gpu auto &

# Wait for device ready
adb wait-for-device && echo "Device connected"
```

#### 3. Build and Install Debug Version

```bash
# Enter project directory
cd /home/hanl5/coding/alouette  # or your project path

# Method 1: Recommended - Development mode (auto build+install+hot reload)
npm run dev:android

# Method 2: Manual debug build
npm run build:android
adb install -r src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk
```

#### 4. Feature Verification Checkpoints

```bash
# Launch application
adb shell am start -n com.alouette.app/com.alouette.app.MainActivity

# View application logs
adb logcat | grep -E "(alouette|Alouette|RustStdoutStderr)"

# Check application status
adb shell ps | grep alouette

# Verify functionality:
# ✅ Application starts normally
# ✅ UI interface displays completely
# ✅ Translation feature available
# ✅ Network connection normal (Ollama)
# ✅ Audio playback functionality
```

#### 5. Troubleshooting Commands

```bash
# Restart app when crashed
adb shell am force-stop com.alouette.app
adb shell am start -n com.alouette.app/com.alouette.app.MainActivity

# Reinstall application
adb uninstall com.alouette.app
adb install src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk

# View device information
adb shell getprop ro.build.version.release  # Android version
adb shell getprop ro.product.cpu.abi        # CPU architecture
adb shell df /data                          # Storage space
```

### ⚠️ Important Notes

- ✅ **Prioritize debug builds** - Auto-signed, can be installed directly
- ❌ **Avoid release builds** - Unsigned, cannot be installed directly, only for production
- 🔄 **Use `npm run dev:android`** - Fastest verification method
- 📱 **Verify core functions** - Translation, TTS, network connection
- 🐛 **Keep logs** - Use `adb logcat` to monitor issues

---

## Environment Configuration

### For macOS (Using ~/zoo setup)

Load the Android environment:

```bash
# Navigate to your zoo directory
cd ~/zoo

# Load environment variables
source android-env.sh

# Verify environment
echo "ANDROID_HOME: $ANDROID_HOME"
echo "NDK_HOME: $NDK_HOME"
echo "Java: $(java -version 2>&1 | head -1)"
```

### For Linux

Configure environment variables for Android development:

```bash
export ANDROID_HOME="$PWD/android-sdk"
export NDK_HOME="$ANDROID_HOME/ndk/android-ndk-r28b"
export GRADLE_HOME="$PWD/gradle-8.14.2"
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"

export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$NDK_HOME:$GRADLE_HOME/bin:$PATH"

echo "Android SDK: $ANDROID_HOME"
echo "NDK: $NDK_HOME"
echo "Gradle: $GRADLE_HOME"
echo "Java: $JAVA_HOME"
```

## Supported Target Architectures

| Architecture              | Target Platform | Usage                               |
| ------------------------- | --------------- | ----------------------------------- |
| `aarch64-linux-android`   | ARM64           | Modern Android devices (mainstream) |
| `armv7-linux-androideabi` | ARM32           | Legacy Android devices              |
| `i686-linux-android`      | x86             | Android emulator                    |
| `x86_64-linux-android`    | x86_64          | High-performance emulator/devices   |

## Build Output

After successful build, you will get the following files:

### APK Files (for development/testing)

```
src-tauri/gen/android/app/build/outputs/apk/universal/release/
├── app-universal-release-unsigned.apk  # Unsigned APK
└── output-metadata.json                # Build metadata
```

### AAB Files (for Google Play Store)

```
src-tauri/gen/android/app/build/outputs/bundle/universalRelease/
└── app-universal-release.aab           # Play Store package
```

## Testing and Deployment

### Setting up Android Emulator

#### For macOS (~/zoo setup)

Create and start an Android Virtual Device (AVD):

```bash
# Load environment first
cd ~/zoo && source android-env.sh

# Create AVD (Android Virtual Device) - if not already created
avdmanager create avd \
  -n "Alouette_Test" \
  -k "system-images;android-34;google_apis_playstore;x86_64" \
  -d "pixel_7"

# Start emulator with optimized memory settings
$ANDROID_HOME/emulator/emulator -avd Alouette_Test \
  -no-snapshot-save \
  -memory 4096 \
  -partition-size 8192 \
  -no-boot-anim \
  -gpu auto &

# Wait for device to be ready
adb wait-for-device

# Verify device is connected
adb devices
```

#### For Linux

Create and start an Android Virtual Device (AVD):

```bash
# Set up environment variables first
export ANDROID_HOME="$PWD/android-sdk"
export NDK_HOME="$ANDROID_HOME/ndk/android-ndk-r28b"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$PATH"

# Create AVD (Android Virtual Device)
avdmanager create avd \
  -n "Alouette_Test" \
  -k "system-images;android-34;google_apis_playstore;x86_64" \
  -d "pixel_7"

# Start emulator with optimized settings for better performance
$ANDROID_HOME/emulator/emulator -avd Alouette_Test \
  -no-snapshot-save \
  -memory 4096 \
  -partition-size 8192 \
  -no-boot-anim \
  -gpu auto &

# Wait for device to be ready
adb wait-for-device
```

### Installing the Application

Install and run the application on emulator:

```bash
# Make sure environment is loaded (for macOS)
cd ~/zoo && source android-env.sh

# Navigate to your Alouette project
cd /path/to/your/alouette/project

# Build the Android APK
npm run tauri android build

# Install debug APK (use -r flag for reinstall/update)
adb install -r src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk

# Launch application
adb shell am start -n com.alouette.app/com.alouette.app.MainActivity

# View application logs in real-time
adb logcat | grep -E "(alouette|Alouette|RustStdoutStderr)"
```

### Quick Installation Script

For faster development workflow, create this installation script:

```bash
#!/bin/bash
# save as install-alouette.sh

# Load environment (macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    cd ~/zoo && source android-env.sh
fi

# Navigate to project (update this path)
cd /path/to/your/alouette/project

# Build and install
echo "Building Alouette for Android..."
npm run tauri android build

if [ $? -eq 0 ]; then
    echo "Installing APK..."
    adb install -r src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk
    
    echo "Launching application..."
    adb shell am start -n com.alouette.app/com.alouette.app.MainActivity
    
    echo "Showing logs (Ctrl+C to stop)..."
    adb logcat | grep -E "(alouette|Alouette|RustStdoutStderr)"
else
    echo "Build failed!"
    exit 1
fi
```

Make it executable:
```bash
chmod +x install-alouette.sh
./install-alouette.sh
```

### Installing on Physical Device

To install on a real Android device:

```bash
# After enabling Developer Mode and USB Debugging
adb devices

# Install APK
adb install src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk

# List installed packages
adb shell pm list packages | grep alouette
```

## Monitoring and Debugging

### Real-time Application Monitoring

Monitor application performance and logs:

```bash
# Monitor application logs in real-time
adb logcat | grep -E "(alouette|Alouette|RustStdoutStderr)"

# Monitor with specific tags
adb logcat -s "AlouetteApp"

# Clear log buffer and monitor fresh logs
adb logcat -c && adb logcat | grep -E "(alouette|Alouette)"

# Monitor application performance
adb shell top | grep alouette

# Check memory usage
adb shell dumpsys meminfo com.alouette.app

# Check CPU usage
adb shell dumpsys cpuinfo | grep alouette

# Monitor network connections
adb shell netstat | grep 11434  # Check Ollama connections
```

### Debugging Commands

```bash
# Get detailed application information
adb shell dumpsys package com.alouette.app

# Check application permissions
adb shell dumpsys package com.alouette.app | grep permission

# Monitor file system access
adb shell strace -p $(adb shell pidof com.alouette.app) 2>&1 | grep -E "(open|read|write)"

# Check application crashes
adb logcat -b crash

# Debug native crashes
adb logcat -b main -b system -b crash | grep -E "(FATAL|AndroidRuntime|DEBUG)"
```

### Network Debugging for Ollama Connection

```bash
# Test network connectivity from emulator to host
adb shell ping -c 3 192.168.31.228  # Replace with your host IP

# Test Ollama API from emulator
adb shell "echo 'GET /api/tags HTTP/1.1\r\nHost: 192.168.31.228:11434\r\n\r\n' | nc 192.168.31.228 11434"

# Check if port 11434 is accessible
adb shell nc -zv 192.168.31.228 11434

# Monitor HTTP requests from the app
adb logcat | grep -E "(http|HTTP|curl|request|response)"
```

## Environment Verification

### For macOS

Verify your development environment setup:

```bash
# Load environment
cd ~/zoo && source android-env.sh

# Complete environment check
echo "=== Environment Verification ==="
echo "Node.js: $(node --version)"
echo "Rust: $(rustc --version)"
echo "Java: $(java -version 2>&1 | head -1)"
echo "Android SDK: $ANDROID_HOME"
echo "NDK: $NDK_HOME"

echo "=== Android Target Architectures ==="
rustup target list --installed | grep android

echo "=== Tool Availability ==="
command -v adb && echo "✅ ADB available" || echo "❌ ADB not available"
command -v sdkmanager && echo "✅ SDK Manager available" || echo "❌ SDK Manager not available"
command -v avdmanager && echo "✅ AVD Manager available" || echo "❌ AVD Manager not available"
command -v emulator && echo "✅ Emulator available" || echo "❌ Emulator not available"
```

### For Linux

Verify your development environment setup:

```bash
# Complete environment check
echo "=== Environment Verification ==="
echo "Node.js: $(node --version)"
echo "Rust: $(rustc --version)"
echo "Java: $(java -version 2>&1 | head -1)"
echo "Gradle: $(gradle --version | head -1)"
echo "Android SDK: $ANDROID_HOME"
echo "NDK: $NDK_HOME"

echo "=== Android Target Architectures ==="
rustup target list --installed | grep android

echo "=== Tool Availability ==="
command -v adb && echo "✅ ADB available" || echo "❌ ADB not available"
command -v gradle && echo "✅ Gradle available" || echo "❌ Gradle not available"
```

## Troubleshooting

Common issues and solutions:

### macOS Specific Issues

1. **Permission denied on DMG mounting**:

   ```bash
   # Allow unsigned applications in System Preferences > Security & Privacy
   sudo spctl --master-disable
   ```

2. **Emulator fails to start**:

   ```bash
   # Check if HAXM is installed (Intel Macs) or enable hardware acceleration
   # For Apple Silicon Macs, ensure you're using arm64 system images
   ```

3. **Environment variables not persisting**:
   ```bash
   # Add to your shell profile
   echo 'source ~/zoo/android-env.sh' >> ~/.zshrc
   ```

### Linux Specific Issues

1. **ADB binary not detected popup in emulator**:
   ```bash
   # Issue: Emulator can't automatically find ADB binary
   # Solution: Manually start ADB server with full path
   cd /path/to/your/project
   export ANDROID_HOME="$PWD/android-sdk"
   export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$PATH"
   $ANDROID_HOME/platform-tools/adb start-server
   $ANDROID_HOME/platform-tools/adb devices  # Verify connection
   ```

2. **Emulator startup with safe memory allocation**:
   ```bash
   # Use balanced memory settings to prevent system crashes
   $ANDROID_HOME/emulator/emulator -avd Alouette_Test -no-snapshot-save -memory 4096 -partition-size 6144 -cores 2 -no-boot-anim -gpu auto &
   ```

3. **Multiple emulator instances error**:
   ```bash
   # If getting "Running multiple emulators with the same AVD" error
   # First kill existing instances
   pkill -f "emulator.*Alouette_Test"
   # Wait a moment, then restart
   sleep 2
   $ANDROID_HOME/emulator/emulator -avd Alouette_Test -no-snapshot-save -memory 4096 -partition-size 6144 -cores 2 -no-boot-anim -gpu auto &
   ```

### Quick Debug Commands

```bash
# Check connected devices
adb devices -l

# Restart ADB server
adb kill-server && adb start-server

# Check emulator status
emulator -list-avds

# Check running emulators
adb devices

# Force stop and restart emulator (Apple Silicon)
adb emu kill
$ANDROID_HOME/emulator/emulator -avd Alouette_ARM64 -no-snapshot-save &

# Check emulator system info
adb shell getprop ro.build.version.release  # Android version
adb shell getprop ro.product.cpu.abi        # CPU architecture
adb shell getprop ro.build.characteristics  # Device type

# Monitor emulator resource usage
adb shell cat /proc/meminfo | head -5       # Memory info
adb shell cat /proc/cpuinfo | grep "model name" | head -1  # CPU info
```

### Emulator Troubleshooting

```bash
# If emulator won't start
emulator -avd Alouette_Test -verbose  # Start with verbose logging

# If emulator is slow
emulator -avd Alouette_Test -gpu auto -no-boot-anim -memory 4096

# If emulator crashes
emulator -avd Alouette_Test -no-snapshot-load  # Cold boot

# Reset emulator to factory state
emulator -avd Alouette_Test -wipe-data

# Check emulator skin/resolution
emulator -avd Alouette_Test -skin 1080x1920
```

### Application Debugging

```bash
# Clear app data
adb shell pm clear com.alouette.app

# Check app installation status
adb shell pm list packages -f | grep alouette

# Get detailed app info
adb shell dumpsys package com.alouette.app | grep -E "(versionCode|versionName|targetSdkVersion)"

# Monitor app startup time
adb shell am start -W -n com.alouette.app/com.alouette.app.MainActivity

# Check app permissions
adb shell dumpsys package com.alouette.app | grep -A 20 "requested permissions"
```

---

## 🎯 Best Practices Summary

### Memory Configuration Guidelines

**Critical Memory Settings for Linux Systems:**

| System RAM | Recommended Emulator Memory | Max Safe Memory | Partition Size |
|------------|---------------------------|-----------------|----------------|
| 8GB        | 2048MB (2GB)             | 3072MB (3GB)    | 4096MB (4GB)   |
| 16GB       | 4096MB (4GB)             | 4096MB (4GB)    | 6144MB (6GB)   |
| 32GB+      | 4096MB (4GB)             | 6144MB (6GB)    | 8192MB (8GB)   |

**⚠️ Critical Warnings:**
- **Never exceed 4GB** emulator memory on systems with 16GB RAM or less
- **Never exceed 6GB** emulator memory even on high-end systems
- Exceeding these limits can cause **system-wide crashes** and **VS Code OOM-kill**

### Recommended Emulator Command

```bash
# Safe and stable emulator configuration (Linux)
$ANDROID_HOME/emulator/emulator -avd Alouette_Test \
  -memory 2048 \
  -partition-size 4096 \
  -cores 2 \
  -gpu swiftshader_indirect \
  -no-boot-anim \
  -no-snapshot-save &
```

### Quick Development Workflow

1. **Set environment** (once per session):
   ```bash
   export ANDROID_HOME="$PWD/android-sdk"
   export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$PATH"
   ```

2. **Start emulator** (safe configuration):
   ```bash
   $ANDROID_HOME/emulator/emulator -avd Alouette_Test -memory 2048 -cores 2 -gpu swiftshader_indirect &
   sleep 20 && adb wait-for-device
   ```

3. **Build and test** (debug mode):
   ```bash
   npm run dev:android
   ```

4. **Monitor logs**:
   ```bash
   adb logcat | grep -E "(alouette|Alouette|translation|Translation)"
   ```

### 🚨 Emulator Crash Recovery

If the emulator crashes repeatedly:

1. **Check system memory**:
   ```bash
   free -h
   ```

2. **Kill all emulator processes**:
   ```bash
   pkill -f emulator
   ```

3. **Clear emulator cache**:
   ```bash
   rm -rf ~/.android/avd/Alouette_Test.avd/snapshots/
   ```

4. **Restart with minimal settings**:
   ```bash
   $ANDROID_HOME/emulator/emulator -avd Alouette_Test -memory 1024 -gpu swiftshader_indirect -no-audio &
   ```

### Troubleshooting Crashes (Updated June 18, 2025)

#### Symptoms
- Emulator window disappears suddenly
- No device in `adb devices`
- High memory usage in system monitor

#### Solutions
1. **Reduce memory allocation**: Max 2GB on Linux
2. **Use software rendering**: `-gpu swiftshader_indirect`
3. **Disable snapshots**: `-no-snapshot-save`
4. **Monitor system resources**: `htop` or `free -h`
5. **Restart VS Code** if OOM-killed

---

**Last Updated**: June 18, 2025  
**Memory Configuration**: Updated to prevent system crashes ✅  
**Crash Recovery**: Added troubleshooting steps ✅  
**Status**: All major issues resolved ✅

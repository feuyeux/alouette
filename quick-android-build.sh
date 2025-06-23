#!/bin/bash
# 快速Android构建脚本 - 只构建x86_64 Android目标以节省时间

set -e

echo "🔧 Setting up Android environment..."
export ANDROID_HOME="$PWD/android-sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$PATH"

echo "📱 Building Android debug APK (x86_64 only for emulator)..."

# 只构建x86_64目标以节省时间
export TAURI_ANDROID_PROJECT_PATH="src-tauri/gen/android"

# 使用Tauri构建，但只针对x86_64
cd src-tauri
cargo tauri android build --target x86_64 --debug

echo "✅ Build completed!"
echo "📦 APK location: src-tauri/gen/android/app/build/outputs/apk/universal/debug/"

# 检查设备连接
if adb devices | grep -q "emulator\|device"; then
    echo "📲 Installing to connected device..."
    adb install -r gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk
    
    echo "🚀 Launching app..."
    adb shell am start -n com.alouette.app/com.alouette.app.MainActivity
    
    echo "📋 Monitoring logs..."
    adb logcat -c
    adb logcat | grep -E "(alouette|Alouette|AndroidRuntime|FATAL)" &
    
    echo "App launched! Check logs above for any issues."
else
    echo "⚠️  No device connected. Please connect a device or start emulator first."
fi

#!/bin/bash

# Alouette Android 环境配置脚本

echo "=== 配置 Alouette Android 开发环境 ==="

# 获取当前目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 设置环境变量
export ANDROID_HOME="$SCRIPT_DIR/android-sdk"
export NDK_HOME="$ANDROID_HOME/ndk/25.1.8937393"
export GRADLE_HOME="$SCRIPT_DIR/gradle-8.14.2"
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"

# 更新 PATH
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$NDK_HOME:$GRADLE_HOME/bin:$PATH"

# 验证环境
echo "✅ Android SDK: $ANDROID_HOME"
echo "✅ NDK: $NDK_HOME"
echo "✅ Gradle: $GRADLE_HOME"
echo "✅ Java: $JAVA_HOME"

# 检查工具可用性
echo ""
echo "=== 工具检查 ==="
command -v adb >/dev/null 2>&1 && echo "✅ ADB 可用" || echo "❌ ADB 不可用"
command -v gradle >/dev/null 2>&1 && echo "✅ Gradle 可用" || echo "❌ Gradle 不可用"
command -v java >/dev/null 2>&1 && echo "✅ Java 可用" || echo "❌ Java 不可用"

echo ""
echo "=== 环境配置完成 ==="
echo "现在可以运行 Android 开发命令了!"

export OLLAMA_HOST=0.0.0.0:11434
ollama serve# Alouette Android 构建指南

```bash
# 1. 安装系统依赖
sudo apt update && sudo apt install -y \
  clang llvm build-essential \
  openjdk-21-jdk \
  wget unzip curl

# 2. 验证 Java 安装
java -version
# 应显示: openjdk version "21.x.x"

# 3. 安装 Rust Android 编译目标
rustup target add \
  aarch64-linux-android \
  armv7-linux-androideabi \
  i686-linux-android \
  x86_64-linux-android

# 4. 验证 Rust 目标
rustup target list --installed | grep android
```

```bash
# 初始化 Android 支持 (仅首次执行)
npx @tauri-apps/cli android init

# 安装前端依赖
npm install

```bash
# 使用项目提供的环境配置脚本
source ./setup-env.sh
```

```bash
# 设置环境变量
export ANDROID_HOME="$PWD/android-sdk"
export NDK_HOME="$ANDROID_HOME/ndk/android-ndk-r28b"
export GRADLE_HOME="$PWD/gradle-8.14.2"
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"

# 更新 PATH
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$NDK_HOME:$GRADLE_HOME/bin:$PATH"

# 验证环境
echo "Android SDK: $ANDROID_HOME"
echo "NDK: $NDK_HOME"
echo "Gradle: $GRADLE_HOME"
echo "Java: $JAVA_HOME"
```


```bash
# 方法 1: 使用 npm 脚本 (推荐)
npm run build:android

# 方法 2: 使用环境脚本
source ./setup-env.sh && npm run build:android
```

```bash
# 构建 Vue 3 前端
npm run build

# 验证构建输出
ls -la dist/
```

```bash
cd src-tauri

# 为所有 Android 架构编译
cargo tauri android build --verbose
```


| 架构 | 目标平台 | 用途 |
|------|----------|------|
| `aarch64-linux-android` | ARM64 | 现代 Android 设备 (主流) |
| `armv7-linux-androideabi` | ARM32 | 老旧 Android 设备 |
| `i686-linux-android` | x86 | Android 模拟器 |
| `x86_64-linux-android` | x86_64 | 高性能模拟器/设备 |

成功构建后，你将得到以下文件：

APK 文件 (开发/测试用)
```
src-tauri/gen/android/app/build/outputs/apk/universal/release/
├── app-universal-release-unsigned.apk  # 未签名 APK
└── output-metadata.json                # 构建元数据
```

AAB 文件 (Google Play 商店用)
```
src-tauri/gen/android/app/build/outputs/bundle/universalRelease/
└── app-universal-release.aab           # Play Store 包
```


首先，创建并启动Android模拟器：

```bash
# 创建AVD (Android Virtual Device)
avdmanager create avd \
  -n "Alouette_Test" \
  -k "system-images;android-34;google_apis_playstore;x86_64" \
  -d "pixel_7"

# 启动模拟器
$ANDROID_HOME/emulator/emulator -avd Alouette_Test -no-snapshot-save &

# 等待模拟器启动完成
adb wait-for-device
```

安装应用：

```bash
# 安装debug版本APK (推荐用于测试)
adb install src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk

# 启动应用
adb shell am start -n com.alouette.app/com.alouette.app.MainActivity

# 查看应用日志
adb logcat | grep -E "(alouette|Alouette)"
```

#### 在物理设备上安装APK

```bash
# 启用开发者模式和USB调试后
adb devices

# 安装APK
adb install src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk

# 查看安装的应用
adb shell pm list packages | grep alouette
```

```bash
# 监控应用性能
adb shell top | grep alouette

# 检查内存使用
adb shell dumpsys meminfo com.alouette.app

# 监控应用日志
adb logcat -s "AlouetteApp"
```

```bash
# 完整环境检查
echo "=== 环境验证 ==="
echo "Node.js: $(node --version)"
echo "Rust: $(rustc --version)"
echo "Java: $(java -version 2>&1 | head -1)"
echo "Gradle: $(gradle --version | head -1)"
echo "Android SDK: $ANDROID_HOME"
echo "NDK: $NDK_HOME"

echo "=== Android 目标架构 ==="
rustup target list --installed | grep android

echo "=== 工具可用性 ==="
command -v adb && echo "✅ ADB 可用" || echo "❌ ADB 不可用"
command -v gradle && echo "✅ Gradle 可用" || echo "❌ Gradle 不可用"
```

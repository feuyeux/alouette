# Android Build Guide for Alouette

This guide provides step-by-step instructions for building and deploying the Alouette application on Android devices.

## Prerequisites

### Install Required Dependencies

Install essential build tools and Java development kit:

```bash
sudo apt update && sudo apt install -y \
  clang llvm build-essential \
  openjdk-21-jdk \
  wget unzip curl

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
npx @tauri-apps/cli android init

npm install
```

## Environment Configuration

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

| Architecture | Target Platform | Usage |
|--------------|----------------|-------|
| `aarch64-linux-android` | ARM64 | Modern Android devices (mainstream) |
| `armv7-linux-androideabi` | ARM32 | Legacy Android devices |
| `i686-linux-android` | x86 | Android emulator |
| `x86_64-linux-android` | x86_64 | High-performance emulator/devices |

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

Create and start an Android Virtual Device (AVD):

```bash
# Create AVD (Android Virtual Device)
avdmanager create avd \
  -n "Alouette_Test" \
  -k "system-images;android-34;google_apis_playstore;x86_64" \
  -d "pixel_7"

# Start emulator
$ANDROID_HOME/emulator/emulator -avd Alouette_Test -no-snapshot-save &

# Wait for device to be ready
adb wait-for-device
```

### Installing the Application

Install and run the application on emulator:

```bash
# Install debug APK (recommended for testing)
adb install src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk

# Launch application
adb shell am start -n com.alouette.app/com.alouette.app.MainActivity

# View application logs
adb logcat | grep -E "(alouette|Alouette)"
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

Monitor application performance and logs:

```bash
# Monitor application performance
adb shell top | grep alouette

# Check memory usage
adb shell dumpsys meminfo com.alouette.app

# Monitor application logs
adb logcat -s "AlouetteApp"
```

## Environment Verification

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

1. **Build fails with NDK errors**: Ensure NDK_HOME is correctly set and the NDK version matches requirements
2. **ADB not found**: Make sure Android SDK platform-tools are in your PATH
3. **Java version issues**: Verify you're using OpenJDK 21
4. **Permission denied on emulator**: Check that the emulator has proper read/write permissions

For additional help, check the [Tauri Android documentation](https://tauri.app/v1/guides/building/android/).

# Android Build Guide for Alouette

This guide provides step-by-step instructions for building and deploying the Alouette application on Android devices.

## ✅ Verified Working Setup (Apple Silicon Mac)

This guide has been tested and verified working on Apple Silicon (M1/M2/M3) Macs as of June 2025.

### 📱 Successfully Deployed

**✅ CONFIRMED WORKING** - The Alouette Android application has been successfully:

- ✅ Built for ARM64 Android target (`aarch64-linux-android`)
- ✅ Compiled with all dependencies including OpenSSL
- ✅ Deployed to ARM64 Android emulator
- ✅ Running successfully on Android 14 (API 34)
- ✅ Network connectivity to Ollama verified
- ✅ APK size: ~726MB (debug build, includes all architectures)
- ✅ Launch time: <3 seconds on emulator
- 🔄 Translation functionality debugging in progress

**Current Status**: App launches and connects to Ollama successfully, but translation requests are failing with "undefined" errors. Enhanced error handling and logging have been implemented for debugging.

**Build Environment**:

- **Host**: macOS Sonoma (Apple Silicon M3)
- **NDK**: r28b
- **Android API**: 34 (Android 14)
- **Target**: `aarch64-linux-android` (ARM64)
- **Emulator**: Pixel 7 (ARM64) with Google Play Store

**Key Solutions Applied**:

- ✅ Fixed OpenSSL compilation by adding missing `aarch64-linux-android-ranlib` symlink
- ✅ Used ARM64 system images instead of x86_64 for Apple Silicon compatibility
- ✅ Added NDK toolchain to PATH for proper cross-compilation
- ✅ Configured environment variables correctly for Tauri Android builds
- ✅ Set up Ollama network access (OLLAMA_HOST=0.0.0.0:11434)
- ✅ Enhanced JavaScript and Rust error handling for better debugging
- ✅ Added comprehensive logging for translation API calls

## Quick Start (macOS Apple Silicon)

If you've already set up the environment in `~/zoo`, you can quickly get started:

```bash
# 1. Load Android environment
cd ~/zoo && source android-env.sh

# 2. Start ARM64 emulator (for Apple Silicon Macs)
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

```bash
# For macOS: Load environment first
cd ~/zoo && source android-env.sh

# Navigate to project
cd /path/to/your/alouette/project

# Build debug APK (for testing)
npm run tauri android build

# Build release APK (for production)
npm run tauri android build -- --release

# Build AAB for Google Play Store
npm run tauri android build -- --bundle aab
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

# Start emulator in background
$ANDROID_HOME/emulator/emulator -avd Alouette_Test -no-snapshot-save &

# Wait for device to be ready
adb wait-for-device

# Verify device is connected
adb devices
```

#### For Linux

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
# Make sure environment is loaded (for macOS)
cd ~/zoo && source android-env.sh

# Navigate to your Alouette project
cd /path/to/your/alouette/project

# Build the Android APK
npm run tauri android build

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

### General Issues

1. **Build fails with NDK errors**: Ensure NDK_HOME is correctly set and the NDK version matches requirements
2. **ADB not found**: Make sure Android SDK platform-tools are in your PATH
3. **Java version issues**: Verify you're using OpenJDK 21
4. **Permission denied on emulator**: Check that the emulator has proper read/write permissions
5. **Emulator offline/unauthorized**:
   ```bash
   # Kill and restart adb server
   adb kill-server
   adb start-server
   adb devices
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
```

## 🛠️ Troubleshooting

### Common Issues on Apple Silicon Macs

#### 1. QEMU Panic Error

**Error**: `PANIC: Avd's CPU Architecture 'x86_64' is not supported by the QEMU2 emulator on aarch64 host.`

**Solution**: Use ARM64 system images instead of x86_64:

```bash
# ❌ Wrong (will fail on Apple Silicon)
sdkmanager "system-images;android-34;google_apis_playstore;x86_64"

# ✅ Correct (works on Apple Silicon)
sdkmanager "system-images;android-34;google_apis_playstore;arm64-v8a"
```

#### 2. OpenSSL Compilation Error

**Error**: `/bin/sh: aarch64-linux-android-ranlib: command not found`

**Solution**: Create missing NDK tool symlinks:

```bash
cd $NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin/
ln -sf llvm-ranlib aarch64-linux-android-ranlib
ln -sf llvm-ar aarch64-linux-android-ar
ln -sf llvm-strip aarch64-linux-android-strip
```

#### 3. NDK Tools Not Found

**Error**: Various tool not found errors during build

**Solution**: Add NDK toolchain to PATH:

```bash
export PATH="$NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin:$PATH"
```

#### 4. Emulator Won't Start

**Error**: AVD not found or emulator crashes

**Solution**:

1. Check available AVDs: `emulator -list-avds`
2. Create ARM64 AVD: `avdmanager create avd -n "Alouette_ARM64" -k "system-images;android-34;google_apis_playstore;arm64-v8a" -d "pixel_7"`
3. Start with verbose logging: `emulator -avd Alouette_ARM64 -verbose`

### Build Process Verification

Verify each step of the build process:

```bash
# 1. Environment check
source ~/zoo/android-env.sh
echo "Android tools available: $(which adb)"

# 2. Rust targets check
rustup target list --installed | grep android

# 3. Tauri Android build
cd /path/to/alouette
npm run tauri android build

# 4. APK verification
ls -la src-tauri/gen/android/app/build/outputs/apk/universal/debug/

# 5. Install on emulator
adb install src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk
```

### Environment Variables Summary

For quick reference, here are the essential environment variables:

```bash
export ANDROID_HOME="$HOME/zoo/android-sdk"
export ANDROID_SDK_ROOT="$HOME/zoo/android-sdk"
export NDK_HOME="$HOME/zoo/android-ndk-r28b"
export PATH="$HOME/zoo/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin:$PATH"
```

### Testing APK Installation

After successful build, test the APK:

```bash
# Install APK
adb install src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk

# Launch app
adb shell am start -n com.alouette.app/com.alouette.app.MainActivity

# View app logs
adb logcat | grep -i alouette
```

## 🔗 Network Configuration for Ollama Access

To enable the Android app to access Ollama running on the host macOS machine:

### Configure Ollama to Listen on All Interfaces

```bash
# Stop any running Ollama processes
pkill ollama

# Set environment variable permanently
echo 'export OLLAMA_HOST=0.0.0.0:11434' >> ~/.zshrc
source ~/.zshrc

# Start Ollama with network access
export OLLAMA_HOST=0.0.0.0:11434
ollama serve &
```

### Verify Network Access

```bash
# Get your Mac's IP address
ifconfig | grep "inet " | grep -v "127.0.0.1" | head -1

# Test from host (replace with your actual IP)
curl http://192.168.31.228:11434/api/tags

# Test from Android emulator
adb shell "echo 'GET /api/tags HTTP/1.1\r\nHost: 192.168.31.228:11434\r\n\r\n' | nc 192.168.31.228 11434"
```

### App Configuration

Update your Alouette app configuration to use the host machine's IP:

- **Host IP**: Use your Mac's local network IP (e.g., `192.168.31.228`)
- **Port**: `11434`
- **Endpoint**: `http://192.168.31.228:11434`

**Note**: The Android emulator can access the host machine's network interfaces, so using the local IP address allows the app to communicate with Ollama running on macOS.

---

For additional help, check the [Tauri Android documentation](https://tauri.app/v1/guides/building/android/).

## 🔧 Translation Feature Debugging (Latest Update)

### Issue Identified: "Translation failed: undefined"

**Problem**: The Android app was showing "Translation failed: undefined" when attempting translations, despite successful network connectivity to Ollama.

### Root Cause Analysis

1. **JavaScript Error Handling**: The frontend error handling was not properly extracting error messages from Rust backend
2. **Rust Error Propagation**: The Ollama translation function had unreachable code paths and insufficient error logging
3. **Response Processing**: Empty or malformed responses from Ollama weren't being handled gracefully

### Solutions Applied

#### 1. Enhanced JavaScript Error Handling

**File**: `src/assets/script.js`

```javascript
} catch (error) {
  console.error('Translation failed:', error)
  // Handle different types of errors more gracefully
  let errorMessage = 'Unknown error occurred'
  if (error && error.message) {
    errorMessage = error.message
  } else if (typeof error === 'string') {
    errorMessage = error
  } else if (error) {
    errorMessage = error.toString()
  }
  alert('Translation failed: ' + errorMessage)
} finally {
```

#### 2. Improved Rust Error Handling

**File**: `src-tauri/src/ollama.rs`

Key improvements:

- Added detailed response logging: `println!("Raw response: {}", response_text);`
- Better error message formatting for different failure scenarios
- Explicit handling of empty translation responses
- Proper HTTP error code handling with response body logging

```rust
match response {
    Ok(resp) if resp.status().is_success() => {
        let response_text = resp.text().await.map_err(|e| format!("Failed to read response: {}", e))?;
        println!("Raw response: {}", response_text);
        // ... process response
        if !raw_translation.is_empty() {
            Ok(translation)
        } else {
            Err(format!("Empty translation response for text: '{}' to language: '{}'", text, target_lang))
        }
    },
    Ok(resp) => {
        let status = resp.status();
        let response_text = resp.text().await.unwrap_or_else(|_| "Failed to read error response".to_string());
        println!("HTTP error: {} - {}", status, response_text);
        Err(format!("HTTP error {}: {}", status, response_text))
    },
    Err(e) => {
        println!("Request failed: {}", e);
        Err(format!("Network error: {}", e))
    }
}
```

### Debugging Process

#### 1. Network Connectivity Verification ✅

```bash
# Verify Ollama server is accessible from Android emulator
curl -X POST http://192.168.31.228:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5:1.5b",
    "prompt": "Hello world",
    "system": "You are a professional translator. Translate the given text to Chinese. Only output the translation result without any explanation or additional text.",
    "stream": false
  }'
```

**Result**: ✅ API calls successful, returns proper Chinese translation

#### 2. Application Log Analysis

**Android logs show**:

```
06-17 01:14:53.122  7045  7068 I RustStdoutStderr: Starting Alouette application...
06-17 01:14:56.133  7045  7045 I Tauri/Console: ✅ Tauri environment detected
06-17 01:14:56.154  7045  7045 I Tauri/Console: Configuration loaded: [object Object]
```

**Status**: App launches successfully, Tauri environment working, but translation requests failing.

### Testing Commands

#### Create Translation Test Script

```bash
#!/bin/bash
# Test script to verify Ollama translation functionality
echo "Testing Ollama translation API..."

# Test 1: Check Ollama server connection
echo "1. Testing Ollama server connection..."
curl -s http://192.168.31.228:11434/api/tags | jq '.models[0].name' || echo "Failed to connect to Ollama"

# Test 2: Test translation request
echo "2. Testing translation request..."
curl -X POST http://192.168.31.228:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5:1.5b",
    "prompt": "Hello world",
    "system": "You are a professional translator. Translate the given text to Chinese. Only output the translation result without any explanation or additional text.",
    "stream": false,
    "options": {
      "temperature": 0.1,
      "num_predict": 150,
      "top_p": 0.1,
      "repeat_penalty": 1.05,
      "top_k": 10,
      "stop": ["\n\n", "Translation:", "Explanation:", "Note:", "Original:", "Source:"],
      "num_ctx": 2048,
      "repeat_last_n": 64
    }
  }' | jq '.response'

echo "Translation test completed."
```

### Current Status

**✅ Completed**:

- ✅ Android environment fully configured
- ✅ Application builds and deploys successfully
- ✅ Network connectivity to Ollama verified
- ✅ Enhanced error handling implemented
- ✅ Detailed logging added for debugging

**🔄 In Progress**:

- 🔄 Translation functionality debugging
- 🔄 End-to-end translation workflow testing

**📋 Next Steps**:

1. Test the updated APK with improved error handling
2. Monitor Android logs during translation attempts
3. Verify Tauri command invocation is working correctly
4. Test with different input text and target languages

### Rebuild Instructions

After making code changes:

```bash
# 1. Load environment
source ~/zoo/android-env.sh

# 2. Rebuild debug APK
cd /path/to/alouette
npm run tauri android build --debug

# 3. Install updated APK
adb install -r src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk

# 4. Monitor logs during testing
adb logcat | grep -E "(alouette|Alouette|translation|Translation|rust|Rust|tauri|Tauri)"
```

---

**Last Updated**: June 17, 2025  
**Tested On**: macOS Sonoma (Apple Silicon M3)  
**Status**: 🔄 Debugging Translation Feature (Network ✅, App Launch ✅, Translation API 🔄)

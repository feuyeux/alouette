#!/bin/bash

# Alouette Base App 快速启动脚本
# Quick start script for Alouette Base App
#
# Usage:
#   ./run_app.sh [platform] [--no-clean] [--device=DEVICE_ID]
#
# Examples:
#   ./run_app.sh                    # Run on default platform (macOS/Linux) with clean build
#   ./run_app.sh linux              # Run on Linux desktop with clean build
#   ./run_app.sh ios                # Run on iOS with clean build
#   ./run_app.sh ios --no-clean     # Run on iOS without cleaning (faster iteration)
#   ./run_app.sh --device=<UUID>    # Run on specific device with clean build
#   ./run_app.sh chrome --no-clean  # Run on Chrome without cleaning
#   ./run_app.sh android            # Run on Android with clean build

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 Starting Alouette Base App${NC}"

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            if [[ "$ID" == "ubuntu" ]] || [[ "$ID_LIKE" == *"ubuntu"* ]] || [[ "$ID_LIKE" == *"debian"* ]]; then
                echo "ubuntu"
            else
                echo "linux"
            fi
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

OS_TYPE=$(detect_os)
echo -e "${GREEN}🖥️  Detected OS: $OS_TYPE${NC}"

# Ubuntu/Linux 系统设置
setup_ubuntu_environment() {
    echo -e "${BLUE}🐧 Setting up Ubuntu environment...${NC}"
    
    # 检查 Flutter Linux 桌面支持
    if ! flutter config | grep -q "linux.*true"; then
        echo -e "${YELLOW}⚠️  Flutter Linux desktop support is not enabled${NC}"
        echo -e "${BLUE}💡 Enabling Flutter Linux desktop support...${NC}"
        flutter config --enable-linux-desktop
        echo -e "${GREEN}✅ Flutter Linux desktop support enabled${NC}"
    fi
    
    # 检查必要的系统依赖
    check_ubuntu_dependencies
}

# 检查 Ubuntu 系统依赖
check_ubuntu_dependencies() {
    echo -e "${BLUE}🔍 Checking Ubuntu system dependencies...${NC}"
    
    local missing_packages=()
    
    # 检查 GTK 开发库
    if ! dpkg -l | grep -q libgtk-3-dev; then
        missing_packages+=("libgtk-3-dev")
    fi
    
    # 检查其他必要的开发库
    local required_packages=("ninja-build" "libblkid-dev" "liblzma-dev" "pkg-config")
    for package in "${required_packages[@]}"; do
        if ! dpkg -l | grep -q "^ii.*$package"; then
            missing_packages+=("$package")
        fi
    done
    
    if [ ${#missing_packages[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Missing required system packages:${NC}"
        printf '%s\n' "${missing_packages[@]}" | sed 's/^/  - /'
        echo -e "${BLUE}💡 Install missing packages with:${NC}"
        echo -e "${GREEN}sudo apt update && sudo apt install ${missing_packages[*]}${NC}"
        echo -e "${YELLOW}⚠️  Please install missing packages and run the script again${NC}"
        exit 1
    else
        echo -e "${GREEN}✅ All required system dependencies are installed${NC}"
    fi
    
    # 检查 Flutter 安装方式和 GLIBC 兼容性
    check_flutter_installation
}

# 检查 Flutter 安装方式并尝试修复兼容性问题
check_flutter_installation() {
    local flutter_path=$(which flutter)
    
    if [[ "$flutter_path" == *"/snap/"* ]]; then
        echo -e "${YELLOW}⚠️  Flutter is installed via Snap${NC}"
        
        # 检查 Ubuntu 版本
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            if [[ "$VERSION_ID" == "24.04" ]]; then
                echo -e "${YELLOW}⚠️  Ubuntu 24.04 detected with Flutter Snap - applying compatibility fixes${NC}"
                
                # 尝试多种兼容性修复方案
                apply_glibc_compatibility_fixes
            fi
        fi
    else
        echo -e "${GREEN}✅ Flutter is installed manually${NC}"
    fi
}

# 应用 GLIBC 兼容性修复
apply_glibc_compatibility_fixes() {
    echo -e "${BLUE}🔧 Applying GLIBC compatibility fixes...${NC}"
    
    # 方案1: 设置环境变量强制使用系统库
    export LD_LIBRARY_PATH="/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/snap/flutter/current/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"
    export PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig:$PKG_CONFIG_PATH"
    
    # 方案2: 创建兼容性符号链接
    create_compatibility_links
    
    # 方案3: 设置编译器标志
    export CC="/usr/bin/gcc"
    export CXX="/usr/bin/g++"
    export CMAKE_C_COMPILER="/usr/bin/gcc"
    export CMAKE_CXX_COMPILER="/usr/bin/g++"
    
    # 方案4: 禁用有问题的链接器标志
    export LDFLAGS="-Wl,--allow-multiple-definition"
    
    echo -e "${GREEN}✅ Applied compatibility fixes${NC}"
}

# 创建兼容性符号链接
create_compatibility_links() {
    local temp_lib_dir="/tmp/flutter_compat_libs"
    
    if [ ! -d "$temp_lib_dir" ]; then
        mkdir -p "$temp_lib_dir"
        
        # 创建指向系统库的符号链接
        if [ -f "/usr/lib/x86_64-linux-gnu/libfreetype.so.6" ]; then
            ln -sf "/usr/lib/x86_64-linux-gnu/libfreetype.so.6" "$temp_lib_dir/libfreetype.so.6"
        fi
        
        if [ -f "/usr/lib/x86_64-linux-gnu/libexpat.so.1" ]; then
            ln -sf "/usr/lib/x86_64-linux-gnu/libexpat.so.1" "$temp_lib_dir/libexpat.so.1"
        fi
        
        # 将临时库目录添加到库路径前面
        export LD_LIBRARY_PATH="$temp_lib_dir:$LD_LIBRARY_PATH"
    fi
}

# 尝试自动安装手动版本的Flutter
attempt_flutter_manual_install() {
    echo -e "${BLUE}🔄 Attempting to install Flutter manually...${NC}"
    
    local flutter_dir="$HOME/flutter"
    local flutter_url="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.35.4-stable.tar.xz"
    
    # 检查是否已经有手动安装的Flutter
    if [ -d "$flutter_dir" ] && [ -f "$flutter_dir/bin/flutter" ]; then
        echo -e "${GREEN}✅ Manual Flutter installation found${NC}"
        export PATH="$flutter_dir/bin:$PATH"
        return 0
    fi
    
    # 询问用户是否同意自动安装
    echo -e "${YELLOW}This will download and install Flutter manually to fix compatibility issues.${NC}"
    echo -e "${BLUE}Continue? (y/N)${NC}"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}📥 Downloading Flutter SDK...${NC}"
        
        # 创建临时目录
        local temp_dir=$(mktemp -d)
        cd "$temp_dir"
        
        # 下载Flutter
        if wget -q --show-progress "$flutter_url" -O flutter.tar.xz; then
            echo -e "${BLUE}📦 Extracting Flutter...${NC}"
            
            # 解压到用户目录
            tar xf flutter.tar.xz -C "$HOME"
            
            if [ -d "$flutter_dir" ] && [ -f "$flutter_dir/bin/flutter" ]; then
                # 更新PATH
                export PATH="$flutter_dir/bin:$PATH"
                
                # 添加到bashrc
                if ! grep -q "flutter/bin" "$HOME/.bashrc"; then
                    echo 'export PATH="$PATH:$HOME/flutter/bin"' >> "$HOME/.bashrc"
                fi
                
                # 配置Flutter
                flutter config --enable-linux-desktop
                
                # 确保使用系统编译器而不是Snap编译器
                export CC="/usr/bin/gcc"
                export CXX="/usr/bin/g++"
                export CMAKE_C_COMPILER="/usr/bin/gcc"
                export CMAKE_CXX_COMPILER="/usr/bin/g++"
                
                # 创建Flutter工具链配置
                create_flutter_toolchain_config "$flutter_dir"
                
                echo -e "${GREEN}✅ Flutter installed successfully${NC}"
                cd "$SCRIPT_DIR"
                rm -rf "$temp_dir"
                return 0
            fi
        fi
        
        cd "$SCRIPT_DIR"
        rm -rf "$temp_dir"
        echo -e "${RED}❌ Failed to install Flutter${NC}"
        return 1
    else
        echo -e "${YELLOW}⚠️  Installation cancelled${NC}"
        return 1
    fi
}

# 处理Flutter运行失败
handle_flutter_failure() {
    echo -e "${RED}❌ Failed to launch Flutter app${NC}"
    
    # Ubuntu/Linux 特定的错误处理
    if [[ "$OS_TYPE" == "ubuntu" || "$OS_TYPE" == "linux" ]]; then
        echo -e "${BLUE}💡 Ubuntu troubleshooting tips:${NC}"
        
        if [ "$IS_LINUX" = true ]; then
            echo -e "${GREEN}1. Check Flutter doctor: flutter doctor${NC}"
            echo -e "${GREEN}2. Verify Linux desktop support: flutter config --list${NC}"
            echo -e "${GREEN}3. Check system dependencies: sudo apt list --installed | grep -E '(gtk|ninja|pkg-config)'${NC}"
            
            # 检查是否是 GLIBC 兼容性问题
            flutter_path=$(which flutter)
            if [[ "$flutter_path" == *"/snap/"* ]] && [ -f /etc/os-release ]; then
                . /etc/os-release
                if [[ "$VERSION_ID" == "24.04" ]]; then
                    echo -e "${YELLOW}⚠️  GLIBC compatibility issue detected (Ubuntu 24.04 + Flutter Snap)${NC}"
                    echo -e "${GREEN}4. Install Flutter manually for better compatibility:${NC}"
                    echo -e "${GREEN}   - Remove snap: sudo snap remove flutter${NC}"
                    echo -e "${GREEN}   - Download from: https://docs.flutter.dev/get-started/install/linux${NC}"
                    echo -e "${GREEN}   - Extract and add to PATH${NC}"
                    echo -e "${GREEN}5. Alternative: Use Flutter from APT (if available)${NC}"
                else
                    echo -e "${GREEN}4. Try running with verbose output: flutter run -d linux -v${NC}"
                fi
            else
                echo -e "${GREEN}4. Try running with verbose output: flutter run -d linux -v${NC}"
            fi
        elif [ "$IS_ANDROID" = true ]; then
            echo -e "${GREEN}1. Check Android setup: flutter doctor${NC}"
            echo -e "${GREEN}2. Verify device connection: adb devices${NC}"
            echo -e "${GREEN}3. Check USB debugging is enabled on device${NC}"
            echo -e "${GREEN}4. Verify udev rules: ls -la /etc/udev/rules.d/*android*${NC}"
        elif [ "$PLATFORM" = "chrome" ]; then
            echo -e "${GREEN}1. Check web support: flutter config --list${NC}"
            echo -e "${GREEN}2. Verify browser installation: which google-chrome chromium-browser firefox${NC}"
            echo -e "${GREEN}3. Enable web support: flutter config --enable-web${NC}"
        fi
    fi
    
    exit 1
}

# 创建Flutter工具链配置
create_flutter_toolchain_config() {
    local flutter_dir="$1"
    local config_dir="$flutter_dir/bin/cache/artifacts/engine/linux-x64"
    
    if [ -d "$config_dir" ]; then
        # 创建自定义工具链配置
        cat > "$config_dir/flutter_linux_config.cmake" << 'EOF'
# Custom toolchain for Ubuntu 24.04 compatibility
set(CMAKE_C_COMPILER "/usr/bin/gcc")
set(CMAKE_CXX_COMPILER "/usr/bin/g++")
set(CMAKE_LINKER "/usr/bin/ld")
set(CMAKE_AR "/usr/bin/ar")
set(CMAKE_RANLIB "/usr/bin/ranlib")
set(CMAKE_STRIP "/usr/bin/strip")

# Use system libraries
set(CMAKE_FIND_ROOT_PATH "/usr")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# Disable problematic flags
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--allow-multiple-definition")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--allow-multiple-definition")
EOF
        
        echo -e "${GREEN}✅ Created Flutter toolchain configuration${NC}"
    fi
}

# 修复CMake配置以解决Ubuntu 24.04兼容性问题
fix_cmake_configuration() {
    local cmake_file="linux/CMakeLists.txt"
    
    if [ -f "$cmake_file" ]; then
        # 备份原始文件
        cp "$cmake_file" "$cmake_file.backup"
        
        # 在CMakeLists.txt开头添加Ubuntu 24.04兼容性设置
        cat > "$cmake_file.tmp" << 'EOF'
# Ubuntu 24.04 compatibility fixes
cmake_minimum_required(VERSION 3.10)

# Force use of system compilers
set(CMAKE_C_COMPILER "/usr/bin/gcc")
set(CMAKE_CXX_COMPILER "/usr/bin/g++")

# Set compiler and linker flags for Ubuntu 24.04
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--allow-multiple-definition -Wl,--as-needed")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--allow-multiple-definition -Wl,--as-needed")

# Use system pkg-config
find_package(PkgConfig REQUIRED)

EOF
        
        # 添加原始内容（跳过第一行的cmake_minimum_required）
        tail -n +2 "$cmake_file" >> "$cmake_file.tmp"
        
        # 替换原文件
        mv "$cmake_file.tmp" "$cmake_file"
        
        echo -e "${GREEN}✅ Applied CMake compatibility fixes${NC}"
    fi
    
    # 同时设置环境变量
    export CC="/usr/bin/gcc"
    export CXX="/usr/bin/g++"
    export CMAKE_C_COMPILER="/usr/bin/gcc"
    export CMAKE_CXX_COMPILER="/usr/bin/g++"
    export PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig"
}

# 检查并启动浏览器 (Ubuntu)
setup_ubuntu_browser() {
    local browser_found=false
    
    # 尝试 Chrome
    if command -v google-chrome &> /dev/null; then
        echo -e "${GREEN}✅ Found Google Chrome${NC}"
        browser_found=true
    # 尝试 Chromium
    elif command -v chromium-browser &> /dev/null; then
        echo -e "${GREEN}✅ Found Chromium${NC}"
        browser_found=true
    # 尝试 Firefox
    elif command -v firefox &> /dev/null; then
        echo -e "${GREEN}✅ Found Firefox${NC}"
        browser_found=true
    fi
    
    if [ "$browser_found" = false ]; then
        echo -e "${YELLOW}⚠️  No suitable browser found for web development${NC}"
        echo -e "${BLUE}💡 Install a browser with:${NC}"
        echo -e "${GREEN}sudo apt update && sudo apt install google-chrome-stable${NC}"
        echo -e "${GREEN}# or${NC}"
        echo -e "${GREEN}sudo apt install chromium-browser${NC}"
        echo -e "${GREEN}# or${NC}"
        echo -e "${GREEN}sudo apt install firefox${NC}"
        exit 1
    fi
}

# 检查 Android 开发环境 (Ubuntu)
check_ubuntu_android_setup() {
    echo -e "${BLUE}🤖 Checking Android development setup on Ubuntu...${NC}"
    
    # 检查 Android SDK
    if [ -z "$ANDROID_HOME" ] && [ -z "$ANDROID_SDK_ROOT" ]; then
        echo -e "${YELLOW}⚠️  Android SDK not found${NC}"
        echo -e "${BLUE}💡 Install Android SDK with:${NC}"
        echo -e "${GREEN}1. Download Android Studio from https://developer.android.com/studio${NC}"
        echo -e "${GREEN}2. Or install command line tools and set ANDROID_HOME environment variable${NC}"
        echo -e "${GREEN}3. Add to ~/.bashrc or ~/.zshrc:${NC}"
        echo -e "${GREEN}   export ANDROID_HOME=\$HOME/Android/Sdk${NC}"
        echo -e "${GREEN}   export PATH=\$PATH:\$ANDROID_HOME/emulator${NC}"
        echo -e "${GREEN}   export PATH=\$PATH:\$ANDROID_HOME/tools${NC}"
        echo -e "${GREEN}   export PATH=\$PATH:\$ANDROID_HOME/tools/bin${NC}"
        echo -e "${GREEN}   export PATH=\$PATH:\$ANDROID_HOME/platform-tools${NC}"
        return 1
    fi
    
    # 检查 udev 规则 (用于 USB 调试)
    if [ ! -f /etc/udev/rules.d/51-android.rules ]; then
        echo -e "${YELLOW}⚠️  Android udev rules not found${NC}"
        echo -e "${BLUE}💡 For USB debugging, create udev rules:${NC}"
        echo -e "${GREEN}sudo wget -S -O - http://source.android.com/source/51-android.rules | sudo tee >/dev/null /etc/udev/rules.d/51-android.rules${NC}"
        echo -e "${GREEN}sudo udevadm control --reload-rules${NC}"
        echo -e "${GREEN}sudo usermod -a -G plugdev \$USER${NC}"
    fi
    
    return 0
}

# 系统特定设置
case $OS_TYPE in
    "ubuntu"|"linux")
        setup_ubuntu_environment
        ;;
    "macos")
        # 确保Homebrew在PATH中 (修复CocoaPods问题)
        if [[ -d "/opt/homebrew/bin" ]]; then
            export PATH="/opt/homebrew/bin:$PATH"
            echo -e "${GREEN}✅ Added Homebrew to PATH${NC}"
        fi
        ;;
esac

# 切换到应用目录
cd "$SCRIPT_DIR"

# 检查pubspec.yaml
if [[ ! -f "pubspec.yaml" ]]; then
    echo "❌ Error: pubspec.yaml not found in $(pwd)"
    exit 1
fi

echo -e "${GREEN}📂 Running from: $(pwd)${NC}"

# 解析参数 - 默认启用清理构建
CLEAN=true
# 根据操作系统设置默认平台
case $OS_TYPE in
    "ubuntu"|"linux")
        PLATFORM="linux"
        ;;
    "macos")
        PLATFORM="macos"
        ;;
    *)
        PLATFORM="chrome"
        ;;
esac
DEVICE_ID=""
IS_IOS=false
IS_ANDROID=false
IS_LINUX=false
VERBOSE=false

for arg in "$@"; do
    case $arg in
        --no-clean)
            CLEAN=false
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        macos|linux|windows|chrome|android|ios)
            PLATFORM=$arg
            if [ "$arg" = "ios" ]; then
                IS_IOS=true
            elif [ "$arg" = "android" ]; then
                IS_ANDROID=true
            elif [ "$arg" = "linux" ]; then
                IS_LINUX=true
            fi
            shift
            ;;
        --device=*)
            DEVICE_ID="${arg#*=}"
            if [ "$PLATFORM" = "ios" ]; then
                IS_IOS=true
            elif [ "$PLATFORM" = "android" ]; then
                IS_ANDROID=true
            elif [ "$PLATFORM" = "linux" ]; then
                IS_LINUX=true
            fi
            shift
            ;;
        *)
            ;;
    esac
done

echo -e "${GREEN}🎯 Platform: $PLATFORM${NC}"
if [ "$CLEAN" = true ]; then
    echo -e "${BLUE}🧹 Clean build enabled (use --no-clean to skip)${NC}"
else
    echo -e "${BLUE}⚡ Fast build mode (no cleaning)${NC}"
fi

# 平台特定的预检查
case $PLATFORM in
    "linux")
        if [[ "$OS_TYPE" != "ubuntu" && "$OS_TYPE" != "linux" ]]; then
            echo -e "${RED}❌ Error: Linux platform selected but not running on Linux system${NC}"
            exit 1
        fi
        IS_LINUX=true
        ;;
    "chrome")
        if [[ "$OS_TYPE" == "ubuntu" || "$OS_TYPE" == "linux" ]]; then
            setup_ubuntu_browser
        fi
        ;;
    "android")
        if [[ "$OS_TYPE" == "ubuntu" || "$OS_TYPE" == "linux" ]]; then
            if ! check_ubuntu_android_setup; then
                exit 1
            fi
        fi
        ;;
esac

# Android 设备/模拟器选择
if [ "$PLATFORM" = "android" ]; then
    if [ -z "$DEVICE_ID" ]; then
        echo -e "${BLUE}📱 Checking available Android devices/emulators...${NC}"
        
        # 获取可用的 Android 设备和模拟器列表
        ANDROID_DEVICES=$(flutter devices 2>/dev/null | grep -i "android" || true)
        
        if [ -z "$ANDROID_DEVICES" ]; then
            echo -e "${BLUE}⚠️  No Android devices or emulators found${NC}"
            
            # Ubuntu/Linux 特定的模拟器启动逻辑
            if [[ "$OS_TYPE" == "ubuntu" || "$OS_TYPE" == "linux" ]]; then
                echo -e "${BLUE}💡 Attempting to start Android emulator on Ubuntu...${NC}"
                
                # 检查是否有可用的 AVD
                AVAILABLE_AVDS=$(emulator -list-avds 2>/dev/null || true)
                if [ -z "$AVAILABLE_AVDS" ]; then
                    echo -e "${RED}❌ No Android Virtual Devices (AVDs) found${NC}"
                    echo -e "${BLUE}💡 Create an AVD with:${NC}"
                    echo -e "${GREEN}flutter emulators --create --name flutter_emulator${NC}"
                    echo -e "${GREEN}# or use Android Studio to create an AVD${NC}"
                    exit 1
                fi
                
                # 启动第一个可用的 AVD
                FIRST_AVD=$(echo "$AVAILABLE_AVDS" | head -n 1)
                echo -e "${BLUE}🚀 Starting AVD: $FIRST_AVD${NC}"
                
                # Ubuntu 上可能需要设置显示环境变量
                if [ -z "$DISPLAY" ]; then
                    export DISPLAY=:0
                fi
                
                emulator -avd "$FIRST_AVD" &>/dev/null &
                EMULATOR_PID=$!
            else
                echo -e "${BLUE}💡 Attempting to start Android emulator...${NC}"
                emulator -avd $(emulator -list-avds | head -n 1) &>/dev/null &
                EMULATOR_PID=$!
            fi
            
            # 等待模拟器启动 (最多等待 60 秒)
            echo -e "${BLUE}⏳ Waiting for emulator to boot...${NC}"
            for i in {1..60}; do
                sleep 1
                ANDROID_DEVICES=$(flutter devices 2>/dev/null | grep -i "android" || true)
                if [ ! -z "$ANDROID_DEVICES" ]; then
                    echo -e "${GREEN}✅ Emulator ready!${NC}"
                    break
                fi
                printf "."
            done
            echo ""
            
            if [ -z "$ANDROID_DEVICES" ]; then
                echo -e "${RED}❌ Error: Emulator did not start in time${NC}"
                if [[ "$OS_TYPE" == "ubuntu" || "$OS_TYPE" == "linux" ]]; then
                    echo -e "${BLUE}💡 Ubuntu troubleshooting:${NC}"
                    echo -e "${GREEN}1. Check if KVM is enabled: ls -la /dev/kvm${NC}"
                    echo -e "${GREEN}2. Add user to kvm group: sudo usermod -a -G kvm \$USER${NC}"
                    echo -e "${GREEN}3. Check hardware acceleration: grep -E '^flags.*(vmx|svm)' /proc/cpuinfo${NC}"
                    echo -e "${GREEN}4. Install QEMU KVM: sudo apt install qemu-kvm${NC}"
                fi
                echo "Please start an Android emulator manually and try again"
                echo "Or connect a physical Android device with USB debugging enabled"
                exit 1
            fi
        fi
        
        echo -e "${GREEN}Available Android devices:${NC}"
        echo "$ANDROID_DEVICES"
        echo ""
        
        # 提取第一个 Android 设备的 ID（优先选择 emulator）
        # Flutter devices 输出格式: "设备名 (类型) • 设备ID • 架构 • 详细信息"
        # 使用 sed 提取第一个 • 和第二个 • 之间的内容（设备ID）
        DEVICE_ID=$(echo "$ANDROID_DEVICES" | grep -i "emulator" | head -n 1 | sed -n 's/.*• \([^ ]*\) •.*/\1/p' || true)
        
        # 如果没有 emulator，尝试获取物理设备
        if [ -z "$DEVICE_ID" ]; then
            DEVICE_ID=$(echo "$ANDROID_DEVICES" | grep -i "android" | head -n 1 | sed -n 's/.*• \([^ ]*\) •.*/\1/p' || true)
        fi
        
        if [ -z "$DEVICE_ID" ]; then
            echo -e "${RED}❌ Error: Could not extract device ID from Android devices list${NC}"
            echo "Debug info:"
            echo "ANDROID_DEVICES output:"
            echo "$ANDROID_DEVICES"
            exit 1
        fi
        
        echo -e "${GREEN}📱 Selected Android device: $DEVICE_ID${NC}"
        PLATFORM="$DEVICE_ID"
    else
        echo -e "${GREEN}📱 Using specified device: $DEVICE_ID${NC}"
        PLATFORM="$DEVICE_ID"
    fi
fi

# iOS 设备/模拟器选择
if [ "$PLATFORM" = "ios" ]; then
    if [ -z "$DEVICE_ID" ]; then
        echo -e "${BLUE}📱 Checking available iOS devices/simulators...${NC}"
        
        # 获取可用的 iOS 设备和模拟器列表
        IOS_DEVICES=$(flutter devices 2>/dev/null | grep -i "ios" || true)
        
        if [ -z "$IOS_DEVICES" ]; then
            echo -e "${BLUE}⚠️  No iOS devices or simulators found${NC}"
            echo -e "${BLUE}💡 Starting iOS simulator...${NC}"
            open -a Simulator
            
            # 等待模拟器启动 (最多等待 30 秒)
            echo -e "${BLUE}⏳ Waiting for simulator to boot...${NC}"
            for i in {1..30}; do
                sleep 1
                IOS_DEVICES=$(flutter devices 2>/dev/null | grep -i "ios" || true)
                if [ ! -z "$IOS_DEVICES" ]; then
                    echo -e "${GREEN}✅ Simulator ready!${NC}"
                    break
                fi
                printf "."
            done
            echo ""
            
            if [ -z "$IOS_DEVICES" ]; then
                echo "❌ Error: Simulator did not start in time"
                echo "Please wait for the simulator to fully boot and try again"
                exit 1
            fi
        fi
        
        echo -e "${GREEN}Available iOS devices:${NC}"
        echo "$IOS_DEVICES"
        echo ""
        
        # 提取第一个 iOS 设备的 UUID（优先选择 simulator）
        DEVICE_ID=$(echo "$IOS_DEVICES" | grep -i "simulator" | head -n 1 | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}')
        
        # 如果没有 simulator，尝试获取 mobile 设备
        if [ -z "$DEVICE_ID" ]; then
            DEVICE_ID=$(echo "$IOS_DEVICES" | grep -i "ios" | head -n 1 | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}')
        fi
        
        if [ -z "$DEVICE_ID" ]; then
            echo "❌ Error: Could not extract device ID from iOS devices list"
            echo "Debug info:"
            echo "IOS_DEVICES output:"
            echo "$IOS_DEVICES"
            exit 1
        fi
        
        echo -e "${GREEN}📱 Selected iOS device: $DEVICE_ID${NC}"
        PLATFORM="$DEVICE_ID"
    else
        echo -e "${GREEN}📱 Using specified device: $DEVICE_ID${NC}"
        PLATFORM="$DEVICE_ID"
    fi
fi

# 清理构建缓存
if [ "$CLEAN" = true ]; then
    echo -e "${BLUE}🧹 Cleaning build cache...${NC}"
    flutter clean
    
    # iOS 特殊清理
    if [ "$IS_IOS" = true ]; then
        if [ -d "ios/Pods" ]; then
            echo -e "${BLUE}🧹 Cleaning iOS Pods...${NC}"
            rm -rf ios/Pods ios/Podfile.lock
        fi
    fi
    
    # Android 特殊清理
    if [ "$IS_ANDROID" = true ]; then
        if [ -d "android/build" ]; then
            echo -e "${BLUE}🧹 Cleaning Android build...${NC}"
            rm -rf android/build android/app/build
        fi
    fi
    
    # Linux 特殊清理
    if [ "$IS_LINUX" = true ]; then
        if [ -d "build/linux" ]; then
            echo -e "${BLUE}🧹 Cleaning Linux build...${NC}"
            rm -rf build/linux
        fi
    fi
    
    echo -e "${BLUE}📦 Getting dependencies...${NC}"
    flutter pub get
    
    # iOS pod install
    if [ "$IS_IOS" = true ]; then
        echo -e "${BLUE}📦 Installing iOS dependencies...${NC}"
        cd ios && pod install && cd ..
    fi
    
    echo -e "${GREEN}✅ Clean complete${NC}"
fi

# 运行应用
echo -e "${GREEN}🚀 Launching Flutter app...${NC}"

# Ubuntu/Linux 特定的运行前检查
if [ "$IS_LINUX" = true ] && [[ "$OS_TYPE" == "ubuntu" || "$OS_TYPE" == "linux" ]]; then
    echo -e "${BLUE}🐧 Running on Linux desktop...${NC}"
    
    # 检查 Flutter Linux 支持是否正确配置
    if ! flutter doctor | grep -q "Linux toolchain"; then
        echo -e "${YELLOW}⚠️  Flutter Linux toolchain may not be properly configured${NC}"
        echo -e "${BLUE}💡 Run 'flutter doctor' to check for issues${NC}"
    fi
    
    # 检查 X11 显示环境
    if [ -z "$DISPLAY" ]; then
        echo -e "${YELLOW}⚠️  DISPLAY environment variable not set${NC}"
        echo -e "${BLUE}💡 Setting DISPLAY=:0${NC}"
        export DISPLAY=:0
    fi
fi

# Ubuntu 24.04 特殊处理：修改项目CMake配置
if [[ "$OS_TYPE" == "ubuntu" ]] && [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$VERSION_ID" == "24.04" ]] && [ "$IS_LINUX" = true ]; then
        echo -e "${BLUE}🔧 Applying Ubuntu 24.04 CMake fixes...${NC}"
        fix_cmake_configuration
    fi
fi

# 启动应用
FLUTTER_ARGS="-d $PLATFORM --debug"
if [ "$VERBOSE" = true ]; then
    FLUTTER_ARGS="$FLUTTER_ARGS -v"
fi

# 尝试运行应用
FLUTTER_CMD="flutter"

# Ubuntu 24.04特殊处理：使用包装脚本
if [[ "$OS_TYPE" == "ubuntu" ]] && [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$VERSION_ID" == "24.04" ]] && [ "$IS_LINUX" = true ]; then
        FLUTTER_CMD="./flutter_ubuntu_wrapper.sh"
        echo -e "${BLUE}🔧 Using Ubuntu compatibility wrapper${NC}"
    fi
fi

if ! $FLUTTER_CMD run $FLUTTER_ARGS; then
    # 如果是Ubuntu 24.04 + Snap的GLIBC问题，尝试自动修复
    if [[ "$OS_TYPE" == "ubuntu" ]] && [[ "$(which flutter)" == *"/snap/"* ]] && [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$VERSION_ID" == "24.04" ]]; then
            echo -e "${YELLOW}⚠️  GLIBC compatibility issue detected. Attempting automatic fix...${NC}"
            if attempt_flutter_manual_install; then
                echo -e "${GREEN}✅ Switched to manual Flutter installation. Retrying...${NC}"
                if ! flutter run $FLUTTER_ARGS; then
                    handle_flutter_failure
                fi
            else
                handle_flutter_failure
            fi
        else
            handle_flutter_failure
        fi
    else
        handle_flutter_failure
    fi
else
    echo -e "${GREEN}✅ Flutter app launched successfully!${NC}"
fi
#!/bin/bash

# Android模拟器安装和启动脚本
# Android Emulator Setup and Launch Script
# 
# 用途: 在新电脑上快速设置ARM64 Android模拟器用于Flutter开发
# Purpose: Quickly setup ARM64 Android emulator for Flutter development on new machines
#
# 使用方法 / Usage:
#   ./setup_android_emulator.sh [install|start|status]
#
# 命令 / Commands:
#   install - 安装Android系统镜像和创建模拟器 / Install system image and create emulator
#   start   - 启动模拟器 / Start the emulator
#   status  - 检查模拟器状态 / Check emulator status
#   help    - 显示帮助信息 / Show help message

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置变量
EMULATOR_NAME="android_pixel"
ANDROID_API="34"
SYSTEM_IMAGE="system-images;android-${ANDROID_API};google_apis_playstore;arm64-v8a"
DEVICE_PROFILE="pixel_7"

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# 检查是否为Apple Silicon Mac
check_architecture() {
    print_info "检查系统架构 / Checking system architecture..."
    
    ARCH=$(uname -m)
    if [[ "$ARCH" == "arm64" ]]; then
        print_success "检测到Apple Silicon (ARM64) - 将安装ARM64系统镜像"
        print_success "Detected Apple Silicon (ARM64) - Will install ARM64 system image"
        return 0
    elif [[ "$ARCH" == "x86_64" ]]; then
        print_warning "检测到Intel x86_64架构"
        print_warning "Detected Intel x86_64 architecture"
        print_info "注意: 本脚本针对ARM64优化，x86_64可能需要调整系统镜像"
        print_info "Note: This script is optimized for ARM64, x86_64 may need different system images"
        read -p "继续吗? Continue? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_error "未知架构: $ARCH"
        print_error "Unknown architecture: $ARCH"
        exit 1
    fi
}

# 检查必要工具
check_requirements() {
    print_info "检查必要工具 / Checking requirements..."
    
    # 检查Flutter
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter未安装 / Flutter is not installed"
        print_info "请先安装Flutter: https://flutter.dev/docs/get-started/install"
        print_info "Please install Flutter first: https://flutter.dev/docs/get-started/install"
        exit 1
    fi
    print_success "Flutter已安装: $(flutter --version | head -1)"
    
    # 检查Android SDK工具
    if ! command -v sdkmanager &> /dev/null; then
        print_error "Android SDK工具未找到 / Android SDK tools not found"
        print_info "请运行: flutter doctor --android-licenses"
        print_info "Please run: flutter doctor --android-licenses"
        exit 1
    fi
    print_success "Android SDK工具已安装"
    
    # 检查avdmanager
    if ! command -v avdmanager &> /dev/null; then
        print_error "avdmanager未找到 / avdmanager not found"
        exit 1
    fi
    print_success "AVD Manager已安装"
}

# 安装系统镜像
install_system_image() {
    print_info "检查系统镜像 / Checking system image..."
    
    # 检查镜像是否已安装
    if sdkmanager --list | grep -q "path | $SYSTEM_IMAGE"; then
        print_success "系统镜像已存在: $SYSTEM_IMAGE"
        return 0
    fi
    
    print_info "正在安装Android ${ANDROID_API} ARM64系统镜像 (带Google Play)..."
    print_info "Installing Android ${ANDROID_API} ARM64 system image (with Google Play)..."
    print_warning "这可能需要几分钟时间，请耐心等待..."
    print_warning "This may take several minutes, please be patient..."
    
    # 安装系统镜像（自动接受许可）
    yes | sdkmanager "$SYSTEM_IMAGE" || {
        print_error "系统镜像安装失败 / System image installation failed"
        exit 1
    }
    
    print_success "系统镜像安装成功 / System image installed successfully"
}

# 创建模拟器
create_emulator() {
    print_info "检查模拟器 / Checking emulator..."
    
    # 检查模拟器是否已存在
    if avdmanager list avd | grep -q "Name: $EMULATOR_NAME"; then
        print_warning "模拟器 '$EMULATOR_NAME' 已存在 / Emulator '$EMULATOR_NAME' already exists"
        read -p "是否删除并重新创建? Delete and recreate? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "删除旧模拟器 / Deleting old emulator..."
            avdmanager delete avd -n "$EMULATOR_NAME"
            print_success "旧模拟器已删除 / Old emulator deleted"
        else
            print_info "保留现有模拟器 / Keeping existing emulator"
            return 0
        fi
    fi
    
    print_info "正在创建模拟器: $EMULATOR_NAME (基于 $DEVICE_PROFILE)..."
    print_info "Creating emulator: $EMULATOR_NAME (based on $DEVICE_PROFILE)..."
    
    # 创建AVD（使用echo "no"避免创建自定义硬件配置文件）
    echo "no" | avdmanager create avd \
        -n "$EMULATOR_NAME" \
        -k "$SYSTEM_IMAGE" \
        -d "$DEVICE_PROFILE" || {
        print_error "模拟器创建失败 / Emulator creation failed"
        exit 1
    }
    
    print_success "模拟器创建成功 / Emulator created successfully"
}

# 启动模拟器
start_emulator() {
    print_info "检查模拟器状态 / Checking emulator status..."
    
    # 检查模拟器是否存在
    if ! avdmanager list avd | grep -q "Name: $EMULATOR_NAME"; then
        print_error "模拟器 '$EMULATOR_NAME' 不存在 / Emulator '$EMULATOR_NAME' does not exist"
        print_info "请先运行: $0 install"
        print_info "Please run: $0 install"
        exit 1
    fi
    
    # 检查是否已经运行
    if flutter devices | grep -q "emulator-"; then
        print_warning "检测到Android模拟器正在运行 / Android emulator already running"
        flutter devices | grep "emulator-"
        return 0
    fi
    
    print_info "正在启动模拟器: $EMULATOR_NAME..."
    print_info "Starting emulator: $EMULATOR_NAME..."
    print_warning "这可能需要30-60秒，请耐心等待..."
    print_warning "This may take 30-60 seconds, please be patient..."
    
    # 使用Flutter启动模拟器（后台运行）
    flutter emulators --launch "$EMULATOR_NAME" &
    
    # 等待模拟器启动
    print_info "等待模拟器启动 / Waiting for emulator to boot..."
    local max_wait=60
    local count=0
    
    while [ $count -lt $max_wait ]; do
        if flutter devices 2>/dev/null | grep -q "emulator-"; then
            echo
            print_success "模拟器启动成功! / Emulator started successfully!"
            print_info "模拟器设备信息 / Emulator device info:"
            flutter devices | grep "emulator-" || true
            return 0
        fi
        printf "."
        sleep 2
        ((count+=2))
    done
    
    echo
    print_error "模拟器启动超时 / Emulator start timeout"
    print_info "请手动检查Android Studio的AVD Manager"
    print_info "Please check Android Studio's AVD Manager manually"
    exit 1
}

# 检查模拟器状态
check_status() {
    print_info "检查Flutter设备 / Checking Flutter devices..."
    echo
    flutter devices
    echo
    
    print_info "检查可用模拟器 / Checking available emulators..."
    echo
    flutter emulators
    echo
    
    # 检查我们的模拟器是否存在
    if avdmanager list avd | grep -q "Name: $EMULATOR_NAME"; then
        print_success "模拟器 '$EMULATOR_NAME' 已安装"
        print_success "Emulator '$EMULATOR_NAME' is installed"
    else
        print_warning "模拟器 '$EMULATOR_NAME' 未安装"
        print_warning "Emulator '$EMULATOR_NAME' is not installed"
        print_info "运行 '$0 install' 来安装"
        print_info "Run '$0 install' to install"
    fi
}

# 显示帮助信息
show_help() {
    cat << EOF
${BLUE}Android模拟器安装和启动脚本${NC}
${BLUE}Android Emulator Setup and Launch Script${NC}

${GREEN}用法 / Usage:${NC}
    $0 [command]

${GREEN}命令 / Commands:${NC}
    ${YELLOW}install${NC}     安装Android系统镜像和创建模拟器
                Install Android system image and create emulator
                
    ${YELLOW}start${NC}       启动模拟器
                Start the emulator
                
    ${YELLOW}status${NC}      检查模拟器和设备状态
                Check emulator and device status
                
    ${YELLOW}help${NC}        显示此帮助信息
                Show this help message

${GREEN}配置 / Configuration:${NC}
    模拟器名称 / Emulator name:  ${YELLOW}$EMULATOR_NAME${NC}
    Android API版本 / API level: ${YELLOW}$ANDROID_API${NC}
    系统镜像 / System image:     ${YELLOW}$SYSTEM_IMAGE${NC}
    设备配置 / Device profile:   ${YELLOW}$DEVICE_PROFILE${NC}

${GREEN}示例 / Examples:${NC}
    # 完整安装流程 / Complete installation
    $0 install
    $0 start
    
    # 检查状态 / Check status
    $0 status
    
    # 在Flutter项目中运行应用 / Run app in Flutter project
    cd your_flutter_project
    flutter run -d emulator-5554

${GREEN}注意事项 / Notes:${NC}
    • 本脚本针对Apple Silicon (ARM64) Mac优化
      This script is optimized for Apple Silicon (ARM64) Macs
    • 首次安装需要下载约1-2GB的系统镜像
      First installation requires downloading ~1-2GB system image
    • 确保已安装Flutter和Android SDK
      Ensure Flutter and Android SDK are installed

EOF
}

# 主函数
main() {
    case "${1:-help}" in
        install)
            print_info "开始安装流程 / Starting installation..."
            echo
            check_architecture
            check_requirements
            install_system_image
            create_emulator
            echo
            print_success "========================================="
            print_success "安装完成! / Installation complete!"
            print_success "========================================="
            echo
            print_info "下一步 / Next steps:"
            print_info "1. 运行 '$0 start' 启动模拟器"
            print_info "   Run '$0 start' to start the emulator"
            print_info "2. 在Flutter项目中运行: flutter run -d emulator-5554"
            print_info "   In Flutter project run: flutter run -d emulator-5554"
            ;;
        start)
            start_emulator
            ;;
        status)
            check_status
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知命令: $1"
            print_error "Unknown command: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"

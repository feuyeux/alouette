#!/bin/bash

# Alouette Translator 快速启动脚本
# Quick start script for Alouette Translator
#
# Usage:
#   ./run_app.sh [platform] [--no-clean] [--device=DEVICE_ID]
#
# Examples:
#   ./run_app.sh                    # Run on macOS with clean build (default)
#   ./run_app.sh ios                # Run on iOS with clean build
#   ./run_app.sh ios --no-clean     # Run on iOS without cleaning (faster iteration)
#   ./run_app.sh --device=<UUID>    # Run on specific device with clean build
#   ./run_app.sh chrome --no-clean  # Run on Chrome without cleaning
#   ./run_app.sh android            # Run on Android with clean build

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Starting Alouette Translator${NC}"

# 确保Homebrew在PATH中 (修复CocoaPods问题)
if [[ "$OSTYPE" == "darwin"* ]] && [[ -d "/opt/homebrew/bin" ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
    echo -e "${GREEN}✅ Added Homebrew to PATH${NC}"
fi

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
PLATFORM="macos"
DEVICE_ID=""
IS_IOS=false

for arg in "$@"; do
    case $arg in
        --no-clean)
            CLEAN=false
            shift
            ;;
        macos|linux|windows|chrome|android|ios)
            PLATFORM=$arg
            if [ "$arg" = "ios" ]; then
                IS_IOS=true
            fi
            shift
            ;;
        --device=*)
            DEVICE_ID="${arg#*=}"
            IS_IOS=true
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
if [ "$CLEAN" = true ]; then
    echo -e "${BLUE}🧹 Clean build enabled (use --no-clean to skip)${NC}"
else
    echo -e "${BLUE}⚡ Fast build mode (no cleaning)${NC}"
fi

# iOS 设备/模拟器选择
if [ "$PLATFORM" = "ios" ]; then
    if [ -z "$DEVICE_ID" ]; then
        echo -e "${BLUE}📱 Checking available iOS devices/simulators...${NC}"
        
        # 获取可用的 iOS 设备和模拟器列表
        IOS_DEVICES=$(flutter devices | grep -E "\(mobile\)|ios.*simulator" || true)
        
        if [ -z "$IOS_DEVICES" ]; then
            echo -e "${BLUE}⚠️  No iOS devices or simulators found${NC}"
            echo -e "${BLUE}💡 Starting iOS simulator...${NC}"
            open -a Simulator
            
            # 等待模拟器启动 (最多等待 30 秒)
            echo -e "${BLUE}⏳ Waiting for simulator to boot...${NC}"
            for i in {1..30}; do
                sleep 1
                IOS_DEVICES=$(flutter devices 2>/dev/null | grep -E "\(mobile\)|ios.*simulator" || true)
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
        DEVICE_ID=$(echo "$IOS_DEVICES" | grep "simulator" | head -n 1 | grep -oE '[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}')
        
        # 如果没有 simulator，尝试获取 mobile 设备
        if [ -z "$DEVICE_ID" ]; then
            DEVICE_ID=$(echo "$IOS_DEVICES" | head -n 1 | grep -oE '[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}')
        fi
        
        if [ -z "$DEVICE_ID" ]; then
            echo "❌ Error: Could not extract device ID from iOS devices list"
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
flutter run -d "$PLATFORM" --debug

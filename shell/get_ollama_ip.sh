#!/bin/bash

# Ollama服务IP地址获取脚本
# Ollama Service IP Address Detection Script
#
# 用途: 自动检测Ollama服务的IP地址,用于配置Flutter应用
# Purpose: Automatically detect Ollama service IP address for Flutter app configuration
#
# 使用方法 / Usage:
#   ./get_ollama_ip.sh [options]
#
# 选项 / Options:
#   --port PORT    指定Ollama端口 (默认: 11434)
#   --export       输出为环境变量格式
#   --json         输出为JSON格式
#   --check        检查服务是否可访问
#   --help         显示帮助信息

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 默认配置
OLLAMA_PORT="${OLLAMA_PORT:-11434}"
OUTPUT_FORMAT="text"
CHECK_SERVICE=false

# 打印函数
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}" >&2
}

print_error() {
    echo -e "${RED}❌ $1${NC}" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" >&2
}

# 显示帮助
show_help() {
    cat << EOF
${BLUE}Ollama服务IP地址检测脚本${NC}
${BLUE}Ollama Service IP Detection Script${NC}

${GREEN}用法 / Usage:${NC}
    $0 [options]

${GREEN}选项 / Options:${NC}
    ${YELLOW}--port PORT${NC}      指定Ollama端口 (默认: 11434)
                       Specify Ollama port (default: 11434)
                       
    ${YELLOW}--export${NC}         输出为环境变量格式
                       Output as environment variable format
                       
    ${YELLOW}--json${NC}           输出为JSON格式
                       Output as JSON format
                       
    ${YELLOW}--check${NC}          检查服务是否可访问
                       Check if service is accessible
                       
    ${YELLOW}--help${NC}           显示此帮助信息
                       Show this help message

${GREEN}示例 / Examples:${NC}
    # 基本使用 - 获取IP地址
    $0
    
    # 指定端口
    $0 --port 11435
    
    # 导出为环境变量
    $0 --export
    eval \$($0 --export)
    
    # JSON格式输出
    $0 --json
    
    # 检查服务可访问性
    $0 --check

${GREEN}用途场景 / Use Cases:${NC}
    • Flutter应用配置Ollama服务器地址
    • CI/CD环境自动配置
    • 开发环境快速设置
    • 服务健康检查

EOF
}

# 解析参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --port)
                OLLAMA_PORT="$2"
                shift 2
                ;;
            --export)
                OUTPUT_FORMAT="export"
                shift
                ;;
            --json)
                OUTPUT_FORMAT="json"
                shift
                ;;
            --check)
                CHECK_SERVICE=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                print_error "未知选项: $1"
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 检测本地IP地址
get_local_ip() {
    local ip=""
    
    # 方法1: 优先使用活动的网络接口
    if command -v ifconfig &> /dev/null; then
        # macOS/BSD风格
        ip=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')
    elif command -v ip &> /dev/null; then
        # Linux风格
        ip=$(ip addr show | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}' | cut -d'/' -f1)
    fi
    
    # 方法2: 如果上述方法失败,尝试通过路由获取
    if [[ -z "$ip" ]]; then
        if command -v route &> /dev/null; then
            # 通过默认路由获取主网络接口
            local main_interface=$(route get default 2>/dev/null | grep interface | awk '{print $2}')
            if [[ -n "$main_interface" ]]; then
                ip=$(ifconfig "$main_interface" 2>/dev/null | grep "inet " | awk '{print $2}')
            fi
        fi
    fi
    
    # 方法3: 通过连接外部地址获取本地IP
    if [[ -z "$ip" ]]; then
        if command -v python3 &> /dev/null; then
            ip=$(python3 -c "import socket; s=socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.connect(('8.8.8.8', 80)); print(s.getsockname()[0]); s.close()" 2>/dev/null)
        fi
    fi
    
    echo "$ip"
}

# 获取所有本地IP地址
get_all_local_ips() {
    local ips=()
    
    if command -v ifconfig &> /dev/null; then
        # macOS/BSD风格
        while IFS= read -r line; do
            [[ -n "$line" ]] && ips+=("$line")
        done < <(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}')
    elif command -v ip &> /dev/null; then
        # Linux风格
        while IFS= read -r line; do
            [[ -n "$line" ]] && ips+=("$line")
        done < <(ip addr show | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | cut -d'/' -f1)
    fi
    
    printf '%s\n' "${ips[@]}"
}

# 检查Ollama服务是否运行
check_ollama_service() {
    local ip="$1"
    local port="$2"
    local url="http://${ip}:${port}/api/tags"
    
    if command -v curl &> /dev/null; then
        if curl -s --connect-timeout 2 "$url" > /dev/null 2>&1; then
            return 0
        fi
    elif command -v wget &> /dev/null; then
        if wget -q --timeout=2 --spider "$url" 2>/dev/null; then
            return 0
        fi
    fi
    
    return 1
}

# 主检测逻辑
detect_ollama_ip() {
    local primary_ip=$(get_local_ip)
    
    if [[ -z "$primary_ip" ]]; then
        print_error "无法检测到本地IP地址"
        print_error "Failed to detect local IP address"
        exit 1
    fi
    
    print_info "检测到主要IP地址: $primary_ip" >&2
    
    # 如果需要检查服务
    if [[ "$CHECK_SERVICE" == "true" ]]; then
        print_info "检查Ollama服务 (端口: $OLLAMA_PORT)..." >&2
        
        # 首先检查localhost
        if check_ollama_service "localhost" "$OLLAMA_PORT"; then
            print_success "Ollama服务运行在 localhost:$OLLAMA_PORT" >&2
            primary_ip="localhost"
        elif check_ollama_service "$primary_ip" "$OLLAMA_PORT"; then
            print_success "Ollama服务运行在 $primary_ip:$OLLAMA_PORT" >&2
        else
            print_warning "无法连接到Ollama服务,但IP地址有效" >&2
            print_warning "Cannot connect to Ollama service, but IP is valid" >&2
            
            # 尝试检查所有IP
            print_info "尝试检查所有网络接口..." >&2
            local found=false
            while IFS= read -r ip; do
                if check_ollama_service "$ip" "$OLLAMA_PORT"; then
                    print_success "找到Ollama服务: $ip:$OLLAMA_PORT" >&2
                    primary_ip="$ip"
                    found=true
                    break
                fi
            done < <(get_all_local_ips)
            
            if [[ "$found" == "false" ]]; then
                print_warning "提示: 确保Ollama服务正在运行" >&2
                print_warning "Hint: Make sure Ollama service is running" >&2
                print_info "启动命令: OLLAMA_HOST=0.0.0.0:$OLLAMA_PORT ollama serve" >&2
            fi
        fi
    fi
    
    # 根据格式输出
    case $OUTPUT_FORMAT in
        export)
            echo "export OLLAMA_HOST=\"http://${primary_ip}:${OLLAMA_PORT}\""
            echo "export OLLAMA_IP=\"${primary_ip}\""
            echo "export OLLAMA_PORT=\"${OLLAMA_PORT}\""
            ;;
        json)
            cat << JSON
{
  "ip": "${primary_ip}",
  "port": ${OLLAMA_PORT},
  "url": "http://${primary_ip}:${OLLAMA_PORT}",
  "api_url": "http://${primary_ip}:${OLLAMA_PORT}/api"
}
JSON
            ;;
        text|*)
            echo "${primary_ip}"
            ;;
    esac
}

# 显示详细信息
show_details() {
    print_info "=== Ollama配置信息 / Ollama Configuration ===" >&2
    echo >&2
    
    local primary_ip=$(get_local_ip)
    local ollama_url="http://${primary_ip}:${OLLAMA_PORT}"
    
    print_info "主要IP地址 / Primary IP:" >&2
    echo "  ${primary_ip}" >&2
    echo >&2
    
    print_info "Ollama服务URL / Ollama Service URL:" >&2
    echo "  ${ollama_url}" >&2
    echo >&2
    
    print_info "所有本地IP地址 / All Local IPs:" >&2
    while IFS= read -r ip; do
        local status=""
        if check_ollama_service "$ip" "$OLLAMA_PORT"; then
            status="${GREEN}[可访问/Accessible]${NC}"
        else
            status="${YELLOW}[未检测/Not detected]${NC}"
        fi
        echo -e "  ${ip}:${OLLAMA_PORT} ${status}" >&2
    done < <(get_all_local_ips)
    echo >&2
    
    print_info "Flutter应用配置示例 / Flutter App Config:" >&2
    cat << CONFIG >&2
  final config = LLMConfig(
    provider: 'ollama',
    serverUrl: '${ollama_url}',
    selectedModel: 'llama3.2',
  );
CONFIG
    echo >&2
    
    print_info "环境变量设置 / Environment Variables:" >&2
    echo "  export OLLAMA_HOST=\"${ollama_url}\"" >&2
    echo >&2
}

# 主函数
main() {
    parse_args "$@"
    
    # 如果只是简单获取IP,直接输出
    if [[ "$OUTPUT_FORMAT" == "text" ]] && [[ "$CHECK_SERVICE" == "false" ]]; then
        detect_ollama_ip
    else
        detect_ollama_ip
        
        # 如果检查了服务,显示详细信息
        if [[ "$CHECK_SERVICE" == "true" ]] && [[ "$OUTPUT_FORMAT" == "text" ]]; then
            echo >&2
            show_details
        fi
    fi
}

# 执行主函数
main "$@"

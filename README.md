# Alouette - AI翻译与朗读工具

基于 **Tauri v2 + Vue 3 + Rust** 构建的跨平台翻译和语音合成应用，支持远程Ollama AI服务器，可在桌面和移动设备上使用。

![Alouette Logo](src/assets/alouette_circle_small.png)

## ✨ 主要功能

### 🌍 多语言翻译
- **支持11种语言**: 英语、日语、韩语、法语、德语、西班牙语、俄语、意大利语、印地语、希腊语、阿拉伯语
- **远程AI翻译**: 支持连接远程Ollama服务器进行翻译
- **动态模型选择**: 自动获取服务器可用模型列表
- **一键全选**: 快速选择所有语言进行批量翻译
- **实时计数器**: 显示已选择语言数量

### 🔊 文本转语音 (TTS)
- **多语言语音合成**: 支持所有翻译语言的语音播放
- **播放全部功能**: 一键播放原文和所有翻译结果
- **智能回退机制**: 不支持的语言自动使用英语语音
- **播放状态指示**: 实时显示播放状态和动画效果

### ⚙️ 服务器配置
- **远程Ollama支持**: 配置远程AI服务器地址
- **连接测试**: 实时测试服务器连接状态
- **模型管理**: 动态获取和选择可用AI模型
- **设置持久化**: 自动保存配置信息

### 📱 移动端支持
- **响应式设计**: 完美适配手机和平板设备
- **移动端构建**: 支持Android和iOS应用构建
- **触控优化**: 针对触摸设备优化的界面
- **跨平台**: 一套代码多平台运行

### 🎨 用户界面
- **现代化设计**: 清爽的卡片式布局
- **响应式界面**: 适配不同屏幕尺寸
- **动画效果**: 流畅的按钮动画和状态转换
- **配置界面**: 直观的设置面板

## 🚀 快速开始

### 环境要求
- **Node.js**: 18+
- **Rust**: 1.70+
- **Ollama服务器**: 本地或远程Ollama服务
- **espeak**: 用于本地TTS (Linux)

### � 移动端支持
- **Android**: Android Studio + Android SDK
- **iOS**: Xcode + iOS SDK (仅限macOS)

### �🐧 Linux (Ubuntu/Debian) 安装
```bash
# 1. 安装系统依赖
sudo apt update && sudo apt install -y \
  libwebkit2gtk-4.1-dev \
  libjavascriptcoregtk-4.1-dev \
  libgtk-3-dev \
  libsoup-3.0-dev \
  libssl-dev \
  libayatana-appindicator3-dev \
  librsvg2-dev \
  espeak espeak-data

# 2. 安装项目依赖
npm install

# 3. 运行应用
npm run dev
```

### 🍎 macOS 安装
```bash
# 1. 安装 Xcode 命令行工具
xcode-select --install

# 2. 安装 Homebrew (如果尚未安装)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3. 安装依赖
brew install espeak
npm install

# 4. 安装Ollama
brew install espeak
npm install

# 4. 运行应用
npm run dev
```

### 🪟 Windows 安装
```bash
# 1. 安装 Visual Studio Build Tools
# 下载并安装: https://visualstudio.microsoft.com/visual-cpp-build-tools/

# 2. 安装依赖
npm install

# 3. 运行应用
npm run dev
```

## 📦 构建命令

```bash
# 桌面端开发和构建
npm run dev              # 启动桌面应用开发模式
npm run build            # 构建桌面应用

# 移动端构建 (需要先安装相应SDK)
npm run build:android    # 构建Android APK
npm run build:ios        # 构建iOS应用 (仅限macOS)
npm run dev:android      # Android开发模式
npm run dev:ios          # iOS开发模式
```

## ⚙️ Ollama服务器配置

### 🔧 首次设置
1. 启动应用后，点击右上角的 **"⚙️ 设置"** 按钮
2. 在设置面板中输入Ollama服务器地址：
   - 本地服务器: `http://localhost:11434`
   - 局域网服务器: `http://192.168.1.100:11434`
   - 远程服务器: `https://your-domain.com:11434`
3. 点击 **"测试连接"** 验证服务器可用性
4. 从下拉列表中选择要使用的AI模型
5. 点击 **"保存设置"** 完成配置


### 📱 移动端使用建议
- 使用轻量级模型以获得更快响应速度
- 确保稳定的网络连接
- 推荐在同一局域网内使用以降低延迟
- 可配置多个服务器地址便于切换

## 🔧 配置说明

### 推荐模型配置

| 模型名称 | 大小 | 适用场景 | 性能 |
|---------|------|----------|------|
| `qwen2:1.5b` | 1.5GB | 移动端/轻量级 | 快速响应 |
| `llama3.2:1b` | 1GB | 极轻量 | 超快响应 |
| `qwen2:7b` | 4GB | 桌面端/平衡 | 高质量翻译 |
| `qwen2:14b` | 8GB | 服务器/高性能 | 最佳质量 |

```bash
# 检查服务器连接
curl http://your-server:11434/api/tags

# 测试翻译
curl -X POST http://your-server:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model": "qwen2:1.5b", "prompt": "Translate \"你好\" to English: ", "stream": false}'
```


## 🏗️ 技术架构

### 前端技术栈
- **Vue 3.5**: 响应式UI框架
- **Vite 6**: 快速构建工具  
- **CSS3**: 现代样式和动画，支持响应式设计

### 后端技术栈
- **Tauri 2.2**: 跨平台应用框架
- **Rust**: 高性能后端语言
- **Reqwest**: HTTP客户端，用于连接Ollama服务器
- **Serde**: 数据序列化和反序列化

### AI服务
- **Ollama**: AI模型推理服务器
- **支持模型**: Qwen2、Llama3.2、Phi3等多种开源模型
- **远程部署**: 支持本地和云端部署

### 语音合成
- **espeak**: Linux文本转语音引擎
- **系统TTS**: 跨平台语音合成支持

### 支持平台
- ✅ **桌面端**: Linux (x64, ARM64), Windows (x64, ARM64), macOS (Intel, Apple Silicon)
- ✅ **移动端**: Android (ARM64, x86_64), iOS (ARM64)


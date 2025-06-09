# Alouette - AI翻译与朗读工具

基于 **Tauri v2 + Vue 3 + Rust** 构建的跨平台翻译和语音合成应用，使用本地Ollama AI模型进行翻译，支持多语言翻译和文本转语音功能。

![Alouette Logo](src-tauri/icons/128x128@2x.png)

## ✨ 主要功能

### 🌍 多语言翻译
- **支持11种语言**: 英语、日语、韩语、法语、德语、西班牙语、俄语、意大利语、印地语、希腊语、阿拉伯语
- **一键全选**: 快速选择所有语言进行批量翻译
- **实时计数器**: 显示已选择语言数量
- **本地AI翻译**: 使用本地Ollama AI模型 (qwen3) 进行离线翻译

### 🔊 文本转语音 (TTS)
- **多语言语音合成**: 支持所有翻译语言的语音播放
- **播放全部功能**: 一键播放原文和所有翻译结果
- **智能回退机制**: 不支持的语言自动使用英语语音
- **智能按钮布局**: 播放按钮与文本在同一行，不占用额外空间
- **系统TTS引擎**: 使用系统espeak引擎提供高质量语音
- **播放状态指示**: 实时显示播放状态和动画效果

### 🎨 用户界面
- **现代化设计**: 清爽的卡片式布局
- **响应式界面**: 适配不同屏幕尺寸
- **动画效果**: 流畅的按钮动画和状态转换
- **优化布局**: 播放按钮与标题并排显示，节省空间

## 🚀 快速开始

### 环境要求
- **Node.js**: 18+
- **Rust**: 1.70+
- **Ollama**: 用于本地AI翻译
- **espeak**: 用于本地TTS (Linux)

### 🐧 Linux (Ubuntu/Debian) 安装
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

# 2. 安装Ollama
curl -fsSL https://ollama.ai/install.sh | sh
ollama pull qwen3:4b

# 3. 安装项目依赖
npm install

# 4. 运行Tauri桌面应用
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
brew install ollama
ollama pull qwen3:4b

# 5. 运行Tauri桌面应用
npm run dev
```

### 🪟 Windows 安装
```bash
# 1. 安装 Visual Studio Build Tools
# 下载并安装: https://visualstudio.microsoft.com/visual-cpp-build-tools/

# 2. 安装依赖
npm install

# 3. 安装Ollama
# 下载并安装: https://ollama.ai/download
ollama pull qwen3:4b

# 4. 运行Tauri桌面应用
npm run dev
```

## 📦 构建命令

```bash
# 开发
npm run dev              # 启动Tauri桌面应用开发模式

# 构建
npm run build            # 构建Tauri桌面应用
```

## 🔧 配置说明

### Ollama配置 (本地AI翻译)
```bash
# 检查Ollama状态
ollama list

# 下载推荐模型
ollama pull qwen3:4b

# 测试翻译
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model": "qwen3:4b", "prompt": "Translate \"你好\" to English: ", "stream": false}'
```


## 🎯 使用方法

### 基本翻译流程
1. **输入文本**: 在文本框中输入要翻译的内容
2. **选择语言**: 
   - 单独勾选需要的目标语言
   - 或点击"全选"选择所有语言
3. **开始翻译**: 点击"开始翻译"按钮
4. **查看结果**: 在结果区域查看翻译内容
5. **语音播放**: 
   - 点击🔊按钮播放单个语音
   - 点击"🔊 播放全部"按钮依次播放原文和所有翻译结果

### Tauri + Ollama 架构
- **本地AI翻译**: 使用 Ollama qwen3:4b 模型进行离线翻译
- **系统TTS引擎**: 使用系统原生TTS引擎，Linux使用espeak
- **隐私保护**: 所有翻译和语音处理都在本地进行
- **桌面应用**: 仅支持Tauri桌面模式，提供完整的本地功能


## 🏗️ 技术架构

### 前端技术栈
- **Vue 3.5**: 响应式UI框架
- **Vite 6**: 快速构建工具  
- **CSS3**: 现代样式和动画

### 后端技术栈
- **Tauri 2.2**: 跨平台应用框架
- **Rust**: 高性能后端语言
- **Ollama**: 本地AI模型推理
- **espeak**: 文本转语音引擎

### 支持平台
- ✅ **Linux** (x64, ARM64)
- ✅ **Windows** (x64, ARM64)
- ✅ **macOS** (Intel, Apple Silicon)

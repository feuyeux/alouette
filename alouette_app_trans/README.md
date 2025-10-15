# Alouette Translator

A cross-platform translation application built with Flutter, supporting AI-powered translation through local models like Ollama and LM Studio.

## Overview

Alouette Translator is a specialized translation application from the Alouette ecosystem. It provides powerful AI-powered translation capabilities with support for multiple LLM providers and batch translation to multiple languages simultaneously.

## Features

### AI Translation
- 🤖 **Local AI Translation** - Support for Ollama and LM Studio local AI models
- 🌍 **Multi-language Support** - Chinese, English, Japanese, Korean, French, German, Spanish, Italian, Russian, Arabic, Hindi, Greek
- 🔄 **Batch Translation** - Translate to multiple target languages at once
- ⚙️ **Flexible Configuration** - Custom server URL, API keys, model selection
- 📊 **Real-time Status** - Connection status, translation progress, and model information

### User Interface
- 🎨 **Modern UI** - Material 3 design with responsive layout
- 📱 **Cross-platform** - Android, iOS, Web, Windows, macOS, Linux
- 📋 **Convenient Operations** - Copy results, clear translations
- ♿ **Accessibility Support** - Screen reader and keyboard navigation

### Technical Features
- 🔧 **Error Handling** - Comprehensive error handling and user prompts
- 📂 **File Support** - Read text content from files
- 🎨 **Theme Support** - Dark/light theme with custom colors

## Quick Start

## 📖 简介 / Introduction

Alouette Translator 是一个跨平台的翻译应用程序，基于 Flutter 开发，支持通过 Ollama 和 LM Studio 等本地 AI 模型进行多语言翻译。该应用复刻了 alouette-app（Tauri 版本）的核心翻译功能，提供直观的用户界面和强大的翻译能力。

Alouette Translator is a cross-platform translation application built with Flutter, supporting AI-powered translation through local models like Ollama and LM Studio. It replicates the core translation functionality of alouette-app (Tauri version) with an intuitive user interface and powerful translation capabilities.

## ✨ 特性 / Features

### AI Translation Features

- 🤖 **本地 AI 翻译** - 支持 Ollama 和 LM Studio 本地 AI 模型
- 🌍 **多语言支持** - 支持中文、英文、日文、韩文、法文、德文、西班牙文、意大利文、俄文、阿拉伯文、印地文、希腊文
- 🔄 **批量翻译** - 一次性翻译到多个目标语言
- ⚙️ **灵活配置** - 支持自定义服务器 URL、API 密钥、模型选择
- 📊 **实时状态** - 显示连接状态、翻译进度和模型信息

### User Interface

- 🎨 **现代化 UI** - Material 3 设计，响应式布局
- � **跨平台** - 支持 Android、iOS、Web、Windows、macOS、Linux
- 📋 **便捷操作** - 支持复制翻译结果、清除结果等操作
- ♿ **无障碍支持** - 支持屏幕阅读器和键盘导航

### Technical Features

- 🔊 **语音合成** - 集成 TTS 功能（继承自原项目）
- �️ **语音控制** - 调节语速、音量、音调等参数
- 📂 **文件支持** - 支持从文件读取文本内容
- 🔧 **错误处理** - 完善的错误处理和用户提示

## 🚀 快速开始 / Quick Start

### Prerequisites

- Flutter SDK 3.8.1+
- Dart SDK 3.0.0+
- **Ollama or LM Studio** (for AI translation functionality)

### AI Model Setup

#### Ollama Setup

1. Install Ollama: https://ollama.ai
2. Start Ollama service: `ollama serve`
3. Download model: `ollama pull llama3.2` or other supported models
4. Configure external access (optional):

   ```bash
   # 创建 systemd override 目录
   sudo mkdir -p /etc/systemd/system/ollama.service.d

   # 创建 override 配置
   sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null <<EOF
   [Service]
   Environment="OLLAMA_HOST=0.0.0.0:11434"
   EOF

   # 重新加载并重启服务
   sudo systemctl daemon-reload
   sudo systemctl restart ollama
   ```

#### LM Studio Setup

1. Install LM Studio: https://lmstudio.ai
2. Load a model in LM Studio
3. Start local server from the server tab

### Installation

1. **Navigate to the app directory**
   ```bash
   cd alouette_app_trans
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   # Desktop
   flutter run -d windows  # or macos, linux
   
   # Mobile
   flutter run -d android  # or ios
   
   # Web
   flutter run -d chrome
   ```

## Configuration

### LLM Server Configuration

1. Launch the app and click the **"⚙️ Settings"** button
2. Select LLM provider (Ollama or LM Studio)
3. Enter server URL:
   - Ollama local: `http://localhost:11434`
   - LM Studio local: `http://localhost:1234`
   - Remote server: `http://your-ip:port`
4. Enter API key if needed
5. Click **"Test Connection"** to verify configuration
6. Select an available model
7. Save configuration

### Supported Models

The application supports various language models compatible with Ollama and LM Studio, including:

- Llama series (llama3.2, llama3.1, etc.)
- Qwen series
- Mistral series
- Other OpenAI-compatible models

## Usage

1. **Enter text** in the input area
2. **Select target languages** from the grid selector
3. **Click Translate** to process the text
4. **Copy results** or use them for further processing

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

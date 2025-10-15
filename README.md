# Alouette

A comprehensive Flutter ecosystem for AI-powered translation and text-to-speech functionality, built with a modular architecture that eliminates code duplication and follows Flutter best practices.

## 📺 Demo

<div align="center">
  <a href="https://www.bilibili.com/video/BV14y4tz3EKr/">
    <img src="https://i0.hdslb.com/bfs/archive/placeholder.jpg" alt="Alouette Demo Video" width="600">
  </a>
  <br>
  <strong><a href="https://www.bilibili.com/video/BV14y4tz3EKr/">🎬 Click to Watch Demo Video</a></strong>
</div>

<!-- Bilibili 嵌入播放器 (在支持 iframe 的环境中显示) -->
<div align="center">
  <iframe src="//player.bilibili.com/player.html?bvid=BV14y4tz3EKr&page=1&high_quality=1&danmaku=0" 
          scrolling="no" 
          border="0" 
          frameborder="no" 
          framespacing="0" 
          allowfullscreen="true" 
          width="600" 
          height="450"
          style="max-width: 100%;">
  </iframe>
</div>

## 🏗️ Architecture Overview

Alouette follows a layered architecture with clear separation of concerns:

```sh
Applications Layer
├── alouette_app (Combined functionality)
├── alouette_app_trans (Translation specialist)
└── alouette_app_tts (TTS specialist)

Library Layer
├── alouette_lib_trans (Translation services)
├── alouette_lib_tts (TTS services)
└── alouette_ui (UI components & services)

Platform Layer
├── Edge TTS (Desktop platforms)
├── Flutter TTS (Mobile/Web platforms)
└── LLM Providers (Ollama, LM Studio)
```

## 🌐 Supported Languages

Alouette supports 12+ languages with high-quality neural voices

1. 🇨🇳 **中文** Chinese (zh-CN): 这是中文语音合成技术的演示。
2. 🇺🇸 **English** (en-US): This is a demonstration of TTS in English.
3. 🇩🇪 **Deutsch** German (de-DE): Dies ist eine Demonstration der deutschen Sprachsynthese-Technologie.
4. 🇫🇷 **Français** French (fr-FR): Ceci est une démonstration de la technologie de synthèse vocale française.
5. 🇪🇸 **Español** Spanish (es-ES): Esta es una demostración de la tecnología de síntesis de voz en español.
6. 🇮🇹 **Italiano** Italian (it-IT): Questa è una dimostrazione della tecnologia di sintesi vocale italiana.
7. 🇷🇺 **Русский** Russian (ru-RU): Это демонстрация технологии синтеза речи на русском языке.
8. 🇬🇷 **Ελληνικά** Greek (el-GR): Αυτή είναι μια επίδειξη της τεχνολογίας σύνθεσης ομιλίας στα ελληνικά.
9. 🇸🇦 **العربية** Arabic (ar-SA): هذا عرض توضيحي لتقنية تحويل النص إلى كلام باللغة العربية.
10. 🇮🇳 **हिन्दी** Hindi (hi-IN): यह हिंदी भाषा में टेक्स्ट-टू-स्पीच तकनीक का प्रदर्शन है।
11. 🇯🇵 **日本語** Japanese (ja-JP): これは日本語音声合成技術のデモンストレーションです。
12. 🇰🇷 **한국어** Korean (ko-KR): 이것은 한국어 음성 합성 기술의 시연입니다。

## 📱 Applications

### 1 alouette_app

- Full-featured application with both translation and TTS capabilities
- Unified interface for seamless workflow between translation and speech synthesis
- Ideal for users who need both functionalities

### 2 alouette_app_trans

- Focused on AI-powered translation using local LLM providers
- Supports Ollama and LM Studio for privacy-focused translation
- Batch translation to multiple languages simultaneously

### 3 alouette_app_tts

- High-quality speech synthesis with platform-specific optimization
- Edge TTS for desktop platforms, Flutter TTS for mobile/web
- Advanced voice controls and audio export capabilities

## 📚 Libraries

### 1 alouette_lib_trans

Translation Services Library

- Centralized AI translation functionality
- Support for multiple LLM providers (Ollama, LM Studio)
- Comprehensive error handling and connection management

### 2 alouette_lib_tts

Text-to-Speech Services Library

- Multi-platform TTS with automatic engine selection
- Edge TTS integration for high-quality desktop synthesis
- Flutter TTS for native mobile and web support

### 3 alouette_ui

Shared UI Components & Services Library

- Atomic design component system (atoms, molecules, organisms)
- Centralized service locator and dependency injection
- Design token system for consistent theming
- Configuration management and service orchestration

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.8.1+
- Dart SDK 3.0.0+
- For AI translation: Ollama or LM Studio
- For desktop TTS: Python 3.7+ with `edge-tts` package

### Installation

1. **Clone the repository**

   ```sh
   git clone https://github.com/feuyeux/alouette.git
   cd alouette
   ```

2. **Install dependencies for all modules**

   ```sh
   # Install dependencies for all applications and libraries
   find . -name "pubspec.yaml" -not -path "./.*" -exec dirname {} \; | xargs -I {} sh -c 'cd "{}" && flutter pub get'
   ```

3. **Set up AI translation (optional)**

   ```sh
   # Install and start Ollama
   # Visit https://ollama.ai for installation instructions
   ollama serve
   ollama pull llama3.2

   # Or install LM Studio from https://lmstudio.ai
   ```

4. **Set up Edge TTS for desktop (optional)**

   ```sh
   pip install edge-tts
   ```

### Running Applications

Each application includes platform-specific run scripts for convenience:

#### **macOS/Linux**

```bash
# Run the main combined application
cd alouette_app && ./run_app.sh

# Run the translation-focused application
cd alouette_app_trans && ./run_app.sh

# Run the TTS-focused application
cd alouette_app_tts && ./run_app.sh
```

#### **Windows (PowerShell)**

```powershell
# Run any application
cd alouette_app
.\run_app.ps1

cd alouette_app_trans
.\run_app.ps1

cd alouette_app_tts
.\run_app.ps1
```

## Acknowledgments

- [Flutter](https://flutter.dev) - Cross-platform UI framework
- [Edge TTS](https://github.com/rany2/edge-tts) - High-quality text-to-speech
- [Ollama](https://ollama.ai) - Local LLM runtime
- [LM Studio](https://lmstudio.ai) - Local LLM interface
- [Material Design 3](https://m3.material.io/) - Design system

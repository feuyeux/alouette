# Alouette TTS App

A Flutter application for high-quality text-to-speech functionality using Microsoft Edge TTS.

## Features

- 🌍 **Multilingual Support**: 12 languages with neural voices
- 🎯 **Edge TTS Integration**: High-quality Microsoft Edge TTS engine
- 🎨 **Modern UI**: Clean and intuitive user interface
- 🔄 **Real-time Synthesis**: Fast text-to-speech conversion
- 📱 **Cross-platform**: Windows, macOS, Linux, Android, iOS, Web

## Supported Languages

1. Chinese (zh-CN)
2. English (en-US)
3. German (de-DE)
4. French (fr-FR)
5. Spanish (es-ES)
6. Italian (it-IT)
7. Russian (ru-RU)
8. Greek (el-GR)
9. Arabic (ar-SA)
10. Hindi (hi-IN)
11. Japanese (ja-JP)
12. Korean (ko-KR)

## Quick Start

### Prerequisites

- Flutter SDK 3.0+
- Dart SDK 3.0+
- Python 3.7+ (for Edge TTS)
- Edge TTS package: `pip install edge-tts`

### Installation

1. **Navigate to the app directory**
   ```bash
   cd alouette_app_tts
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Install Edge TTS** (for desktop platforms)
   ```bash
   pip install edge-tts
   ```

4. **Run the application**
   ```bash
   # Desktop
   flutter run -d windows  # or macos, linux
   
   # Mobile
   flutter run -d android  # or ios
   
   # Web
   flutter run -d chrome
   ```

## Architecture

The application is built with a modular architecture:

- **alouette_app_tts**: Main Flutter application
- **alouette_lib_tts**: Core TTS library with unified API
- **alouette_ui**: Shared UI components and services
- **Edge TTS Processor**: Microsoft Edge TTS integration (desktop)
- **Flutter TTS Processor**: System TTS (mobile/web)

## Usage

1. **Launch the app**: The application will automatically initialize the TTS service
2. **Enter text**: Type or paste the text you want to convert to speech
3. **Select voice**: Choose from available voices in the dropdown
4. **Adjust settings**: Speed, pitch, volume as needed
5. **Play**: Click the play button to hear the synthesized speech

## Troubleshooting

### Common Issues

1. **"Edge TTS not available"**
   - Ensure Python is installed and in PATH
   - Install edge-tts: `pip install edge-tts`
   - Verify installation: `edge-tts --list-voices`

2. **"No voices available"**
   - Check internet connection (Edge TTS requires online access)
   - Verify Edge TTS installation
   - Try switching to Flutter TTS engine (mobile/web)

3. **Audio playback issues**
   - Ensure system audio is working
   - Check volume settings
   - Try different audio formats

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.
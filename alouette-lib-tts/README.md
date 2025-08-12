# Alouette TTS Library

A Flutter library for text-to-speech functionality used across Alouette applications. This library provides a unified, cross-platform TTS API with support for Android, iOS, Web, Windows, macOS, and Linux.

## Features

- 🎯 **Cross-platform support**: Works on Android, iOS, Web, Windows, macOS, and Linux
- 🔧 **Configurable**: Adjust speech rate, volume, pitch, and language
- 🎭 **Multiple languages**: Support for 12+ languages with proper localization
- 🛡️ **Type-safe**: Full TypeScript-style type safety with comprehensive error handling
- 🧪 **Well-tested**: Comprehensive unit tests with high coverage
- 📱 **Platform-optimized**: Platform-specific optimizations for Android audio handling

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  alouette_lib_tts: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:alouette_lib_tts/alouette_lib_tts.dart';

class MyTTSWidget extends StatefulWidget {
  @override
  _MyTTSWidgetState createState() => _MyTTSWidgetState();
}

class _MyTTSWidgetState extends State<MyTTSWidget> {
  final TTSService _ttsService = TTSService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeTTS();
  }

  Future<void> _initializeTTS() async {
    try {
      await _ttsService.initialize(
        onStart: () => print('TTS started'),
        onComplete: () => print('TTS completed'),
        onError: (error) => print('TTS error: $error'),
      );
      setState(() => _isInitialized = true);
    } catch (e) {
      print('Failed to initialize TTS: $e');
    }
  }

  Future<void> _speak() async {
    if (!_isInitialized) return;
    
    try {
      await _ttsService.speak(
        text: 'Hello, world!',
        languageCode: 'en-US',
        speechRate: 1.0,
        volume: 1.0,
        pitch: 1.0,
      );
    } catch (e) {
      print('Failed to speak: $e');
    }
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: _isInitialized ? _speak : null,
          child: Text('Speak'),
        ),
      ),
    );
  }
}
```

## Configuration

### Using TTSConfig

```dart
// Create a custom configuration
final config = TTSConfig(
  speechRate: 1.2,
  volume: 0.8,
  pitch: 1.1,
  languageCode: 'zh-CN',
  awaitCompletion: true,
);

// Initialize with custom config
await ttsService.initialize(
  onStart: () => print('Started'),
  onComplete: () => print('Completed'),
  onError: (error) => print('Error: $error'),
  config: config,
);

// Or update config later
await ttsService.updateConfig(config);
```

### Supported Languages

The library supports the following languages:

| Language Code | Language Name | Flag |
|---------------|---------------|------|
| `zh-CN` | 简体中文 | 🇨🇳 |
| `en-US` | English (US) | 🇺🇸 |
| `ja-JP` | 日本語 | 🇯🇵 |
| `ko-KR` | 한국어 | 🇰🇷 |
| `fr-FR` | Français | 🇫🇷 |
| `de-DE` | Deutsch | 🇩🇪 |
| `es-ES` | Español | 🇪🇸 |
| `it-IT` | Italiano | 🇮🇹 |
| `ru-RU` | Русский | 🇷🇺 |
| `ar-SA` | العربية | 🇸🇦 |
| `hi-IN` | हिंदी | 🇮🇳 |
| `el-GR` | Ελληνικά | 🇬🇷 |

```dart
// Get supported languages
final languages = ttsService.getSupportedLanguages();

// Get language by code
final english = ttsService.getLanguageByCode('en-US');

// Check available languages from TTS engine
final availableLanguages = await ttsService.getLanguages();
```

## API Reference

### TTSService

#### Initialization
```dart
Future<void> initialize({
  required VoidCallback onStart,
  required VoidCallback onComplete,
  required void Function(dynamic message) onError,
  TTSConfig? config,
})
```

#### Speech Control
```dart
// Speak with parameters
Future<void> speak({
  required String text,
  required String languageCode,
  required double speechRate,
  required double volume,
  required double pitch,
})

// Speak with configuration
Future<void> speakWithConfig(String text, {TTSConfig? config})

// Control playback
Future<void> stop()
Future<void> pause()
Future<void> resume()
```

#### Configuration
```dart
// Individual settings
Future<void> setSpeechRate(double rate)  // 0.0 - 2.0
Future<void> setVolume(double volume)    // 0.0 - 1.0
Future<void> setPitch(double pitch)      // 0.0 - 2.0
Future<void> setLanguage(String code)

// Bulk configuration
Future<void> updateConfig(TTSConfig config)
```

#### State Management
```dart
// Current state
TTSState get currentState
TTSConfig get currentConfig
bool get isInitialized

// State checks
bool get isSpeaking
bool get isPaused
bool get isStopped

// Current values
double getSpeechRate()
double getVolume()
double getPitch()
String getLanguageCode()
```

### TTSConfig

```dart
const TTSConfig({
  required double speechRate,    // 0.0 - 2.0
  required double volume,        // 0.0 - 1.0
  required double pitch,         // 0.0 - 2.0
  required String languageCode,
  bool awaitCompletion = true,
  Map<String, dynamic>? platformSpecific,
})

// Factory constructors
TTSConfig.defaultConfig()

// Methods
TTSConfig copyWith({...})
Map<String, dynamic> toJson()
TTSConfig.fromJson(Map<String, dynamic> json)
bool isValid()
```

### TTSState

```dart
enum TTSState {
  stopped,    // TTS is not active
  playing,    // TTS is currently speaking
  paused,     // TTS is paused
  continued,  // TTS has resumed from pause
}
```

## Error Handling

The library provides comprehensive error handling with specific exception types:

```dart
try {
  await ttsService.speak(
    text: 'Hello',
    languageCode: 'en-US',
    speechRate: 1.0,
    volume: 1.0,
    pitch: 1.0,
  );
} on TTSNotInitializedException {
  print('TTS service not initialized');
} on TTSLanguageNotSupportedException catch (e) {
  print('Language ${e.languageCode} not supported');
} on TTSConfigurationException catch (e) {
  print('Configuration error in ${e.configField}: ${e.message}');
} on TTSSpeechException catch (e) {
  print('Speech error: ${e.message}');
} on TTSPlatformException catch (e) {
  print('Platform error on ${e.platform}: ${e.message}');
} catch (e) {
  print('Unexpected error: $e');
}
```

### Exception Types

- `TTSNotInitializedException`: Service not initialized
- `TTSInitializationException`: Initialization failed
- `TTSLanguageNotSupportedException`: Unsupported language
- `TTSConfigurationException`: Invalid configuration
- `TTSSpeechException`: Speech operation failed
- `TTSPlatformException`: Platform-specific error

## Platform-Specific Notes

### Android

The library automatically configures Android audio settings for optimal TTS playback:

- Sets audio stream type to media stream
- Configures TTS engine parameters
- Provides volume information for debugging

### iOS

iOS-specific audio session management is handled automatically by the underlying `flutter_tts` plugin.

### Web

Web implementation uses the Web Speech API. Some features may be limited compared to native platforms.

### Desktop (Windows/macOS/Linux)

Desktop platforms use system TTS engines via the `flutter_tts` plugin.

## Testing

The library includes comprehensive unit tests. To run tests:

```bash
cd alouette-lib-tts
flutter test
```

Test coverage includes:
- Model serialization/deserialization
- Configuration validation
- Exception handling
- Service state management
- Constants and utilities

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This library is part of the Alouette project. See the main project for license information.

## Changelog

### 1.0.0
- Initial release
- Cross-platform TTS support
- Comprehensive error handling
- Full test coverage
- Platform-specific optimizations
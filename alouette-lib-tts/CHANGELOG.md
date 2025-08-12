# Changelog

All notable changes to the alouette-lib-tts library will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-12

### Added
- Initial release of alouette-lib-tts library
- Core TTS functionality extracted from alouette-app and alouette-tts applications
- Multi-platform support (Android, iOS, Web, Windows, macOS, Linux)
- TTSService with comprehensive API for text-to-speech operations
- TTSConfig model for configuration management
- TTSState enumeration for state tracking
- LanguageOption model for language selection
- Platform-specific implementations for optimal performance
- Comprehensive error handling with custom exceptions
- Unit tests and integration tests
- Example application demonstrating usage

### Features
- **Speech Control**: Play, pause, stop, and resume functionality
- **Voice Configuration**: Adjustable speech rate, volume, and pitch
- **Language Support**: Multi-language TTS with automatic language detection
- **State Management**: Real-time TTS state monitoring
- **Error Handling**: Graceful error handling with meaningful messages
- **Resource Management**: Proper cleanup and resource disposal

### Platform Support
- Android API 21+ with native TTS engine integration
- iOS 11.0+ with AVSpeechSynthesizer integration
- Web with Speech Synthesis API
- Windows with SAPI integration
- macOS with NSSpeechSynthesizer
- Linux with espeak/festival integration

### Dependencies
- flutter_tts: ^4.2.3 for cross-platform TTS functionality
- Flutter SDK: >=3.8.1

### Breaking Changes
- N/A (Initial release)

### Migration Guide
This is the initial release. To migrate from direct flutter_tts usage:

1. Add dependency to pubspec.yaml:
   ```yaml
   dependencies:
     alouette_lib_tts:
       path: ../alouette-lib-tts  # or version from pub.dev
   ```

2. Replace flutter_tts imports:
   ```dart
   // Before
   import 'package:flutter_tts/flutter_tts.dart';
   
   // After
   import 'package:alouette_lib_tts/alouette_lib_tts.dart';
   ```

3. Update service initialization:
   ```dart
   // Before
   FlutterTts flutterTts = FlutterTts();
   
   // After
   TTSService ttsService = TTSService();
   await ttsService.initialize(
     onStart: () => print('TTS Started'),
     onComplete: () => print('TTS Completed'),
     onError: (error) => print('TTS Error: $error'),
   );
   ```

4. Update method calls:
   ```dart
   // Before
   await flutterTts.speak("Hello World");
   await flutterTts.setSpeechRate(0.5);
   
   // After
   await ttsService.speak(
     text: "Hello World",
     languageCode: "en-US",
     speechRate: 0.5,
     volume: 1.0,
     pitch: 1.0,
   );
   ```

### Documentation
- Comprehensive README with usage examples
- API documentation for all public methods
- Platform-specific setup instructions
- Troubleshooting guide

### Known Issues
- None at this time

### Contributors
- Alouette Development Team
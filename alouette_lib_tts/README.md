# Alouette TTS Library

A multi-platform text-to-speech (TTS) library for Flutter applications, providing unified access to multiple TTS engines including Microsoft Edge TTS and Flutter's native TTS capabilities.

## Features

- **Unified API**: Consistent interface across all TTS engines
- **Multi-platform Support**: Works on Desktop (Windows, macOS, Linux), Mobile (Android, iOS), and Web
- **Automatic Engine Selection**: Intelligently chooses the best TTS engine for each platform
- **Platform-specific UI Support**: Optimized display for different platforms (emoji flags on macOS, text codes on Windows)
- **High-Quality Voices**: Access to Microsoft Edge's neural voices and system TTS voices
- **Audio File Generation**: Synthesize speech to audio files (MP3, WAV, etc.)
- **Direct Speech Playback**: Integrated `speakText` method for immediate audio playback
- **Cross-platform Audio Playback**: Built-in audio player for all platforms
- **Error Handling**: Comprehensive error handling with recovery suggestions
- **Backward Compatibility**: Maintains compatibility with existing applications

## Supported TTS Engines

### Edge TTS
- **Platforms**: Desktop (Windows, macOS, Linux)
- **Features**: High-quality neural voices, 100+ languages, offline capability after initial setup
- **Requirements**: `edge-tts` command-line tool (`pip install edge-tts`)

### Flutter TTS  
- **Platforms**: Mobile (Android, iOS), Web, Desktop (fallback)
- **Features**: Native system integration, no additional dependencies
- **Limitations**: Web platform doesn't support audio file generation

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  alouette_tts: ^1.0.0
```

### Additional Setup for Edge TTS

For desktop platforms to use Edge TTS, install the command-line tool:

```bash
pip install edge-tts
```

## Quick Start

### New Unified API (Recommended)

```dart
import 'package:alouette_tts/alouette_tts.dart';

void main() async {
  // Create and initialize the TTS service
  final ttsService = TTSService();
  await ttsService.initialize();
  
  // Get available voices
  final voices = await ttsService.getVoices();
  print('Available voices: ${voices.length}');
  
  // Synthesize text to audio data
  final audioData = await ttsService.synthesizeText(
    'Hello, this is a test of the TTS system!',
    voices.first.name,
  );
  
  // Play the audio
  final audioPlayer = AudioPlayer();
  await audioPlayer.playBytes(audioData);
  
  // Clean up
  ttsService.dispose();
}
```

### Platform-Specific Engine Selection

```dart
import 'package:alouette_tts/alouette_tts.dart';

void main() async {
  // Automatic platform-based selection
  final processor = await PlatformTTSFactory.createForPlatform();
  
  // Or manually select an engine
  final edgeProcessor = await PlatformTTSFactory.create(TTSEngineType.edge);
  final flutterProcessor = await PlatformTTSFactory.create(TTSEngineType.flutter);
  
  // Use the processor
  final voices = await processor.getVoices();
  final audioData = await processor.synthesizeText('Hello world', voices.first.name);
  
  // Clean up
  processor.dispose();
}
```

### Advanced Configuration

```dart
import 'package:alouette_tts/alouette_tts.dart';

void main() async {
  // Create TTS service with preferred engine
  final ttsService = TTSService();
  await ttsService.initialize(preferredEngine: TTSEngineType.edge);
  
  // Check current engine
  print('Current engine: ${ttsService.currentEngine}');
  
  // Switch engines at runtime
  await ttsService.switchEngine(TTSEngineType.flutter);
  
  // Filter voices by language
  final voices = await ttsService.getVoices();
  final englishVoices = voices.where((v) => v.language == 'en').toList();
  
  // Synthesize with specific format
  final audioData = await ttsService.synthesizeText(
    'Hello world',
    englishVoices.first.name,
    format: 'wav',
  );
}
```

## API Reference

### Core Classes

#### TTSService
The main service class providing a unified interface to all TTS engines.

```dart
class TTSService {
  Future<void> initialize({TTSEngineType? preferredEngine});
  Future<List<Voice>> getVoices();
  Future<Uint8List> synthesizeText(String text, String voiceName, {String format = 'mp3'});
  Future<void> speakText(String text, {String? voiceName, String format = 'mp3'});
  Future<void> switchEngine(TTSEngineType engineType);
  TTSEngineType? get currentEngine;
  void dispose();
}
```

#### PlatformDetector
Utility class for platform detection and platform-specific UI optimizations.

```dart
class PlatformDetector {
  String get platformName;
  bool get isDesktop;
  bool get isMobile;
  bool get supportsEmojiFlags;
  String getFlag(String emojiFlag, String languageCode);
  double get flagFontSize;
}
```

#### TTSProcessor
Abstract interface implemented by all TTS engines.

```dart
abstract class TTSProcessor {
  String get backend;
  Future<List<Voice>> getVoices();
  Future<Uint8List> synthesizeText(String text, String voiceName, {String format = 'mp3'});
  void dispose();
}
```

#### AudioPlayer
Cross-platform audio player for TTS-generated content.

```dart
class AudioPlayer {
  Future<void> play(String filePath);
  Future<void> playBytes(Uint8List audioData, {String format = 'mp3'});
}
```

#### PlatformTTSFactory
Factory for creating platform-appropriate TTS processors.

```dart
class PlatformTTSFactory {
  static Future<TTSProcessor> createForPlatform();
  static Future<TTSProcessor> create(TTSEngineType engineType);
}
```

### Data Models

#### Voice
Represents a TTS voice with metadata.

```dart
class Voice {
  final String name;           // Voice identifier
  final String displayName;    // Human-readable name
  final String language;       // Language code (e.g., 'en', 'zh')
  final String gender;         // 'Male', 'Female', or 'Unknown'
  final String locale;         // Full locale (e.g., 'en-US', 'zh-CN')
  final bool isNeural;         // Whether it's a neural voice
  final bool isStandard;       // Whether it's a standard voice
}
```

#### TTSError
Comprehensive error class with recovery suggestions.

```dart
class TTSError extends Error {
  final String message;        // Error description
  final String? code;          // Error code for programmatic handling
  final dynamic originalError; // Original underlying error
}
```

### Utility Classes

#### PlatformUtils
Platform detection and capability checking.

```dart
class PlatformUtils {
  static bool get isDesktop;
  static bool get isMobile;
  static bool get isWeb;
  static TTSEngineType get recommendedEngine;
  static Future<bool> isEdgeTTSAvailable();
}
```

#### FileUtils
File operations for temporary audio files.

```dart
class FileUtils {
  static Future<File> createTempFile({String? prefix, String? suffix});
  static Future<void> cleanupTempFile(File file);
}
```

## Migration Guide

### From Legacy API to New Unified API

If you're using the legacy `EdgeTTSService` or `FlutterTTSService`:

**Before (Legacy):**
```dart
// Old way
final edgeService = EdgeTTSService();
await edgeService.initialize();
final voices = await edgeService.getVoices();
```

**After (New Unified API):**
```dart
// New way
final ttsService = TTSService();
await ttsService.initialize();
final voices = await ttsService.getVoices();
```

### Key Benefits of Migration

1. **Automatic Platform Selection**: No need to manually choose engines
2. **Consistent Interface**: Same API across all platforms
3. **Better Error Handling**: More informative error messages
4. **Engine Switching**: Change engines at runtime
5. **Improved Performance**: Optimized resource management

### Deprecated APIs

The following APIs are still supported but marked as deprecated:

- `EdgeTTSService` → Use `TTSService` or `EdgeTTSProcessor`
- `FlutterTTSService` → Use `TTSService` or `FlutterTTSProcessor`
- Legacy `TTSPlayer` classes → Use `AudioPlayer`

## Platform-Specific Notes

### Desktop (Windows, macOS, Linux)
- **Recommended Engine**: Edge TTS
- **Requirements**: Install `edge-tts` via pip
- **Features**: Full audio file generation support

### Mobile (Android, iOS)
- **Recommended Engine**: Flutter TTS
- **Requirements**: None (uses system TTS)
- **Features**: Native system integration

### Web
- **Recommended Engine**: Flutter TTS
- **Requirements**: None (uses Web Speech API)
- **Limitations**: No audio file generation support

## Error Handling

The library provides comprehensive error handling with specific error codes:

```dart
try {
  final audioData = await ttsService.synthesizeText('Hello', 'invalid-voice');
} on TTSError catch (e) {
  switch (e.code) {
    case TTSErrorCodes.voiceNotFound:
      print('Voice not available: ${e.message}');
      break;
    case TTSErrorCodes.synthesisFailed:
      print('Synthesis failed: ${e.message}');
      break;
    default:
      print('TTS error: ${e.message}');
  }
}
```

## Performance Tips

1. **Cache Voice Lists**: Voice lists are automatically cached but can be refreshed
2. **Reuse Services**: Create one service instance and reuse it
3. **Proper Cleanup**: Always call `dispose()` when done
4. **Choose Appropriate Engine**: Edge TTS for quality, Flutter TTS for compatibility

## Troubleshooting

### Edge TTS Issues

**Problem**: "edge-tts command not found"
**Solution**: Install edge-tts: `pip install edge-tts`

**Problem**: "No voices available"
**Solution**: Check internet connection for initial voice list download

### Flutter TTS Issues

**Problem**: "No system voices available"
**Solution**: Check system TTS settings and ensure voices are installed

**Problem**: "Synthesis failed on web"
**Solution**: Web platform has limitations; consider using Edge TTS for file generation

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests to our repository.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Changelog

### Version 1.0.0
- Initial release with unified API
- Support for Edge TTS and Flutter TTS
- Cross-platform audio playback
- Comprehensive error handling
- Backward compatibility with legacy APIs
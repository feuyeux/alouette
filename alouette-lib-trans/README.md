# Alouette Translation Library

A Flutter library for AI-powered translation functionality with support for multiple LLM providers.

## Features

- Support for multiple LLM providers (Ollama, LM Studio)
- Unified API for translation operations
- Configuration management and connection testing
- Comprehensive error handling
- Cross-platform support (Android, iOS, Web, Windows, macOS, Linux)

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  alouette_lib_trans: ^1.0.0
```

## Usage

```dart
import 'package:alouette_lib_trans/alouette_lib_trans.dart';

// Configure LLM
final config = LLMConfig(
  provider: 'ollama',
  serverUrl: 'http://localhost:11434',
  selectedModel: 'llama2',
);

// Create translation service
final translationService = TranslationService();

// Translate text
final result = await translationService.translateText(
  'Hello, world!',
  ['es', 'fr', 'de'],
  config,
);

print(result.translations['es']); // Hola, mundo!
```

## Supported Providers

- **Ollama**: Local LLM server
- **LM Studio**: Local LLM server with OpenAI-compatible API

## License

MIT License
# Changelog

All notable changes to the alouette-lib-trans library will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-12

### Added
- Initial release of alouette-lib-trans library
- Core AI translation functionality extracted from alouette-app and alouette-translator applications
- Multi-platform support (Android, iOS, Web, Windows, macOS, Linux)
- TranslationService with comprehensive API for AI-powered translation
- LLMConfigService for LLM provider configuration and management
- Support for multiple LLM providers (Ollama, LM Studio)
- Comprehensive data models (LLMConfig, TranslationRequest, TranslationResult, ConnectionStatus)
- Auto-detection and configuration capabilities
- Robust error handling with custom exceptions
- Text cleaning utilities for translation results
- Unit tests and integration tests
- Example application demonstrating usage

### Features
- **Multi-Provider Support**: Ollama and LM Studio integration
- **Batch Translation**: Translate to multiple languages simultaneously
- **Auto-Configuration**: Automatic detection of available LLM services
- **Connection Testing**: Verify LLM provider connectivity and model availability
- **Configuration Management**: Save and load LLM configurations
- **Error Handling**: Comprehensive error handling with meaningful messages
- **Text Processing**: Advanced text cleaning and formatting utilities

### Supported LLM Providers
- **Ollama**: Local AI model server with REST API
- **LM Studio**: Local AI model server with OpenAI-compatible API
- Extensible architecture for additional providers

### Language Support
- Chinese (Simplified)
- English
- Japanese
- Korean
- French
- German
- Spanish
- Italian
- Russian
- Arabic
- Hindi
- Greek

### Dependencies
- http: ^1.1.0 for HTTP client functionality
- Flutter SDK: >=3.8.1

### Breaking Changes
- N/A (Initial release)

### Migration Guide
This is the initial release. To migrate from custom translation implementations:

1. Add dependency to pubspec.yaml:
   ```yaml
   dependencies:
     alouette_lib_trans:
       path: ../alouette-lib-trans  # or version from pub.dev
   ```

2. Replace custom translation imports:
   ```dart
   // Before
   import 'package:http/http.dart' as http;
   // Custom translation logic
   
   // After
   import 'package:alouette_lib_trans/alouette_lib_trans.dart';
   ```

3. Update service initialization:
   ```dart
   // Before
   // Custom HTTP client and translation logic
   
   // After
   TranslationService translationService = TranslationService();
   LLMConfigService configService = LLMConfigService();
   ```

4. Update translation calls:
   ```dart
   // Before
   // Custom HTTP requests and JSON parsing
   
   // After
   final config = LLMConfig(
     provider: 'ollama',
     serverUrl: 'http://localhost:11434',
     selectedModel: 'qwen2.5:latest',
   );
   
   final result = await translationService.translateText(
     'Hello World',
     ['Chinese', 'Japanese'],
     config,
   );
   ```

5. Update configuration management:
   ```dart
   // Before
   // Custom configuration storage
   
   // After
   await configService.saveConfig(config);
   final savedConfig = await configService.loadConfig();
   final connectionStatus = await configService.testConnection(config);
   ```

### API Changes from Custom Implementations
- Standardized error handling with custom exception types
- Unified configuration model across all LLM providers
- Consistent response format for all translation operations
- Built-in connection testing and model discovery

### Documentation
- Comprehensive README with usage examples
- API documentation for all public methods
- Provider-specific setup instructions
- Migration guide from custom implementations
- Troubleshooting guide

### Known Issues
- None at this time

### Contributors
- Alouette Development Team
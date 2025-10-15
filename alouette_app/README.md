# Alouette App

The main Flutter application that combines AI-powered translation and text-to-speech functionality in a unified interface.

## Overview

Alouette App is the flagship application of the Alouette ecosystem, providing users with seamless access to both translation and TTS capabilities. It leverages the refactored architecture with centralized services and shared UI components for a consistent, high-quality user experience.

## Features

### 🌍 AI-Powered Translation
- Support for multiple LLM providers (Ollama, LM Studio)
- Batch translation to multiple languages simultaneously
- Real-time connection status and model information
- Comprehensive error handling and retry mechanisms

### 🔊 High-Quality Text-to-Speech
- Platform-optimized TTS engines (Edge TTS for desktop, Flutter TTS for mobile/web)
- 12+ languages with neural voice support
- Advanced voice controls (speed, pitch, volume)
- Audio export capabilities

### 🎨 Modern User Interface
- Material Design 3 with atomic design components
- Responsive layout for all screen sizes
- Dark/light theme support with custom color options
- Accessibility features and keyboard navigation

### ⚙️ Advanced Configuration
- Centralized configuration management
- Service health monitoring
- Theme customization and preferences
- Platform-specific optimizations

## Architecture

Alouette App follows the refactored architecture principles:

```
alouette_app/
├── lib/
│   ├── main.dart                    # Application entry point
│   ├── app/
│   │   ├── alouette_app.dart        # Main app widget
│   │   └── app_router.dart          # Navigation configuration
│   ├── features/
│   │   ├── home/                    # Home page and dashboard
│   │   └── translation/             # Translation workflows
│   ├── shared/
│   │   ├── constants/               # App-specific constants
│   │   └── utils/                   # Utility functions
│   └── config/
│       └── app_config.dart          # Application configuration
├── test/                            # Unit and widget tests
├── integration_test/                # Integration tests
└── pubspec.yaml                     # Dependencies and metadata
```

### Dependencies

The application depends on the refactored libraries:

- **alouette_lib_trans**: AI translation services
- **alouette_lib_tts**: Text-to-speech services
- **alouette_ui**: Shared UI components and services

## Quick Start

### Prerequisites

- Flutter SDK 3.8.1+
- Dart SDK 3.0.0+
- For AI translation: Ollama or LM Studio
- For desktop TTS: Python 3.7+ with `edge-tts` package

### Installation

1. **Navigate to the app directory**
   ```bash
   cd alouette_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   # Desktop (Windows, macOS, Linux)
   flutter run -d windows
   flutter run -d macos
   flutter run -d linux
   
   # Mobile
   flutter run -d android
   flutter run -d ios
   
   # Web
   flutter run -d chrome
   ```

### Configuration

#### AI Translation Setup

1. **Install Ollama** (recommended for local AI)
   ```bash
   # Visit https://ollama.ai for installation instructions
   ollama serve
   ollama pull llama3.2
   ```

2. **Or install LM Studio**
   - Download from https://lmstudio.ai
   - Load a compatible model
   - Start the local server

3. **Configure in the app**
   - Open Settings (⚙️ icon)
   - Select LLM provider (Ollama or LM Studio)
   - Enter server URL (default: `http://localhost:11434` for Ollama)
   - Test connection and select model

#### TTS Setup

**Desktop platforms** (automatic Edge TTS setup):
```bash
pip install edge-tts
```

**Mobile/Web platforms**: Uses system TTS (no additional setup required)

## Usage

### Translation Workflow

1. **Enter text** in the input area
2. **Select target languages** from the grid selector
3. **Configure LLM settings** if needed (provider, model, server URL)
4. **Click Translate** to process the text
5. **Copy results** or use them for TTS synthesis

### TTS Workflow

1. **Enter or paste text** in the TTS input area
2. **Select voice** from available options
3. **Adjust settings** (speed, pitch, volume) if desired
4. **Click Play** to synthesize and play audio
5. **Export audio** if needed (desktop platforms)

### Combined Workflow

1. **Translate text** using the translation feature
2. **Select a translation result**
3. **Use "Speak" button** to synthesize the translated text
4. **Adjust TTS settings** for optimal output

## Service Integration

The application uses the service locator pattern for dependency management:

```dart
// Services are automatically initialized in main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await ServiceManager.initialize(ServiceConfiguration.combined);
  
  runApp(AlouetteApp());
}

// Access services in widgets
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final translationService = ServiceManager.getTranslationService();
    final ttsService = ServiceManager.getTTSService();
    
    // Use services...
  }
}
```

## UI Components

The application uses atomic design components from alouette-ui-shared:

### Atoms
- `AlouetteButton` - Consistent button styling
- `AlouetteTextField` - Unified text input
- `AlouetteSlider` - Voice control sliders

### Molecules
- `LanguageSelector` - Language selection interface
- `VoiceSelector` - Voice selection dropdown
- `StatusIndicator` - Service status display

### Organisms
- `TranslationPanel` - Complete translation interface
- `TTSControlPanel` - Full TTS control interface
- `ConfigDialog` - Settings and configuration

## Platform-Specific Features

### Desktop (Windows, macOS, Linux)
- **Edge TTS integration** for high-quality synthesis
- **File export** capabilities for audio
- **Advanced keyboard shortcuts**
- **Window state persistence**

### Mobile (Android, iOS)
- **Native TTS integration** with system voices
- **Touch-optimized interface**
- **Platform-specific navigation**
- **Background audio playback**

### Web
- **Web Speech API** integration
- **Responsive design** for various screen sizes
- **Progressive Web App** capabilities
- **Cross-browser compatibility**

## Configuration Options

### Application Settings

```dart
// Theme and appearance
await ConfigurationManager.instance.setThemeMode('dark');
await ConfigurationManager.instance.setFontScale(1.2);

// Language preferences
await ConfigurationManager.instance.setPrimaryLanguage('es');

// Feature toggles
await ConfigurationManager.instance.setShowAdvancedOptions(true);
await ConfigurationManager.instance.setAnimationsEnabled(false);
```

### Service Configuration

```dart
// Translation service
final translationConfig = LLMConfig(
  provider: 'ollama',
  serverUrl: 'http://localhost:11434',
  selectedModel: 'llama3.2',
);

// TTS service
final ttsConfig = TTSConfig(
  preferredEngine: TTSEngineType.edge,
  speechRate: 1.0,
  volume: 0.8,
  pitch: 1.0,
);
```

## Troubleshooting

### Common Issues

1. **Translation not working**
   - Verify LLM server is running (Ollama/LM Studio)
   - Check network connectivity
   - Validate server URL and model selection
   - Review error messages in the status indicator

2. **TTS not working**
   - Desktop: Ensure `edge-tts` is installed (`pip install edge-tts`)
   - Mobile: Check system TTS settings
   - Verify internet connection for voice downloads

3. **UI issues**
   - Clear app data and restart
   - Check theme settings
   - Verify screen resolution compatibility

### Debug Mode

Run with verbose logging:
```bash
flutter run --verbose
```

Enable debug features in the app:
- Settings → Advanced → Enable Debug Mode
- View service health status
- Access detailed error logs

## Performance Optimization

### Memory Management
- Services are properly disposed when not needed
- Audio files are cleaned up after playback
- Configuration is cached for quick access

### Network Optimization
- Connection pooling for LLM requests
- Retry logic with exponential backoff
- Efficient voice list caching

### UI Performance
- Lazy loading of heavy components
- Efficient state management
- Optimized animations and transitions

## Contributing

When contributing to the main application:

1. **Follow architecture principles** - Use services through the service locator
2. **Use shared components** - Leverage alouette-ui-shared for UI elements
3. **Add tests** - Include unit, widget, and integration tests
4. **Update documentation** - Keep README and code comments current
5. **Test across platforms** - Verify functionality on desktop, mobile, and web

### Code Style

- Follow Flutter naming conventions
- Use atomic design components
- Implement proper error handling
- Add accessibility features
- Document public APIs

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

## Support

For issues specific to the main application:

1. Check the [troubleshooting section](#troubleshooting)
2. Review the [platform-specific features](#platform-specific-features)
3. Consult the library documentation for service-related issues
4. Create an issue on GitHub with detailed reproduction steps
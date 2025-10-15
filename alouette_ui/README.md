# Alouette UI Shared Library

A comprehensive Flutter library providing shared UI components, services, and design systems for all Alouette applications. Built with atomic design principles and a robust service architecture.

## Overview

The Alouette UI Shared library serves as the foundation for consistent user experiences across all Alouette applications. It provides:

- **Atomic Design Components**: Hierarchical component system (atoms, molecules, organisms)
- **Service Locator**: Centralized dependency injection and service management
- **Design Token System**: Consistent styling and theming across applications
- **Configuration Management**: Unified settings and preferences system
- **Theme Management**: Advanced theme switching and customization

## Features

### 🎨 Atomic Design System
- **Atoms**: Basic UI elements (buttons, text fields, sliders)
- **Molecules**: Composite components (selectors, indicators, search boxes)
- **Organisms**: Complex components (panels, dialogs, control interfaces)

### 🔧 Service Architecture
- **Service Locator**: Dependency injection container
- **Service Manager**: High-level service lifecycle management
- **Health Monitoring**: Service status tracking and health checks
- **Configuration**: Centralized settings management

### 🎭 Design Tokens
- **Color System**: Semantic colors with light/dark theme support
- **Typography**: Material Design 3 text styles
- **Spacing & Dimensions**: Consistent sizing system
- **Motion**: Standardized animation timing and curves
- **Effects**: Gradients, shadows, and visual effects

### ⚙️ Configuration System
- **Persistent Storage**: SharedPreferences and file-based storage
- **Validation**: Comprehensive configuration validation
- **Migration**: Automatic version upgrades
- **Export/Import**: Configuration backup and restore

## Quick Start

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  alouette_ui: ^1.0.0
```

### Basic Setup

```dart
import 'package:alouette_ui/alouette_ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize configuration
  await ConfigurationManager.instance.initialize();
  
  // Initialize services (optional)
  await ServiceManager.initialize(ServiceConfiguration.combined);
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlouetteThemeProvider(
      child: MaterialApp(
        theme: ThemeService().getLightTheme(),
        darkTheme: ThemeService().getDarkTheme(),
        home: MyHomePage(),
      ),
    );
  }
}
```

### Using Atomic Components

```dart
class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Alouette App')),
      body: Padding(
        padding: EdgeInsets.all(SpacingTokens.l),
        child: Column(
          children: [
            // Atom: Button
            AlouetteButton(
              text: 'Primary Action',
              onPressed: () {},
              variant: AlouetteButtonVariant.primary,
            ),
            
            SizedBox(height: SpacingTokens.m),
            
            // Molecule: Language Selector
            LanguageSelector(
              selectedLanguage: 'en',
              onLanguageChanged: (language) {},
              availableLanguages: [
                LanguageOption(code: 'en', name: 'English'),
                LanguageOption(code: 'es', name: 'Spanish'),
              ],
            ),
            
            SizedBox(height: SpacingTokens.l),
            
            // Organism: Translation Panel
            Expanded(
              child: TranslationPanel(
                textController: TextEditingController(),
                selectedLanguages: ['es', 'fr'],
                onLanguagesChanged: (languages) {},
                onTranslate: () {},
                onClear: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Architecture

### Component Hierarchy

```
alouette_ui/
├── lib/
│   ├── alouette_ui.dart          # Main export
│   └── src/
│       ├── components/                   # UI Components
│       │   ├── atoms/                    # Basic elements
│       │   ├── molecules/                # Composite components
│       │   └── organisms/                # Complex components
│       ├── services/                     # Core services
│       │   ├── core/                     # Service locator & manager
│       │   ├── tts_service.dart
│       │   └── translation_service.dart
│       ├── tokens/                       # Design tokens
│       │   ├── color_tokens.dart
│       │   ├── typography_tokens.dart
│       │   ├── dimension_tokens.dart
│       │   └── motion_tokens.dart
│       ├── themes/                       # Theme system
│       │   ├── app_theme.dart
│       │   └── theme_service.dart
│       └── widgets/                      # Utility widgets
```

## Atomic Design Components

### Atoms

Basic UI elements that serve as building blocks:

#### AlouetteButton

```dart
AlouetteButton(
  text: 'Action',
  onPressed: () {},
  variant: AlouetteButtonVariant.primary, // primary, secondary, tertiary, destructive
  size: AlouetteButtonSize.medium,        // small, medium, large
  icon: Icons.translate,                  // optional icon
  isLoading: false,                       // loading state
)
```

#### AlouetteTextField

```dart
AlouetteTextField(
  controller: textController,
  labelText: 'Enter text',
  hintText: 'Type something...',
  errorText: errorMessage,
  maxLines: 3,
  onChanged: (value) {},
)
```

#### AlouetteSlider

```dart
AlouetteSlider(
  value: currentValue,
  onChanged: (value) {},
  min: 0.0,
  max: 2.0,
  divisions: 20,
  label: 'Speech Rate',
  icon: Icons.speed,
)
```

### Molecules

Composite components combining multiple atoms:

#### LanguageSelector

```dart
LanguageSelector(
  selectedLanguage: 'en',
  onLanguageChanged: (language) {},
  availableLanguages: languages,
  labelText: 'Target Language',
)
```

#### VoiceSelector

```dart
VoiceSelector(
  selectedVoice: 'en-US-AriaNeural',
  onVoiceChanged: (voice) {},
  availableVoices: voices,
  labelText: 'Voice',
)
```

#### StatusIndicator

```dart
StatusIndicator(
  status: StatusType.success,           // success, warning, error, info
  message: 'Translation completed',
  details: 'Translated to 3 languages',
  actions: [
    StatusAction(
      label: 'Copy Results',
      onPressed: () {},
    ),
  ],
)
```

### Organisms

Complex components providing complete functionality:

#### TranslationPanel

```dart
TranslationPanel(
  textController: textController,
  selectedLanguages: ['es', 'fr', 'de'],
  onLanguagesChanged: (languages) {},
  onTranslate: () {},
  onClear: () {},
  translationResults: results,
  isTranslating: false,
  errorMessage: null,
  isCompact: false,
)
```

#### TTSControlPanel

```dart
TTSControlPanel(
  textController: textController,
  availableVoices: voices,
  selectedVoice: selectedVoice,
  onVoiceChanged: (voice) {},
  onPlay: () {},
  onStop: () {},
  speechRate: 1.0,
  volume: 0.8,
  pitch: 1.0,
  onSpeechRateChanged: (rate) {},
  onVolumeChanged: (volume) {},
  onPitchChanged: (pitch) {},
  isPlaying: false,
  showAdvancedControls: true,
)
```

#### ConfigDialog

```dart
ConfigDialog(
  title: 'Settings',
  sections: [
    ConfigSection(
      title: 'General',
      fields: [
        ConfigField.dropdown(
          key: 'theme',
          label: 'Theme',
          value: 'system',
          options: ['light', 'dark', 'system'],
        ),
        ConfigField.slider(
          key: 'font_scale',
          label: 'Font Scale',
          value: 1.0,
          min: 0.5,
          max: 2.0,
        ),
      ],
    ),
  ],
  onSave: () {},
  onCancel: () {},
  onReset: () {},
)
```

## Service Architecture

### Service Locator

Centralized dependency injection:

```dart
// Register services
ServiceLocator.register<MyService>(MyServiceImpl());
ServiceLocator.registerFactory<MyService>(() => MyServiceImpl());
ServiceLocator.registerSingleton<MyService>(() => MyServiceImpl());

// Retrieve services
final service = ServiceLocator.get<MyService>();

// Check registration
if (ServiceLocator.isRegistered<MyService>()) {
  // Service is available
}
```

### Service Manager

High-level service management:

```dart
// Initialize services
final result = await ServiceManager.initialize(ServiceConfiguration.combined);

if (result.isSuccessful) {
  // Access services
  final ttsService = ServiceManager.getTTSService();
  final translationService = ServiceManager.getTranslationService();
} else {
  print('Initialization failed: ${result.errors}');
}

// Check service status
final status = ServiceManager.getServiceStatus();
print('TTS Available: ${status['TTS']}');

// Dispose services
await ServiceManager.dispose();
```

### Service Health Monitoring

```dart
// Start health monitoring
ServiceHealthMonitor.startMonitoring(intervalSeconds: 30);

// Listen to health reports
ServiceHealthMonitor.healthReportStream.listen((report) {
  print('Overall healthy: ${report.isOverallHealthy}');
  for (final service in report.serviceReports) {
    print('${service.serviceName}: ${service.status}');
  }
});

// Manual health check
final report = await ServiceHealthMonitor.performHealthCheck();
```

## Design Token System

### Colors

```dart
// Primary colors
Container(color: ColorTokens.primary)
Text('Text', style: TextStyle(color: ColorTokens.onPrimary))

// Functional colors
Container(color: ColorTokens.success)
Container(color: ColorTokens.warning)
Container(color: ColorTokens.error)

// Surface colors
Container(color: ColorTokens.surface)
Container(color: ColorTokens.surfaceVariant)
```

### Typography

```dart
// Display styles (large headings)
Text('Title', style: TypographyTokens.displayLargeStyle)

// Headline styles (section headings)
Text('Section', style: TypographyTokens.headlineMediumStyle)

// Body styles (content)
Text('Content', style: TypographyTokens.bodyLargeStyle)

// Label styles (buttons, captions)
Text('Label', style: TypographyTokens.labelMediumStyle)
```

### Spacing

```dart
// Consistent spacing
Padding(padding: EdgeInsets.all(SpacingTokens.l))
SizedBox(height: SpacingTokens.m)
Container(margin: EdgeInsets.symmetric(horizontal: SpacingTokens.xl))

// Available sizes: xxs, xs, s, m, l, xl, xxl, xxxl
```

### Dimensions

```dart
// Component sizing
Container(
  width: DimensionTokens.buttonMinWidth,
  height: DimensionTokens.buttonL,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(DimensionTokens.radiusM),
  ),
)
```

### Motion

```dart
// Animation timing
AnimatedContainer(
  duration: MotionTokens.fast,        // 150ms
  curve: MotionTokens.standard,       // easeInOut
  // ...
)

AnimatedOpacity(
  duration: MotionTokens.normal,      // 200ms
  curve: MotionTokens.emphasized,     // easeInOutCubic
  // ...
)
```

## Configuration Management

### Basic Configuration

```dart
final configManager = ConfigurationManager.instance;

// Initialize
await configManager.initialize();

// Get/set theme
await configManager.setThemeMode('dark');
final themeMode = await configManager.getThemeMode();

// Get/set language
await configManager.setPrimaryLanguage('es');
final language = await configManager.getPrimaryLanguage();

// Custom app settings
await configManager.setAppSetting('auto_save', true);
final autoSave = await configManager.getAppSetting<bool>('auto_save');
```

### Reactive Configuration

```dart
// Listen to configuration changes
configManager.configurationStream.listen((config) {
  print('Configuration updated: ${config.version}');
  // Update UI accordingly
});
```

### Configuration Validation

```dart
// Validate configuration
final isValid = await configManager.isConfigurationValid();
final errors = await configManager.getConfigurationErrors();
final warnings = await configManager.getConfigurationWarnings();
```

### Export/Import

```dart
// Export configuration
final configJson = await configManager.exportConfiguration();

// Import configuration
final success = await configManager.importConfiguration(configJson);
```

## Theme Management

### Theme Service

```dart
final themeService = ThemeService();

// Set theme mode
themeService.setThemeMode(AlouetteThemeMode.dark);

// Custom colors
themeService.setUseCustomColors(true);
themeService.setCustomPrimaryColor(Colors.purple);

// Use in MaterialApp
MaterialApp(
  theme: themeService.getLightTheme(),
  darkTheme: themeService.getDarkTheme(),
  themeMode: _getThemeMode(themeService.themeMode),
)
```

### Theme Widgets

```dart
// Theme provider wrapper
AlouetteThemeProvider(
  child: MyApp(),
)

// Theme switcher
ThemeSwitcher(
  onThemeChanged: () {
    // Handle theme change
  },
)

// Full theme configuration
ThemeConfigurationWidget(
  onThemeChanged: () {
    // Handle theme change
  },
)
```

### Custom Theme Colors

```dart
// Access custom colors
final customColors = Theme.of(context).alouetteColors;

Container(
  color: customColors.success,
  child: Text(
    'Success message',
    style: TextStyle(color: customColors.onSuccess),
  ),
)
```

## Testing

### Component Testing

```dart
void main() {
  group('AlouetteButton Tests', () {
    testWidgets('should render with correct text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AlouetteButton(
            text: 'Test Button',
            onPressed: () {},
          ),
        ),
      );
      
      expect(find.text('Test Button'), findsOneWidget);
    });
    
    testWidgets('should call onPressed when tapped', (tester) async {
      bool pressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: AlouetteButton(
            text: 'Test Button',
            onPressed: () => pressed = true,
          ),
        ),
      );
      
      await tester.tap(find.byType(AlouetteButton));
      expect(pressed, isTrue);
    });
  });
}
```

### Service Testing

```dart
void main() {
  group('ServiceLocator Tests', () {
    setUp(() {
      ServiceLocator.clear();
    });
    
    test('should register and retrieve service', () {
      final service = MockService();
      ServiceLocator.register<MockService>(service);
      
      final retrieved = ServiceLocator.get<MockService>();
      expect(retrieved, equals(service));
    });
    
    test('should throw when service not registered', () {
      expect(
        () => ServiceLocator.get<MockService>(),
        throwsA(isA<ServiceNotRegisteredException>()),
      );
    });
  });
}
```

### Configuration Testing

```dart
void main() {
  group('ConfigurationManager Tests', () {
    late ConfigurationManager configManager;
    
    setUp(() {
      configManager = ConfigurationManager.instance;
    });
    
    test('should save and load theme mode', () async {
      await configManager.initialize();
      
      await configManager.setThemeMode('dark');
      final themeMode = await configManager.getThemeMode();
      
      expect(themeMode, equals('dark'));
    });
  });
}
```

## Examples and Demos

### Design Token Showcase

```dart
// Interactive demo of all design tokens
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => DesignTokenShowcase(),
  ),
);
```

### Atomic Design Demo

```dart
// Comprehensive demo of atomic components
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AtomicDesignDemo(),
  ),
);
```

## Migration from Legacy UI

### Component Migration

```dart
// OLD: Custom button
ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
  onPressed: onPressed,
  child: Text('Button'),
)

// NEW: Atomic button
AlouetteButton(
  text: 'Button',
  onPressed: onPressed,
  variant: AlouetteButtonVariant.primary,
)
```

### Theme Migration

```dart
// OLD: Manual theme management
ThemeData(
  primarySwatch: Colors.blue,
  // ...
)

// NEW: Design token system
ThemeService().getLightTheme() // Automatically uses design tokens
```

### Configuration Migration

```dart
// OLD: Manual SharedPreferences
final prefs = await SharedPreferences.getInstance();
final theme = prefs.getString('theme') ?? 'system';

// NEW: Configuration manager
final theme = await ConfigurationManager.instance.getThemeMode();
```

## Best Practices

### Component Usage

1. **Use atomic hierarchy**: Build complex UIs from atoms → molecules → organisms
2. **Leverage design tokens**: Use tokens instead of hardcoded values
3. **Follow naming conventions**: Use descriptive, semantic names
4. **Implement proper error handling**: Handle edge cases gracefully
5. **Add accessibility features**: Support screen readers and keyboard navigation

### Service Management

1. **Initialize early**: Set up services in main() before running the app
2. **Use interfaces**: Depend on abstractions, not concrete implementations
3. **Handle failures gracefully**: Check service availability before use
4. **Dispose properly**: Clean up resources when services are no longer needed
5. **Monitor health**: Use health monitoring for production applications

### Configuration

1. **Validate inputs**: Always validate configuration before saving
2. **Handle migrations**: Support upgrading from older configuration versions
3. **Use reactive patterns**: Listen to configuration changes for UI updates
4. **Backup configurations**: Implement export/import for user data safety
5. **Test thoroughly**: Verify configuration persistence across app restarts

## Contributing

When contributing to the UI shared library:

1. **Follow atomic design principles**: Place components in the correct hierarchy level
2. **Use design tokens**: Ensure all styling uses the token system
3. **Add comprehensive tests**: Include unit, widget, and integration tests
4. **Update documentation**: Keep README and code comments current
5. **Maintain backward compatibility**: Avoid breaking changes when possible

### Adding New Components

1. **Determine hierarchy level**: Atom, molecule, or organism?
2. **Use existing tokens**: Leverage the design token system
3. **Add proper documentation**: Include usage examples and API docs
4. **Write tests**: Cover all component variants and edge cases
5. **Update exports**: Add to the appropriate barrel file

### Adding New Services

1. **Define clear interfaces**: Create abstract base classes
2. **Implement proper lifecycle**: Support initialization and disposal
3. **Add health checks**: Implement status monitoring
4. **Handle errors gracefully**: Provide meaningful error messages
5. **Register with service locator**: Make services discoverable

## Documentation

Complete API documentation is available in the source code and through dart doc:

```bash
# Generate documentation
dart doc

# View documentation
open doc/api/index.html
```

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

## Support

For issues and questions about the UI shared library:

1. Check the [examples and demos](#examples-and-demos) for usage patterns
2. Review the [migration guide](#migration-from-legacy-ui) for upgrading
3. Consult the [best practices](#best-practices) for implementation guidance
4. Create an issue on GitHub with detailed reproduction steps
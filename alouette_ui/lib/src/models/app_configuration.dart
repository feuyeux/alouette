import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';

/// Unified application configuration model
///
/// This is the standardized data model used across all Alouette applications
/// for application configuration. It includes comprehensive validation and serialization.
class AppConfiguration {
  /// Translation configuration
  final LLMConfig? translationConfig;

  /// TTS configuration
  final TTSConfig? ttsConfig;

  /// UI preferences
  final UIPreferences uiPreferences;

  /// Application-specific settings
  final Map<String, dynamic> appSettings;

  /// Last updated timestamp
  final DateTime lastUpdated;

  /// Configuration version for migration purposes
  final String version;

  AppConfiguration({
    this.translationConfig,
    this.ttsConfig,
    this.uiPreferences = const UIPreferences(),
    this.appSettings = const {},
    DateTime? lastUpdated,
    this.version = '1.0.0',
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// Convert to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'translation_config': translationConfig?.toJson(),
      'tts_config': ttsConfig?.toJson(),
      'ui_preferences': uiPreferences.toJson(),
      'app_settings': appSettings,
      'last_updated': lastUpdated.toIso8601String(),
      'version': version,
    };
  }

  /// Create from JSON representation
  factory AppConfiguration.fromJson(Map<String, dynamic> json) {
    return AppConfiguration(
      translationConfig: json['translation_config'] != null
          ? LLMConfig.fromJson(json['translation_config'])
          : null,
      ttsConfig: json['tts_config'] != null
          ? TTSConfig.fromJson(json['tts_config'])
          : null,
      uiPreferences: json['ui_preferences'] != null
          ? UIPreferences.fromJson(json['ui_preferences'])
          : const UIPreferences(),
      appSettings: json['app_settings'] != null
          ? Map<String, dynamic>.from(json['app_settings'])
          : {},
      lastUpdated: DateTime.parse(
        json['last_updated'] ?? DateTime.now().toIso8601String(),
      ),
      version: json['version'] ?? '1.0.0',
    );
  }

  /// Create a copy with modified fields
  AppConfiguration copyWith({
    LLMConfig? translationConfig,
    TTSConfig? ttsConfig,
    UIPreferences? uiPreferences,
    Map<String, dynamic>? appSettings,
    DateTime? lastUpdated,
    String? version,
  }) {
    return AppConfiguration(
      translationConfig: translationConfig ?? this.translationConfig,
      ttsConfig: ttsConfig ?? this.ttsConfig,
      uiPreferences: uiPreferences ?? this.uiPreferences,
      appSettings: appSettings ?? this.appSettings,
      lastUpdated: lastUpdated ?? DateTime.now(),
      version: version ?? this.version,
    );
  }

  /// Validate the configuration
  Map<String, dynamic> validate() {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate translation config if present
    if (translationConfig != null) {
      final translationValidation = translationConfig!.validate();
      if (!(translationValidation['isValid'] as bool)) {
        errors.addAll(List<String>.from(translationValidation['errors']));
      }
      warnings.addAll(List<String>.from(translationValidation['warnings']));
    }

    // Validate TTS config if present
    if (ttsConfig != null) {
      final ttsValidation = ttsConfig!.validate();
      if (ttsValidation.isNotEmpty) {
        errors.addAll(ttsValidation);
      }
    }

    // Validate UI preferences
    final uiValidation = uiPreferences.validate();
    if (!(uiValidation['isValid'] as bool)) {
      errors.addAll(List<String>.from(uiValidation['errors']));
    }
    warnings.addAll(List<String>.from(uiValidation['warnings']));

    // Version validation
    if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version)) {
      warnings.add(
        'Version format should follow semantic versioning (e.g., 1.0.0)',
      );
    }

    return {'isValid': errors.isEmpty, 'errors': errors, 'warnings': warnings};
  }

  /// Check if the configuration is valid (no validation errors)
  bool get isValid => validate()['isValid'] as bool;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppConfiguration &&
        other.translationConfig == translationConfig &&
        other.ttsConfig == ttsConfig &&
        other.uiPreferences == uiPreferences &&
        other.appSettings.length == appSettings.length &&
        other.appSettings.keys.every(
          (key) => appSettings[key] == other.appSettings[key],
        ) &&
        other.version == version;
  }

  @override
  int get hashCode {
    return Object.hash(
      translationConfig,
      ttsConfig,
      uiPreferences,
      Object.hashAll(
        appSettings.entries.map((e) => Object.hash(e.key, e.value)),
      ),
      version,
    );
  }

  @override
  String toString() {
    return 'AppConfiguration(version: $version, hasTranslation: ${translationConfig != null}, '
        'hasTTS: ${ttsConfig != null}, lastUpdated: $lastUpdated)';
  }
}

/// UI preferences model
class UIPreferences {
  /// Theme mode (light, dark, system)
  final String themeMode;

  /// Primary language for the UI
  final String primaryLanguage;

  /// Font size scale factor
  final double fontScale;

  /// Whether to show advanced options
  final bool showAdvancedOptions;

  /// Whether to enable animations
  final bool enableAnimations;

  /// Window size preferences
  final WindowPreferences? windowPreferences;

  /// Custom UI settings
  final Map<String, dynamic> customSettings;

  const UIPreferences({
    this.themeMode = 'system',
    this.primaryLanguage = 'en',
    this.fontScale = 1.0,
    this.showAdvancedOptions = false,
    this.enableAnimations = true,
    this.windowPreferences,
    this.customSettings = const {},
  });

  /// Convert to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'theme_mode': themeMode,
      'primary_language': primaryLanguage,
      'font_scale': fontScale,
      'show_advanced_options': showAdvancedOptions,
      'enable_animations': enableAnimations,
      'window_preferences': windowPreferences?.toJson(),
      'custom_settings': customSettings,
    };
  }

  /// Create from JSON representation
  factory UIPreferences.fromJson(Map<String, dynamic> json) {
    return UIPreferences(
      themeMode: json['theme_mode'] ?? 'system',
      primaryLanguage: json['primary_language'] ?? 'en',
      fontScale: (json['font_scale'] ?? 1.0).toDouble(),
      showAdvancedOptions: json['show_advanced_options'] ?? false,
      enableAnimations: json['enable_animations'] ?? true,
      windowPreferences: json['window_preferences'] != null
          ? WindowPreferences.fromJson(json['window_preferences'])
          : null,
      customSettings: json['custom_settings'] != null
          ? Map<String, dynamic>.from(json['custom_settings'])
          : {},
    );
  }

  /// Create a copy with modified fields
  UIPreferences copyWith({
    String? themeMode,
    String? primaryLanguage,
    double? fontScale,
    bool? showAdvancedOptions,
    bool? enableAnimations,
    WindowPreferences? windowPreferences,
    Map<String, dynamic>? customSettings,
  }) {
    return UIPreferences(
      themeMode: themeMode ?? this.themeMode,
      primaryLanguage: primaryLanguage ?? this.primaryLanguage,
      fontScale: fontScale ?? this.fontScale,
      showAdvancedOptions: showAdvancedOptions ?? this.showAdvancedOptions,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      windowPreferences: windowPreferences ?? this.windowPreferences,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  /// Validate the UI preferences
  Map<String, dynamic> validate() {
    final errors = <String>[];
    final warnings = <String>[];

    // Theme mode validation
    const validThemeModes = ['light', 'dark', 'system'];
    if (!validThemeModes.contains(themeMode)) {
      errors.add('Theme mode must be one of: ${validThemeModes.join(", ")}');
    }

    // Language code validation
    if (!RegExp(r'^[a-z]{2}(-[A-Z]{2})?$').hasMatch(primaryLanguage)) {
      warnings.add(
        'Primary language "$primaryLanguage" may not be in standard format (e.g., "en", "en-US")',
      );
    }

    // Font scale validation
    if (fontScale < 0.5 || fontScale > 3.0) {
      errors.add('Font scale must be between 0.5 and 3.0');
    }

    // Window preferences validation
    if (windowPreferences != null) {
      final windowValidation = windowPreferences!.validate();
      if (!(windowValidation['isValid'] as bool)) {
        errors.addAll(List<String>.from(windowValidation['errors']));
      }
      warnings.addAll(List<String>.from(windowValidation['warnings']));
    }

    return {'isValid': errors.isEmpty, 'errors': errors, 'warnings': warnings};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UIPreferences &&
        other.themeMode == themeMode &&
        other.primaryLanguage == primaryLanguage &&
        other.fontScale == fontScale &&
        other.showAdvancedOptions == showAdvancedOptions &&
        other.enableAnimations == enableAnimations &&
        other.windowPreferences == windowPreferences &&
        other.customSettings.length == customSettings.length &&
        other.customSettings.keys.every(
          (key) => customSettings[key] == other.customSettings[key],
        );
  }

  @override
  int get hashCode {
    return Object.hash(
      themeMode,
      primaryLanguage,
      fontScale,
      showAdvancedOptions,
      enableAnimations,
      windowPreferences,
      Object.hashAll(
        customSettings.entries.map((e) => Object.hash(e.key, e.value)),
      ),
    );
  }

  @override
  String toString() {
    return 'UIPreferences(theme: $themeMode, language: $primaryLanguage, fontScale: $fontScale)';
  }
}

/// Window preferences model
class WindowPreferences {
  /// Window width
  final double width;

  /// Window height
  final double height;

  /// Window X position
  final double? x;

  /// Window Y position
  final double? y;

  /// Whether window is maximized
  final bool isMaximized;

  /// Whether window is minimized
  final bool isMinimized;

  const WindowPreferences({
    this.width = 800.0,
    this.height = 600.0,
    this.x,
    this.y,
    this.isMaximized = false,
    this.isMinimized = false,
  });

  /// Convert to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
      'x': x,
      'y': y,
      'is_maximized': isMaximized,
      'is_minimized': isMinimized,
    };
  }

  /// Create from JSON representation
  factory WindowPreferences.fromJson(Map<String, dynamic> json) {
    return WindowPreferences(
      width: (json['width'] ?? 800.0).toDouble(),
      height: (json['height'] ?? 600.0).toDouble(),
      x: json['x']?.toDouble(),
      y: json['y']?.toDouble(),
      isMaximized: json['is_maximized'] ?? false,
      isMinimized: json['is_minimized'] ?? false,
    );
  }

  /// Create a copy with modified fields
  WindowPreferences copyWith({
    double? width,
    double? height,
    double? x,
    double? y,
    bool? isMaximized,
    bool? isMinimized,
  }) {
    return WindowPreferences(
      width: width ?? this.width,
      height: height ?? this.height,
      x: x ?? this.x,
      y: y ?? this.y,
      isMaximized: isMaximized ?? this.isMaximized,
      isMinimized: isMinimized ?? this.isMinimized,
    );
  }

  /// Validate the window preferences
  Map<String, dynamic> validate() {
    final errors = <String>[];
    final warnings = <String>[];

    // Size validation
    if (width < 200 || width > 5000) {
      errors.add('Window width must be between 200 and 5000 pixels');
    }

    if (height < 150 || height > 5000) {
      errors.add('Window height must be between 150 and 5000 pixels');
    }

    // Position validation
    if (x != null && (x! < -1000 || x! > 10000)) {
      warnings.add('Window X position seems unusual (${x!.toInt()})');
    }

    if (y != null && (y! < -1000 || y! > 10000)) {
      warnings.add('Window Y position seems unusual (${y!.toInt()})');
    }

    // State validation
    if (isMaximized && isMinimized) {
      errors.add('Window cannot be both maximized and minimized');
    }

    return {'isValid': errors.isEmpty, 'errors': errors, 'warnings': warnings};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WindowPreferences &&
        other.width == width &&
        other.height == height &&
        other.x == x &&
        other.y == y &&
        other.isMaximized == isMaximized &&
        other.isMinimized == isMinimized;
  }

  @override
  int get hashCode {
    return Object.hash(width, height, x, y, isMaximized, isMinimized);
  }

  @override
  String toString() {
    return 'WindowPreferences(${width.toInt()}x${height.toInt()}, maximized: $isMaximized)';
  }
}

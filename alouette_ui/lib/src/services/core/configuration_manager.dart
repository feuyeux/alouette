import 'dart:async';

import '../../core/logger.dart';
import 'configuration_service.dart';
import '../../models/app_configuration.dart';

/// High-level configuration manager for Alouette applications
///
/// Provides a simplified API for configuration management with automatic
/// initialization, validation, and error handling.
class ConfigurationManager {
  static ConfigurationManager? _instance;
  static ConfigurationManager get instance {
    _instance ??= ConfigurationManager._internal();
    return _instance!;
  }

  ConfigurationManager._internal();

  ConfigurationService? _configService;
  bool _isInitialized = false;
  final Completer<void> _initializationCompleter = Completer<void>();

  /// Initialize the configuration manager
  Future<void> initialize() async {
    if (_isInitialized) {
      return _initializationCompleter.future;
    }

    // If initialization is already in progress, return the same future
    if (!_initializationCompleter.isCompleted) {
      try {
        _configService = ConfigurationService();
        await _configService!.initialize();

        _isInitialized = true;
        _initializationCompleter.complete();
      } catch (e) {
        logger.e('[CONFIG] Failed to initialize ConfigurationManager', error: e);
        if (!_initializationCompleter.isCompleted) {
          _initializationCompleter.completeError(e);
        }
        rethrow;
      }
    }

    return _initializationCompleter.future;
  }

  /// Ensure the manager is initialized before use
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Get current configuration
  Future<AppConfiguration> getConfiguration() async {
    await _ensureInitialized();
    return _configService!.currentConfiguration;
  }

  /// Update configuration with validation
  Future<bool> updateConfiguration(AppConfiguration config) async {
    await _ensureInitialized();
    return await _configService!.updateConfiguration(config);
  }

  /// Update UI preferences only
  Future<bool> updateUIPreferences(UIPreferences preferences) async {
    await _ensureInitialized();
    final currentConfig = _configService!.currentConfiguration;
    final updatedConfig = currentConfig.copyWith(uiPreferences: preferences);
    return await _configService!.updateConfiguration(updatedConfig);
  }

  /// Update app settings only
  Future<bool> updateAppSettings(Map<String, dynamic> settings) async {
    await _ensureInitialized();
    final currentConfig = _configService!.currentConfiguration;
    final updatedConfig = currentConfig.copyWith(appSettings: settings);
    return await _configService!.updateConfiguration(updatedConfig);
  }

  /// Update translation configuration only
  Future<bool> updateTranslationConfig(dynamic translationConfig) async {
    await _ensureInitialized();
    final currentConfig = _configService!.currentConfiguration;
    final updatedConfig = currentConfig.copyWith(
      translationConfig: translationConfig,
    );
    return await _configService!.updateConfiguration(updatedConfig);
  }

  /// Update TTS configuration only
  Future<bool> updateTTSConfig(dynamic ttsConfig) async {
    await _ensureInitialized();
    final currentConfig = _configService!.currentConfiguration;
    final updatedConfig = currentConfig.copyWith(ttsConfig: ttsConfig);
    return await _configService!.updateConfiguration(updatedConfig);
  }

  /// Get specific app setting
  Future<T?> getAppSetting<T>(String key) async {
    await _ensureInitialized();
    final config = _configService!.currentConfiguration;
    return config.appSettings[key] as T?;
  }

  /// Set specific app setting
  Future<bool> setAppSetting<T>(String key, T value) async {
    await _ensureInitialized();
    final currentConfig = _configService!.currentConfiguration;
    final updatedSettings = Map<String, dynamic>.from(
      currentConfig.appSettings,
    );
    updatedSettings[key] = value;

    final updatedConfig = currentConfig.copyWith(appSettings: updatedSettings);
    return await _configService!.updateConfiguration(updatedConfig);
  }

  /// Reset configuration to defaults
  Future<void> resetToDefaults() async {
    await _ensureInitialized();
    await _configService!.resetToDefaults();
  }

  /// Export configuration for backup
  Future<Map<String, dynamic>> exportConfiguration() async {
    await _ensureInitialized();
    return _configService!.exportConfiguration();
  }

  /// Import configuration from backup
  Future<bool> importConfiguration(Map<String, dynamic> configJson) async {
    await _ensureInitialized();
    return await _configService!.importConfiguration(configJson);
  }

  /// Validate current configuration
  Future<Map<String, dynamic>> validateConfiguration() async {
    await _ensureInitialized();
    final config = _configService!.currentConfiguration;
    return _configService!.validateConfiguration(config);
  }

  /// Check if configuration is valid
  Future<bool> isConfigurationValid() async {
    final validation = await validateConfiguration();
    return validation['isValid'] as bool;
  }

  /// Get configuration validation errors
  Future<List<String>> getConfigurationErrors() async {
    final validation = await validateConfiguration();
    return List<String>.from(validation['errors'] ?? []);
  }

  /// Get configuration validation warnings
  Future<List<String>> getConfigurationWarnings() async {
    final validation = await validateConfiguration();
    return List<String>.from(validation['warnings'] ?? []);
  }

  /// Stream of configuration changes
  Stream<AppConfiguration> get configurationStream async* {
    await _ensureInitialized();
    yield* _configService!.configurationStream;
  }

  /// Check if this is the first launch
  Future<bool> isFirstLaunch() async {
    final firstLaunch = await getAppSetting<bool>('first_launch');
    return firstLaunch ?? true;
  }

  /// Mark first launch as completed
  Future<void> completeFirstLaunch() async {
    await setAppSetting('first_launch', false);
  }

  /// Get theme mode
  Future<String> getThemeMode() async {
    final config = await getConfiguration();
    return config.uiPreferences.themeMode;
  }

  /// Set theme mode
  Future<bool> setThemeMode(String themeMode) async {
    final config = await getConfiguration();
    final updatedPreferences = config.uiPreferences.copyWith(
      themeMode: themeMode,
    );
    return await updateUIPreferences(updatedPreferences);
  }

  /// Get primary language
  Future<String> getPrimaryLanguage() async {
    final config = await getConfiguration();
    return config.uiPreferences.primaryLanguage;
  }

  /// Set primary language
  Future<bool> setPrimaryLanguage(String language) async {
    final config = await getConfiguration();
    final updatedPreferences = config.uiPreferences.copyWith(
      primaryLanguage: language,
    );
    return await updateUIPreferences(updatedPreferences);
  }

  /// Get font scale
  Future<double> getFontScale() async {
    final config = await getConfiguration();
    return config.uiPreferences.fontScale;
  }

  /// Set font scale
  Future<bool> setFontScale(double scale) async {
    final config = await getConfiguration();
    final updatedPreferences = config.uiPreferences.copyWith(fontScale: scale);
    return await updateUIPreferences(updatedPreferences);
  }

  /// Check if advanced options should be shown
  Future<bool> shouldShowAdvancedOptions() async {
    final config = await getConfiguration();
    return config.uiPreferences.showAdvancedOptions;
  }

  /// Set advanced options visibility
  Future<bool> setShowAdvancedOptions(bool show) async {
    final config = await getConfiguration();
    final updatedPreferences = config.uiPreferences.copyWith(
      showAdvancedOptions: show,
    );
    return await updateUIPreferences(updatedPreferences);
  }

  /// Check if animations are enabled
  Future<bool> areAnimationsEnabled() async {
    final config = await getConfiguration();
    return config.uiPreferences.enableAnimations;
  }

  /// Set animations enabled
  Future<bool> setAnimationsEnabled(bool enabled) async {
    final config = await getConfiguration();
    final updatedPreferences = config.uiPreferences.copyWith(
      enableAnimations: enabled,
    );
    return await updateUIPreferences(updatedPreferences);
  }

  /// Dispose resources
  void dispose() {
    _configService?.dispose();
    _configService = null;
    _isInitialized = false;
    _instance = null;
  }
}

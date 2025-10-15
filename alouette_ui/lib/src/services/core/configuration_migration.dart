import '../../core/logger.dart';
import '../../models/app_configuration.dart';

/// Configuration migration utilities
///
/// Handles migration of configuration data between different versions
/// of the Alouette applications.
class ConfigurationMigration {
  static const String currentVersion = '1.0.0';

  /// Migration registry mapping version ranges to migration functions
  static final Map<
    String,
    Future<Map<String, dynamic>> Function(Map<String, dynamic>)
  >
  _migrations = {
    '0.1.0->1.0.0': _migrateFrom0_1_0To1_0_0,
    '0.2.0->1.0.0': _migrateFrom0_2_0To1_0_0,
    // Add more migrations as needed
  };

  /// Perform migration from any supported version to current version
  static Future<AppConfiguration> migrate(
    Map<String, dynamic> oldConfig,
    String fromVersion,
  ) async {
    logger.i(
      '[CONFIG] Starting configuration migration from $fromVersion to $currentVersion',
    );

    try {
      Map<String, dynamic> migratedConfig = Map.from(oldConfig);

      // Apply version-specific migrations
      final migrationKey = '$fromVersion->$currentVersion';
      if (_migrations.containsKey(migrationKey)) {
        migratedConfig = await _migrations[migrationKey]!(migratedConfig);
      } else {
        // Try to find a migration path through intermediate versions
        migratedConfig = await _findMigrationPath(
          migratedConfig,
          fromVersion,
          currentVersion,
        );
      }

      // Ensure final version is set
      migratedConfig['version'] = currentVersion;
      migratedConfig['last_updated'] = DateTime.now().toIso8601String();

      // Validate migrated configuration
      final config = AppConfiguration.fromJson(migratedConfig);
      final validation = config.validate();

      if (!(validation['isValid'] as bool)) {
        logger.w(
          '[CONFIG] Migration resulted in invalid configuration: ${validation['errors']}',
        );
        // Apply fixes for common migration issues
        migratedConfig = _applyMigrationFixes(
          migratedConfig,
          validation['errors'] as List<String>,
        );
      }

      logger.i('[CONFIG] Configuration migration completed successfully');
      return AppConfiguration.fromJson(migratedConfig);
    } catch (e) {
      logger.e('[CONFIG] Configuration migration failed', error: e);
      // Return a safe default configuration
      return _createSafeMigratedConfiguration(oldConfig);
    }
  }

  /// Check if migration is needed
  static bool needsMigration(String? currentVersion) {
    if (currentVersion == null) return true;
    return currentVersion != ConfigurationMigration.currentVersion;
  }

  /// Get list of supported migration paths
  static List<String> getSupportedMigrations() {
    return _migrations.keys.toList();
  }

  // Private migration methods

  static Future<Map<String, dynamic>> _migrateFrom0_1_0To1_0_0(
    Map<String, dynamic> config,
  ) async {
    final migrated = Map<String, dynamic>.from(config);

    // Migrate old theme settings
    if (migrated.containsKey('theme')) {
      final oldTheme = migrated['theme'];
      migrated['ui_preferences'] = {
        'theme_mode': oldTheme == 'dark' ? 'dark' : 'light',
        'primary_language': migrated['language'] ?? 'en',
        'font_scale': 1.0,
        'show_advanced_options': false,
        'enable_animations': true,
      };
      migrated.remove('theme');
      migrated.remove('language');
    }

    // Migrate old TTS settings
    if (migrated.containsKey('tts_settings')) {
      final oldTTS = migrated['tts_settings'] as Map<String, dynamic>;
      migrated['tts_config'] = {
        'engine_type': oldTTS['engine'] ?? 'flutter',
        'speech_rate': oldTTS['rate'] ?? 1.0,
        'volume': oldTTS['volume'] ?? 1.0,
        'pitch': oldTTS['pitch'] ?? 1.0,
      };
      migrated.remove('tts_settings');
    }

    // Migrate old translation settings
    if (migrated.containsKey('translation_settings')) {
      final oldTranslation =
          migrated['translation_settings'] as Map<String, dynamic>;
      migrated['translation_config'] = {
        'provider': oldTranslation['provider'] ?? 'ollama',
        'model': oldTranslation['model'] ?? 'llama2',
        'base_url': oldTranslation['url'] ?? 'http://localhost:11434',
        'api_key': oldTranslation['api_key'],
      };
      migrated.remove('translation_settings');
    }

    // Set default app settings
    migrated['app_settings'] = {
      'first_launch': false, // Not first launch if migrating
      'analytics_enabled': migrated['analytics'] ?? false,
      'auto_save': migrated['auto_save'] ?? true,
      'backup_enabled': true,
    };

    // Clean up old keys
    migrated.remove('analytics');
    migrated.remove('auto_save');

    return migrated;
  }

  static Future<Map<String, dynamic>> _migrateFrom0_2_0To1_0_0(
    Map<String, dynamic> config,
  ) async {
    final migrated = Map<String, dynamic>.from(config);

    // 0.2.0 had partial UI preferences, ensure all fields exist
    if (migrated.containsKey('ui_preferences')) {
      final uiPrefs = migrated['ui_preferences'] as Map<String, dynamic>;

      // Ensure all required fields exist
      uiPrefs['theme_mode'] ??= 'system';
      uiPrefs['primary_language'] ??= 'en';
      uiPrefs['font_scale'] ??= 1.0;
      uiPrefs['show_advanced_options'] ??= false;
      uiPrefs['enable_animations'] ??= true;

      migrated['ui_preferences'] = uiPrefs;
    }

    // Ensure app_settings exists with all required fields
    final appSettings = migrated['app_settings'] as Map<String, dynamic>? ?? {};
    appSettings['first_launch'] ??= false;
    appSettings['analytics_enabled'] ??= false;
    appSettings['auto_save'] ??= true;
    appSettings['backup_enabled'] ??= true;
    migrated['app_settings'] = appSettings;

    return migrated;
  }

  static Future<Map<String, dynamic>> _findMigrationPath(
    Map<String, dynamic> config,
    String fromVersion,
    String toVersion,
  ) async {
    // For now, apply a generic migration that ensures all required fields exist
    return _applyGenericMigration(config);
  }

  static Map<String, dynamic> _applyGenericMigration(
    Map<String, dynamic> config,
  ) {
    final migrated = Map<String, dynamic>.from(config);

    // Ensure UI preferences exist
    if (!migrated.containsKey('ui_preferences')) {
      migrated['ui_preferences'] = {
        'theme_mode': 'system',
        'primary_language': 'en',
        'font_scale': 1.0,
        'show_advanced_options': false,
        'enable_animations': true,
      };
    }

    // Ensure app settings exist
    if (!migrated.containsKey('app_settings')) {
      migrated['app_settings'] = {
        'first_launch': false,
        'analytics_enabled': false,
        'auto_save': true,
        'backup_enabled': true,
      };
    }

    return migrated;
  }

  static Map<String, dynamic> _applyMigrationFixes(
    Map<String, dynamic> config,
    List<String> errors,
  ) {
    final fixed = Map<String, dynamic>.from(config);

    for (final error in errors) {
      if (error.contains('Theme mode')) {
        // Fix invalid theme mode
        final uiPrefs = fixed['ui_preferences'] as Map<String, dynamic>? ?? {};
        uiPrefs['theme_mode'] = 'system';
        fixed['ui_preferences'] = uiPrefs;
      }

      if (error.contains('Font scale')) {
        // Fix invalid font scale
        final uiPrefs = fixed['ui_preferences'] as Map<String, dynamic>? ?? {};
        uiPrefs['font_scale'] = 1.0;
        fixed['ui_preferences'] = uiPrefs;
      }

      if (error.contains('Window')) {
        // Fix invalid window preferences
        final uiPrefs = fixed['ui_preferences'] as Map<String, dynamic>? ?? {};
        uiPrefs.remove('window_preferences'); // Remove invalid window prefs
        fixed['ui_preferences'] = uiPrefs;
      }
    }

    return fixed;
  }

  static AppConfiguration _createSafeMigratedConfiguration(
    Map<String, dynamic> oldConfig,
  ) {
    // Create a safe configuration preserving what we can from the old config
    return AppConfiguration(
      uiPreferences: UIPreferences(
        themeMode: _extractSafeValue(oldConfig, [
          'ui_preferences',
          'theme_mode',
        ], 'system'),
        primaryLanguage: _extractSafeValue(oldConfig, [
          'ui_preferences',
          'primary_language',
        ], 'en'),
        fontScale: _extractSafeValue(oldConfig, [
          'ui_preferences',
          'font_scale',
        ], 1.0),
        showAdvancedOptions: _extractSafeValue(oldConfig, [
          'ui_preferences',
          'show_advanced_options',
        ], false),
        enableAnimations: _extractSafeValue(oldConfig, [
          'ui_preferences',
          'enable_animations',
        ], true),
      ),
      appSettings: {
        'first_launch': false,
        'analytics_enabled': _extractSafeValue(oldConfig, [
          'app_settings',
          'analytics_enabled',
        ], false),
        'auto_save': _extractSafeValue(oldConfig, [
          'app_settings',
          'auto_save',
        ], true),
        'backup_enabled': _extractSafeValue(oldConfig, [
          'app_settings',
          'backup_enabled',
        ], true),
        // Preserve any other app settings that might exist
        ..._extractSafeMap(oldConfig, ['app_settings']),
      },
      version: currentVersion,
    );
  }

  static T _extractSafeValue<T>(
    Map<String, dynamic> config,
    List<String> path,
    T defaultValue,
  ) {
    try {
      dynamic current = config;
      for (final key in path) {
        if (current is Map<String, dynamic> && current.containsKey(key)) {
          current = current[key];
        } else {
          return defaultValue;
        }
      }
      return current is T ? current : defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  static Map<String, dynamic> _extractSafeMap(
    Map<String, dynamic> config,
    List<String> path,
  ) {
    try {
      dynamic current = config;
      for (final key in path) {
        if (current is Map<String, dynamic> && current.containsKey(key)) {
          current = current[key];
        } else {
          return {};
        }
      }
      return current is Map<String, dynamic> ? current : {};
    } catch (e) {
      return {};
    }
  }
}

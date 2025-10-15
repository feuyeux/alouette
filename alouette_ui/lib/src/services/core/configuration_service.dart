import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/logger.dart';
import '../../models/app_configuration.dart';

/// Simple configuration service for Alouette applications
///
/// Provides persistent storage for application configuration using SharedPreferences
class ConfigurationService {
  static const String _configKey = 'alouette_app_configuration';
  static const String _configVersionKey = 'alouette_config_version';
  static const String _currentVersion = '1.0.0';

  SharedPreferences? _prefs;
  AppConfiguration? _currentConfig;
  final StreamController<AppConfiguration> _configController =
      StreamController<AppConfiguration>.broadcast();

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentConfig = await loadConfiguration();
  }

  Future<AppConfiguration> loadConfiguration() async {
    if (_prefs == null) {
      throw StateError('ConfigurationService not initialized');
    }

    final configJson = _prefs!.getString(_configKey);
    if (configJson == null) {
      return AppConfiguration();
    }

    try {
      return AppConfiguration.fromJson(json.decode(configJson));
    } catch (e) {
      logger.e('[CONFIG] Failed to load configuration', error: e);
      return AppConfiguration();
    }
  }

  Future<void> saveConfiguration(AppConfiguration config) async {
    if (_prefs == null) {
      throw StateError('ConfigurationService not initialized');
    }

    _currentConfig = config;
    final configJson = json.encode(config.toJson());
    await _prefs!.setString(_configKey, configJson);
    await _prefs!.setString(_configVersionKey, _currentVersion);
    _configController.add(config);
  }

  AppConfiguration get currentConfiguration =>
      _currentConfig ?? AppConfiguration();

  Future<bool> updateConfiguration(AppConfiguration config) async {
    try {
      await saveConfiguration(config);
      return true;
    } catch (e) {
      logger.e('[CONFIG] Failed to update configuration', error: e);
      return false;
    }
  }

  Future<void> resetToDefaults() async {
    final defaults = AppConfiguration();
    await saveConfiguration(defaults);
  }

  Future<Map<String, dynamic>> exportConfiguration() async {
    return currentConfiguration.toJson();
  }

  Future<bool> importConfiguration(Map<String, dynamic> configJson) async {
    try {
      final config = AppConfiguration.fromJson(configJson);
      await saveConfiguration(config);
      return true;
    } catch (e) {
      logger.e('[CONFIG] Failed to import configuration', error: e);
      return false;
    }
  }

  Map<String, dynamic> validateConfiguration(AppConfiguration config) {
    // Basic validation
    return {
      'isValid': true,
      'errors': <String>[],
      'warnings': <String>[],
    };
  }

  Stream<AppConfiguration> get configurationStream => _configController.stream;

  void dispose() {
    _configController.close();
  }
}

/// Unified app initialization logic for all Alouette applications
///
/// Provides consistent service initialization patterns across
/// alouette_app, alouette_app_trans, and alouette_app_tts.
library alouette_ui.core.initialization;

import 'package:flutter/material.dart';
import '../services/core/service_locator.dart';
import '../services/core/service_manager.dart';
import '../services/core/service_configuration.dart';
import '../services/theme_service.dart';
import '../core/errors/alouette_error.dart';
import '../widgets/splash_screen.dart';

/// Base class for app-specific initialization
abstract class AppInitializer {
  /// Initialize all required services for the app
  Future<bool> initialize();

  /// Get app-specific error message
  String getErrorMessage(Object error);
}

/// Combined app initializer (Translation + TTS)
class CombinedAppInitializer extends AppInitializer {
  @override
  Future<bool> initialize() async {
    final logger = ServiceLocator.logger;

    try {
      logger.info('Starting Combined app initialization', tag: 'AppInit');

      // Initialize services in parallel for faster startup
      await Future.wait([_initializeServices(), _initializeThemeService()]);

      logger.info('All services initialized successfully', tag: 'AppInit');
      return true;
    } catch (error, stackTrace) {
      logger.fatal(
        'Service initialization failed',
        tag: 'AppInit',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> _initializeServices() async {
    final logger = ServiceLocator.logger;
    try {
      logger.debug('Initializing combined services', tag: 'ServiceInit');

      final result = await ServiceManager.initialize(
        const ServiceConfiguration(
          initializeTTS: true,
          initializeTranslation: true,
          initializationTimeoutMs: 15000, // 15 seconds timeout
        ),
      );

      if (!result.isSuccessful) {
        throw ServiceError.initializationFailed(
          'Combined',
          result.errors.join(', '),
        );
      }

      logger.info('All services initialized successfully', tag: 'ServiceInit');
    } catch (e, stackTrace) {
      logger.error(
        'Service initialization failed',
        tag: 'ServiceInit',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> _initializeThemeService() async {
    final logger = ServiceLocator.logger;
    try {
      logger.debug('Initializing Theme service', tag: 'ServiceInit');

      ServiceLocator.registerSingleton<ThemeService>(() => ThemeService());
      final themeService = ServiceLocator.get<ThemeService>();
      await themeService.initialize();

      logger.info('Theme service initialized', tag: 'ServiceInit');
    } catch (e, stackTrace) {
      logger.error(
        'Theme initialization failed',
        tag: 'ServiceInit',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  String getErrorMessage(Object error) {
    if (error is ServiceError) {
      return 'Failed to initialize services: ${error.message}';
    }
    return 'Unexpected error during initialization: $error';
  }
}

/// Translation-only app initializer
class TranslationAppInitializer extends AppInitializer {
  @override
  Future<bool> initialize() async {
    final logger = ServiceLocator.logger;

    try {
      logger.info('Starting Translation app initialization', tag: 'AppInit');

      // Initialize services in parallel
      await Future.wait([
        _initializeTranslationService(),
        _initializeThemeService(),
      ]);

      logger.info('All services initialized successfully', tag: 'AppInit');
      return true;
    } catch (error, stackTrace) {
      logger.fatal(
        'Service initialization failed',
        tag: 'AppInit',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> _initializeTranslationService() async {
    final logger = ServiceLocator.logger;
    try {
      logger.debug('Initializing Translation service', tag: 'ServiceInit');

      // Use short timeout for translation - it can be configured manually later
      final result =
          await ServiceManager.initialize(
            const ServiceConfiguration(
              initializeTTS: false, // Translation-only app, no TTS
              initializeTranslation: true,
              initializationTimeoutMs:
                  5000, // 5 seconds - allow manual config later
            ),
          ).timeout(
            const Duration(seconds: 6),
            onTimeout: () {
              // Timeout is OK - user can configure manually
              logger.info(
                'Translation auto-config timed out - manual configuration available',
                tag: 'ServiceInit',
              );
              return ServiceInitializationResult(
                isSuccessful: true, // Continue anyway
                serviceResults: {'Translation': false},
                errors: ['Auto-configuration timed out'],
                durationMs: 6000,
              );
            },
          );

      logger.info(
        'Translation service initialized: ${result.isSuccessful}',
        tag: 'ServiceInit',
      );
    } catch (e) {
      // Allow translation service to fail - can be configured manually
      logger.warning(
        'Translation auto-config failed - manual configuration available',
        tag: 'ServiceInit',
        error: e,
      );
      // Don't rethrow - app can still start
    }
  }

  Future<void> _initializeThemeService() async {
    final logger = ServiceLocator.logger;
    try {
      logger.debug('Initializing Theme service', tag: 'ServiceInit');

      ServiceLocator.registerSingleton<ThemeService>(() => ThemeService());
      final themeService = ServiceLocator.get<ThemeService>();
      await themeService.initialize();

      logger.info('Theme service initialized', tag: 'ServiceInit');
    } catch (e, stackTrace) {
      logger.error(
        'Theme initialization failed',
        tag: 'ServiceInit',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  String getErrorMessage(Object error) {
    if (error is ServiceError) {
      return 'Failed to initialize translation service: ${error.message}';
    }
    return 'Unexpected error during initialization: $error';
  }
}

/// TTS-only app initializer
class TTSAppInitializer extends AppInitializer {
  @override
  Future<bool> initialize() async {
    final logger = ServiceLocator.logger;

    try {
      logger.info('Starting TTS app initialization', tag: 'AppInit');

      // Initialize services in parallel
      await Future.wait([_initializeTTSService(), _initializeThemeService()]);

      logger.info('All services initialized successfully', tag: 'AppInit');
      return true;
    } catch (error, stackTrace) {
      logger.fatal(
        'Service initialization failed',
        tag: 'AppInit',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> _initializeTTSService() async {
    final logger = ServiceLocator.logger;
    try {
      logger.debug('Initializing TTS service', tag: 'ServiceInit');

      final result = await ServiceManager.initialize(
        const ServiceConfiguration(
          initializeTTS: true,
          initializeTranslation: false,
          initializationTimeoutMs: 15000, // 15 seconds
        ),
      );

      if (!result.isSuccessful) {
        throw ServiceError.initializationFailed(
          'TTS',
          result.errors.join(', '),
        );
      }

      logger.info('TTS service initialized successfully', tag: 'ServiceInit');
    } catch (e, stackTrace) {
      logger.error(
        'TTS initialization failed',
        tag: 'ServiceInit',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> _initializeThemeService() async {
    final logger = ServiceLocator.logger;
    try {
      logger.debug('Initializing Theme service', tag: 'ServiceInit');

      ServiceLocator.registerSingleton<ThemeService>(() => ThemeService());
      final themeService = ServiceLocator.get<ThemeService>();
      await themeService.initialize();

      logger.info('Theme service initialized', tag: 'ServiceInit');
    } catch (e, stackTrace) {
      logger.error(
        'Theme initialization failed',
        tag: 'ServiceInit',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  String getErrorMessage(Object error) {
    if (error is ServiceError) {
      return 'Failed to initialize TTS service: ${error.message}';
    }
    return 'Unexpected error during initialization: $error';
  }
}

/// Base wrapper widget for app initialization
class AppInitializationWrapper extends StatelessWidget {
  final String title;
  final String splashMessage;
  final AppInitializer initializer;
  final Widget app;

  const AppInitializationWrapper({
    super.key,
    required this.title,
    required this.splashMessage,
    required this.initializer,
    required this.app,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: initializer.initialize(),
        builder: (context, snapshot) {
          // Show splash screen while loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SplashScreen(message: splashMessage);
          }

          // Show error screen if initialization failed
          if (snapshot.hasError || snapshot.data == false) {
            return InitializationErrorScreen(
              error: snapshot.error,
              onRetry: () {
                // Force rebuild to retry initialization
                (context as Element).markNeedsBuild();
              },
            );
          }

          // Services initialized successfully
          return app;
        },
      ),
    );
  }
}

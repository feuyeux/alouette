import 'dart:async';
import 'package:alouette_lib_tts/alouette_tts.dart' as tts_lib;
import 'package:alouette_lib_trans/alouette_lib_trans.dart' as trans_lib;
import 'service_locator.dart';

/// Service Health Monitor
///
/// Monitors the health and status of registered services.
/// Provides health checks and automatic recovery mechanisms.
class ServiceHealthMonitor {
  static Timer? _healthCheckTimer;
  static final Map<Type, ServiceHealthStatus> _healthStatus = {};
  static final StreamController<ServiceHealthReport> _healthReportController =
      StreamController<ServiceHealthReport>.broadcast();

  /// Start health monitoring
  ///
  /// [intervalSeconds] - How often to check service health (default: 30 seconds)
  static void startMonitoring({int intervalSeconds = 30}) {
    stopMonitoring(); // Stop any existing monitoring

    _healthCheckTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => _performHealthCheck(),
    );
  }

  /// Stop health monitoring
  static void stopMonitoring() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  /// Perform a manual health check
  static Future<ServiceHealthReport> performHealthCheck() async {
    return await _performHealthCheck();
  }

  /// Get current health status for all services
  static Map<Type, ServiceHealthStatus> getCurrentHealthStatus() {
    return Map.unmodifiable(_healthStatus);
  }

  /// Get health report stream
  static Stream<ServiceHealthReport> get healthReportStream =>
      _healthReportController.stream;

  /// Check if a specific service is healthy
  static bool isServiceHealthy<T>() {
    final status = _healthStatus[T];
    return status?.isHealthy ?? false;
  }

  /// Perform health check on all registered services
  static Future<ServiceHealthReport> _performHealthCheck() async {
    final report = ServiceHealthReport(timestamp: DateTime.now());

    // Check TTS service
    if (ServiceLocator.isRegistered<tts_lib.TTSService>()) {
      final status = await _checkTTSHealth();
      _healthStatus[tts_lib.TTSService] = status;
      report.serviceStatus[tts_lib.TTSService] = status;
    }

    // Check Translation service
    if (ServiceLocator.isRegistered<trans_lib.TranslationService>()) {
      final status = await _checkTranslationHealth();
      _healthStatus[trans_lib.TranslationService] = status;
      report.serviceStatus[trans_lib.TranslationService] = status;
    }

    // Broadcast the health report
    _healthReportController.add(report);
    return report;
  }

  /// Check TTS service health
  static Future<ServiceHealthStatus> _checkTTSHealth() async {
    try {
      final service = ServiceLocator.get<tts_lib.TTSService>();

      if (!service.isInitialized) {
        return ServiceHealthStatus(
          isHealthy: false,
          lastChecked: DateTime.now(),
          error: 'Service not initialized',
        );
      }

      // Try to get voices as a health check
      await service.getVoices();

      return ServiceHealthStatus(isHealthy: true, lastChecked: DateTime.now());
    } catch (e) {
      return ServiceHealthStatus(
        isHealthy: false,
        lastChecked: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Check Translation service health
  static Future<ServiceHealthStatus> _checkTranslationHealth() async {
    try {
      final service = ServiceLocator.get<trans_lib.TranslationService>();

      if (!service.isReady) {
        return ServiceHealthStatus(
          isHealthy: false,
          lastChecked: DateTime.now(),
          error: 'Service not ready',
        );
      }

      // Just check if service is ready - no specific method call needed
      // Translation service health is based on isReady status

      return ServiceHealthStatus(isHealthy: true, lastChecked: DateTime.now());
    } catch (e) {
      return ServiceHealthStatus(
        isHealthy: false,
        lastChecked: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Dispose the health monitor
  static void dispose() {
    stopMonitoring();
    _healthStatus.clear();
    _healthReportController.close();
  }
}

/// Service health status
class ServiceHealthStatus {
  final bool isHealthy;
  final DateTime lastChecked;
  final String? error;

  const ServiceHealthStatus({
    required this.isHealthy,
    required this.lastChecked,
    this.error,
  });

  @override
  String toString() {
    if (isHealthy) {
      return 'Healthy (checked: $lastChecked)';
    } else {
      return 'Unhealthy (error: $error, checked: $lastChecked)';
    }
  }
}

/// Service health report
class ServiceHealthReport {
  final DateTime timestamp;
  final Map<Type, ServiceHealthStatus> serviceStatus = {};

  ServiceHealthReport({required this.timestamp});

  /// Get overall health status
  bool get isOverallHealthy {
    return serviceStatus.values.every((status) => status.isHealthy);
  }

  /// Get count of healthy services
  int get healthyServiceCount {
    return serviceStatus.values.where((status) => status.isHealthy).length;
  }

  /// Get total service count
  int get totalServiceCount => serviceStatus.length;

  /// Get summary string
  String getSummary() {
    return 'Health Report ($timestamp): $healthyServiceCount/$totalServiceCount services healthy';
  }

  @override
  String toString() => getSummary();
}

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

import '../interfaces/i_platform_detector.dart';
import '../enums/tts_platform.dart';

/// Concrete implementation of platform detection and capability checking
class PlatformDetector implements IPlatformDetector {
  static const MethodChannel _channel = MethodChannel('alouette_tts');
  
  // Cache for platform capabilities to avoid repeated expensive operations
  Map<String, dynamic>? _cachedCapabilities;
  TTSPlatform? _cachedPlatform;
  
  @override
  TTSPlatform getCurrentPlatform() {
    if (_cachedPlatform != null) {
      return _cachedPlatform!;
    }
    
    if (kIsWeb) {
      _cachedPlatform = TTSPlatform.web;
    } else if (Platform.isAndroid) {
      _cachedPlatform = TTSPlatform.android;
    } else if (Platform.isIOS) {
      _cachedPlatform = TTSPlatform.ios;
    } else if (Platform.isLinux) {
      _cachedPlatform = TTSPlatform.linux;
    } else if (Platform.isMacOS) {
      _cachedPlatform = TTSPlatform.macos;
    } else if (Platform.isWindows) {
      _cachedPlatform = TTSPlatform.windows;
    } else {
      // Fallback to web if platform is unknown
      _cachedPlatform = TTSPlatform.web;
    }
    
    return _cachedPlatform!;
  }

  @override
  bool isDesktopPlatform() {
    return getCurrentPlatform().isDesktop;
  }

  @override
  bool isMobilePlatform() {
    return getCurrentPlatform().isMobile;
  }

  @override
  bool isWebPlatform() {
    return getCurrentPlatform().isWeb;
  }

  @override
  Future<bool> isEdgeTTSAvailable() async {
    // Edge TTS is only available on desktop platforms
    if (!isDesktopPlatform()) {
      return false;
    }
    
    try {
      // Try to invoke platform-specific method to check edge-tts availability
      final result = await _channel.invokeMethod<bool>('isEdgeTTSAvailable');
      return result ?? false;
    } catch (e) {
      // If platform channel fails, try alternative detection methods
      return await _fallbackEdgeTTSDetection();
    }
  }

  /// Fallback method to detect Edge TTS availability without platform channels
  Future<bool> _fallbackEdgeTTSDetection() async {
    try {
      // Check if edge-tts is available by trying to access the service
      // This is a simplified check - in production you might want to:
      // - Check for edge-tts Python package installation
      // - Test network connectivity to Microsoft's TTS service
      // - Verify required system dependencies
      
      // For desktop platforms, assume Edge TTS is available via WebSocket connection
      // The actual availability will be determined when creating the service
      if (isDesktopPlatform()) {
        return true; // Enable Edge TTS for desktop platforms
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<String>> getAvailableTTSEngines() async {
    final platform = getCurrentPlatform();
    final engines = <String>[];
    
    // Add flutter-tts as it's available on all platforms
    engines.add('flutter-tts');
    
    // Add edge-tts if available (desktop platforms)
    if (platform.isDesktop && await isEdgeTTSAvailable()) {
      engines.add('edge-tts');
    }
    
    // Add platform-specific engines
    try {
      final platformEngines = await _channel.invokeMethod<List<dynamic>>('getAvailableTTSEngines');
      if (platformEngines != null) {
        engines.addAll(platformEngines.cast<String>());
      }
    } catch (e) {
      // Ignore platform channel errors and continue with basic engines
    }
    
    return engines;
  }

  @override
  Map<String, dynamic> getPlatformCapabilities() {
    if (_cachedCapabilities != null) {
      return Map<String, dynamic>.from(_cachedCapabilities!);
    }
    
    final platform = getCurrentPlatform();
    final capabilities = <String, dynamic>{};
    
    // Set capabilities based on platform
    switch (platform) {
      case TTSPlatform.android:
        capabilities.addAll(_getAndroidCapabilities());
        break;
      case TTSPlatform.ios:
        capabilities.addAll(_getIOSCapabilities());
        break;
      case TTSPlatform.linux:
      case TTSPlatform.macos:
      case TTSPlatform.windows:
        capabilities.addAll(_getDesktopCapabilities());
        break;
      case TTSPlatform.web:
        capabilities.addAll(_getWebCapabilities());
        break;
    }
    
    _cachedCapabilities = capabilities;
    return Map<String, dynamic>.from(capabilities);
  }

  Map<String, dynamic> _getAndroidCapabilities() {
    return {
      'supportsSSML': true,
      'supportsPause': true,
      'supportsVolumeControl': true,
      'supportsPitchControl': true,
      'supportsRateControl': true,
      'maxTextLength': 4000,
      'supportedFormats': ['wav', 'mp3'],
      'supportsFileOutput': true,
      'supportsBatchProcessing': true,
      'supportsVoiceSelection': true,
      'supportsLanguageDetection': false,
    };
  }

  Map<String, dynamic> _getIOSCapabilities() {
    return {
      'supportsSSML': true,
      'supportsPause': true,
      'supportsVolumeControl': true,
      'supportsPitchControl': true,
      'supportsRateControl': true,
      'maxTextLength': 4000,
      'supportedFormats': ['wav', 'mp3'],
      'supportsFileOutput': true,
      'supportsBatchProcessing': true,
      'supportsVoiceSelection': true,
      'supportsLanguageDetection': false,
    };
  }

  Map<String, dynamic> _getDesktopCapabilities() {
    return {
      'supportsSSML': true,
      'supportsPause': true,
      'supportsVolumeControl': true,
      'supportsPitchControl': true,
      'supportsRateControl': true,
      'maxTextLength': 10000, // Edge TTS supports longer texts
      'supportedFormats': ['wav', 'mp3', 'ogg'],
      'supportsFileOutput': true,
      'supportsBatchProcessing': true,
      'supportsVoiceSelection': true,
      'supportsLanguageDetection': true,
      'supportsConnectionPooling': true, // Edge TTS specific
      'supportsWebSocketConnection': true, // Edge TTS specific
    };
  }

  Map<String, dynamic> _getWebCapabilities() {
    return {
      'supportsSSML': false, // Web Speech API has limited SSML support
      'supportsPause': true,
      'supportsVolumeControl': true,
      'supportsPitchControl': true,
      'supportsRateControl': true,
      'maxTextLength': 2000, // Web Speech API limitations
      'supportedFormats': ['wav'], // Limited format support on web
      'supportsFileOutput': false, // File system access limitations
      'supportsBatchProcessing': false, // Limited by browser constraints
      'supportsVoiceSelection': true,
      'supportsLanguageDetection': false,
    };
  }

  @override
  Future<String> getPlatformVersion() async {
    try {
      final version = await _channel.invokeMethod<String>('getPlatformVersion');
      return version ?? 'Unknown';
    } catch (e) {
      // Fallback to basic platform information
      if (kIsWeb) {
        return 'Web';
      } else {
        return Platform.operatingSystemVersion;
      }
    }
  }

  @override
  bool isFeatureSupported(String feature) {
    final capabilities = getPlatformCapabilities();
    
    switch (feature.toLowerCase()) {
      case 'ssml':
        return capabilities['supportsSSML'] ?? false;
      case 'pause':
        return capabilities['supportsPause'] ?? false;
      case 'volume':
        return capabilities['supportsVolumeControl'] ?? false;
      case 'pitch':
        return capabilities['supportsPitchControl'] ?? false;
      case 'rate':
        return capabilities['supportsRateControl'] ?? false;
      case 'fileoutput':
        return capabilities['supportsFileOutput'] ?? false;
      case 'batch':
        return capabilities['supportsBatchProcessing'] ?? false;
      case 'voiceselection':
        return capabilities['supportsVoiceSelection'] ?? false;
      case 'languagedetection':
        return capabilities['supportsLanguageDetection'] ?? false;
      case 'connectionpooling':
        return capabilities['supportsConnectionPooling'] ?? false;
      case 'websocket':
        return capabilities['supportsWebSocketConnection'] ?? false;
      default:
        return false;
    }
  }

  @override
  String getRecommendedTTSImplementation() {
    final platform = getCurrentPlatform();
    
    if (platform.isDesktop) {
      return 'edge-tts';
    } else {
      return 'flutter-tts';
    }
  }

  /// Clears the cached platform information
  /// Useful for testing or when platform capabilities might change
  void clearCache() {
    _cachedCapabilities = null;
    _cachedPlatform = null;
  }
}
/// Enumeration of supported TTS platforms
enum TTSPlatform {
  /// Android mobile platform
  android,
  
  /// iOS mobile platform
  ios,
  
  /// Linux desktop platform
  linux,
  
  /// macOS desktop platform
  macos,
  
  /// Windows desktop platform
  windows,
  
  /// Web platform
  web;

  /// Returns true if this is a desktop platform
  bool get isDesktop {
    switch (this) {
      case TTSPlatform.linux:
      case TTSPlatform.macos:
      case TTSPlatform.windows:
        return true;
      case TTSPlatform.android:
      case TTSPlatform.ios:
      case TTSPlatform.web:
        return false;
    }
  }

  /// Returns true if this is a mobile platform
  bool get isMobile {
    switch (this) {
      case TTSPlatform.android:
      case TTSPlatform.ios:
        return true;
      case TTSPlatform.linux:
      case TTSPlatform.macos:
      case TTSPlatform.windows:
      case TTSPlatform.web:
        return false;
    }
  }

  /// Returns true if this is the web platform
  bool get isWeb => this == TTSPlatform.web;

  /// Returns the platform name as a string
  String get platformName {
    switch (this) {
      case TTSPlatform.android:
        return 'Android';
      case TTSPlatform.ios:
        return 'iOS';
      case TTSPlatform.linux:
        return 'Linux';
      case TTSPlatform.macos:
        return 'macOS';
      case TTSPlatform.windows:
        return 'Windows';
      case TTSPlatform.web:
        return 'Web';
    }
  }
}
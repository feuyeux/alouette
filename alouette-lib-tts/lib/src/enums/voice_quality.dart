/// Enumeration of voice quality levels
enum VoiceQuality {
  /// Standard quality voice
  standard,
  
  /// Premium quality voice
  premium,
  
  /// Neural/AI-generated high-quality voice
  neural;

  /// Returns the quality name as a string
  String get qualityName {
    switch (this) {
      case VoiceQuality.standard:
        return 'Standard';
      case VoiceQuality.premium:
        return 'Premium';
      case VoiceQuality.neural:
        return 'Neural';
    }
  }
  
  /// Creates a VoiceQuality from a string representation
  static VoiceQuality fromString(String quality) {
    switch (quality.toLowerCase()) {
      case 'standard':
      case 'basic':
        return VoiceQuality.standard;
      case 'premium':
      case 'high':
        return VoiceQuality.premium;
      case 'neural':
      case 'ai':
      case 'enhanced':
        return VoiceQuality.neural;
      default:
        return VoiceQuality.standard;
    }
  }

  /// Returns the quality level as an integer (higher is better)
  int get qualityLevel {
    switch (this) {
      case VoiceQuality.standard:
        return 1;
      case VoiceQuality.premium:
        return 2;
      case VoiceQuality.neural:
        return 3;
    }
  }
}
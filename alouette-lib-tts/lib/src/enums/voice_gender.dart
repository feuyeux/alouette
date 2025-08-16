/// Enumeration of voice gender types
enum VoiceGender {
  /// Male voice
  male,
  
  /// Female voice
  female,
  
  /// Neutral or unspecified gender
  neutral;

  /// Returns the gender name as a string
  String get genderName {
    switch (this) {
      case VoiceGender.male:
        return 'Male';
      case VoiceGender.female:
        return 'Female';
      case VoiceGender.neutral:
        return 'Neutral';
    }
  }
  
  /// Creates a VoiceGender from a string representation
  static VoiceGender fromString(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
      case 'm':
        return VoiceGender.male;
      case 'female':
      case 'f':
        return VoiceGender.female;
      case 'neutral':
      case 'n':
      case 'unknown':
      default:
        return VoiceGender.neutral;
    }
  }
}
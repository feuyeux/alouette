/// Validation utilities for consistent data validation across all Alouette applications
///
/// This utility class provides standardized validation methods that can be used
/// by all data models to ensure consistent validation behavior.
class ValidationUtils {
  ValidationUtils._(); // Private constructor to prevent instantiation

  /// Validate a language code format
  ///
  /// Returns true if the language code follows the standard format (e.g., "en", "en-US")
  static bool isValidLanguageCode(String languageCode) {
    if (languageCode.isEmpty) return false;
    return RegExp(r'^[a-z]{2}(-[A-Z]{2})?$').hasMatch(languageCode);
  }

  /// Validate a URL format
  ///
  /// Returns true if the URL is properly formatted
  static bool isValidUrl(String url) {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  /// Validate an email format
  ///
  /// Returns true if the email is properly formatted
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  /// Validate a version string format (semantic versioning)
  ///
  /// Returns true if the version follows semantic versioning (e.g., "1.0.0")
  static bool isValidVersion(String version) {
    if (version.isEmpty) return false;
    return RegExp(
      r'^\d+\.\d+\.\d+(-[a-zA-Z0-9.-]+)?(\+[a-zA-Z0-9.-]+)?$',
    ).hasMatch(version);
  }

  /// Validate a numeric range
  ///
  /// Returns true if the value is within the specified range (inclusive)
  static bool isInRange(num value, num min, num max) {
    return value >= min && value <= max;
  }

  /// Validate text length
  ///
  /// Returns true if the text length is within the specified range
  static bool isValidTextLength(
    String text, {
    int minLength = 0,
    int? maxLength,
  }) {
    if (text.length < minLength) return false;
    if (maxLength != null && text.length > maxLength) return false;
    return true;
  }

  /// Validate that a string is not empty or whitespace-only
  ///
  /// Returns true if the string contains non-whitespace characters
  static bool isNotEmptyOrWhitespace(String text) {
    return text.trim().isNotEmpty;
  }

  /// Validate a list is not empty
  ///
  /// Returns true if the list contains at least one element
  static bool isNotEmptyList<T>(List<T> list) {
    return list.isNotEmpty;
  }

  /// Validate that all items in a list are unique
  ///
  /// Returns true if all items in the list are unique
  static bool hasUniqueItems<T>(List<T> list) {
    return list.length == list.toSet().length;
  }

  /// Validate a map is not empty
  ///
  /// Returns true if the map contains at least one key-value pair
  static bool isNotEmptyMap<K, V>(Map<K, V> map) {
    return map.isNotEmpty;
  }

  /// Validate a file path format
  ///
  /// Returns true if the path appears to be a valid file path
  static bool isValidFilePath(String path) {
    if (path.isEmpty) return false;
    // Basic validation - no invalid characters for most file systems
    return !RegExp(r'[<>:"|?*]').hasMatch(path);
  }

  /// Validate a port number
  ///
  /// Returns true if the port is in the valid range (1-65535)
  static bool isValidPort(int port) {
    return port >= 1 && port <= 65535;
  }

  /// Validate an IP address format (IPv4)
  ///
  /// Returns true if the IP address is properly formatted
  static bool isValidIPv4(String ip) {
    if (ip.isEmpty) return false;
    final parts = ip.split('.');
    if (parts.length != 4) return false;

    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }
    return true;
  }

  /// Create a validation result map
  ///
  /// Helper method to create consistent validation result maps
  static Map<String, dynamic> createValidationResult({
    required bool isValid,
    List<String> errors = const [],
    List<String> warnings = const [],
  }) {
    return {'isValid': isValid, 'errors': errors, 'warnings': warnings};
  }

  /// Validate multiple conditions and combine results
  ///
  /// Takes a list of validation functions and combines their results
  static Map<String, dynamic> combineValidationResults(
    List<Map<String, dynamic>> validationResults,
  ) {
    final allErrors = <String>[];
    final allWarnings = <String>[];
    bool isValid = true;

    for (final result in validationResults) {
      if (!(result['isValid'] as bool)) {
        isValid = false;
      }
      allErrors.addAll(List<String>.from(result['errors'] ?? []));
      allWarnings.addAll(List<String>.from(result['warnings'] ?? []));
    }

    return createValidationResult(
      isValid: isValid,
      errors: allErrors,
      warnings: allWarnings,
    );
  }

  /// Sanitize text input
  ///
  /// Removes potentially harmful characters and trims whitespace
  static String sanitizeText(String text) {
    return text.trim().replaceAll(
      RegExp(r'[^\w\s\-.,!?@#$%^&*()+={}[\]:;"<>/\\|`~]'),
      '',
    );
  }

  /// Normalize a URL
  ///
  /// Ensures the URL has a proper format and removes trailing slashes
  static String normalizeUrl(String url) {
    if (url.isEmpty) return url;

    String normalized = url.trim();

    // Add protocol if missing
    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'http://$normalized';
    }

    // Remove trailing slash
    if (normalized.endsWith('/') && normalized.length > 1) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    return normalized;
  }

  /// Validate and normalize a language code
  ///
  /// Returns a normalized language code or null if invalid
  static String? normalizeLanguageCode(String languageCode) {
    if (languageCode.isEmpty) return null;

    final normalized = languageCode.toLowerCase().trim();

    // Handle common formats
    if (RegExp(r'^[a-z]{2}$').hasMatch(normalized)) {
      return normalized;
    }

    if (RegExp(r'^[a-z]{2}[-_][a-z]{2}$').hasMatch(normalized)) {
      final parts = normalized.split(RegExp(r'[-_]'));
      return '${parts[0]}-${parts[1].toUpperCase()}';
    }

    return null;
  }

  /// Get validation error message for common validation failures
  ///
  /// Provides standardized error messages for common validation scenarios
  static String getValidationErrorMessage(
    String field,
    String validationType, {
    dynamic value,
  }) {
    switch (validationType) {
      case 'required':
        return '$field is required';
      case 'empty':
        return '$field cannot be empty';
      case 'invalid_format':
        return '$field has an invalid format';
      case 'invalid_url':
        return '$field must be a valid URL';
      case 'invalid_email':
        return '$field must be a valid email address';
      case 'invalid_language_code':
        return '$field must be a valid language code (e.g., "en", "en-US")';
      case 'out_of_range':
        return '$field is out of valid range';
      case 'too_short':
        return '$field is too short';
      case 'too_long':
        return '$field is too long';
      case 'duplicate':
        return '$field contains duplicate values';
      default:
        return '$field is invalid${value != null ? ': $value' : ''}';
    }
  }

  /// Get validation warning message for common validation warnings
  ///
  /// Provides standardized warning messages for common validation scenarios
  static String getValidationWarningMessage(
    String field,
    String warningType, {
    dynamic value,
  }) {
    switch (warningType) {
      case 'unusual_format':
        return '$field format may be unusual';
      case 'deprecated':
        return '$field uses a deprecated format';
      case 'performance':
        return '$field may impact performance';
      case 'security':
        return '$field may have security implications';
      case 'compatibility':
        return '$field may have compatibility issues';
      default:
        return '$field may need attention${value != null ? ': $value' : ''}';
    }
  }
}

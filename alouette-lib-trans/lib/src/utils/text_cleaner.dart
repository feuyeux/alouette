/// Utility class for cleaning and processing translation results
class TextCleaner {
  /// Clean translation result by removing unwanted prefixes, suffixes, and formatting
  static String cleanTranslationResult(String rawText, String targetLanguage) {
    if (rawText.trim().isEmpty) {
      return '';
    }

    String cleaned = rawText.trim();

    // Remove common translation prefixes
    cleaned = _removePrefixes(cleaned);
    
    // Remove trailing punctuation that might be artifacts
    cleaned = _removeTrailingArtifacts(cleaned);
    
    // Remove quotes if they wrap the entire text
    cleaned = _removeWrappingQuotes(cleaned);
    
    // Handle multi-line responses by taking the first meaningful line
    cleaned = _extractMainTranslation(cleaned);
    
    // Final cleanup
    cleaned = cleaned.trim();

    // If cleaning resulted in empty text, return the first non-empty line of original
    if (cleaned.isEmpty) {
      cleaned = _fallbackExtraction(rawText);
    }

    return cleaned;
  }

  /// Remove common translation prefixes
  static String _removePrefixes(String text) {
    final prefixPatterns = [
      // English prefixes
      RegExp(r'^translation:\s*', caseSensitive: false),
      RegExp(r'^translated text:\s*', caseSensitive: false),
      RegExp(r'^here is the translation:\s*', caseSensitive: false),
      RegExp(r'^the translation is:\s*', caseSensitive: false),
      RegExp(r'^answer:\s*', caseSensitive: false),
      RegExp(r'^response:\s*', caseSensitive: false),
      RegExp(r'^result:\s*', caseSensitive: false),
      RegExp(r'^output:\s*', caseSensitive: false),
      
      // Numbered prefixes
      RegExp(r'^\d+\.\s*'),
      RegExp(r'^\d+\)\s*'),
      RegExp(r'^[-*]\s*'),
      
      // Generic patterns
      RegExp(r'^[a-zA-Z\s]*:\s*', caseSensitive: false),
    ];

    String result = text;
    for (final pattern in prefixPatterns) {
      result = result.replaceFirst(pattern, '');
    }

    return result.trim();
  }

  /// Remove quotes that wrap the entire text
  static String _removeWrappingQuotes(String text) {
    String result = text.trim();
    
    // Remove outer quotes if they wrap the entire text
    if (result.length >= 2) {
      if ((result.startsWith('"') && result.endsWith('"')) ||
          (result.startsWith("'") && result.endsWith("'")) ||
          (result.startsWith('`') && result.endsWith('`'))) {
        result = result.substring(1, result.length - 1).trim();
      }
      
      // Handle smart quotes
      if ((result.startsWith('"') && result.endsWith('"')) ||
          (result.startsWith(''') && result.endsWith('''))) {
        result = result.substring(1, result.length - 1).trim();
      }
    }

    return result;
  }

  /// Remove trailing artifacts that might be added by the model
  static String _removeTrailingArtifacts(String text) {
    String result = text.trim();
    
    // Remove trailing explanatory text
    final trailingPatterns = [
      RegExp(r'\s*\(.*translation.*\)$', caseSensitive: false),
      RegExp(r'\s*\[.*translation.*\]$', caseSensitive: false),
      RegExp(r'\s*\(.*\)$'), // Remove any parenthetical at the end
      RegExp(r'\s*--.*$'),
      RegExp(r'\s*\.\.\.$'),
    ];

    for (final pattern in trailingPatterns) {
      result = result.replaceFirst(pattern, '');
    }

    return result.trim();
  }

  /// Extract the main translation from multi-line responses
  static String _extractMainTranslation(String text) {
    final lines = text.split('\n').map((line) => line.trim()).toList();
    
    // If single line, return as is
    if (lines.length == 1) {
      return lines.first;
    }

    // Find the first substantial line (not empty, not just punctuation)
    for (final line in lines) {
      if (line.isNotEmpty && _isSubstantialText(line)) {
        return line;
      }
    }

    // Fallback to first non-empty line
    for (final line in lines) {
      if (line.isNotEmpty) {
        return line;
      }
    }

    return text; // Return original if no good line found
  }

  /// Check if text is substantial (not just punctuation or very short)
  static bool _isSubstantialText(String text) {
    if (text.length < 2) return false;
    
    // Check if it's mostly punctuation
    final alphanumericCount = text.replaceAll(RegExp(r'[^\w\s]'), '').length;
    return alphanumericCount >= text.length * 0.5;
  }

  /// Fallback extraction when main cleaning fails
  static String _fallbackExtraction(String rawText) {
    final lines = rawText.split('\n');
    
    // Find first non-empty line
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    
    return rawText.trim();
  }

  /// Validate that the cleaned text is reasonable
  static bool isValidTranslation(String text, String originalText) {
    if (text.trim().isEmpty) return false;
    
    // Check if it's too similar to original (might indicate translation failure)
    if (text.toLowerCase().trim() == originalText.toLowerCase().trim()) {
      return false;
    }
    
    // Check for common error patterns
    final errorPatterns = [
      RegExp(r'^(error|failed|cannot|unable)', caseSensitive: false),
      RegExp(r'(sorry|apologize)', caseSensitive: false),
      RegExp(r"^(i don't|i can't)", caseSensitive: false),
    ];
    
    for (final pattern in errorPatterns) {
      if (pattern.hasMatch(text)) {
        return false;
      }
    }
    
    return true;
  }

  /// Clean and validate translation result
  static String cleanAndValidate(String rawText, String targetLanguage, String originalText) {
    final cleaned = cleanTranslationResult(rawText, targetLanguage);
    
    if (!isValidTranslation(cleaned, originalText)) {
      throw Exception('Invalid translation result: $cleaned');
    }
    
    return cleaned;
  }

  /// Normalize text for comparison (remove extra spaces, normalize case, etc.)
  static String normalizeText(String text) {
    return text
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
        .toLowerCase();
  }

  /// Extract language-specific patterns if needed
  static String cleanLanguageSpecific(String text, String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'zh':
      case 'chinese':
        // Remove common Chinese translation artifacts
        return text.replaceAll(RegExp(r'^翻译[:：]\s*'), '');
      
      case 'ja':
      case 'japanese':
        // Remove common Japanese translation artifacts
        return text.replaceAll(RegExp(r'^翻訳[:：]\s*'), '');
      
      case 'ar':
      case 'arabic':
        // Handle RTL text cleaning if needed
        return text.trim();
      
      default:
        return text;
    }
  }
}
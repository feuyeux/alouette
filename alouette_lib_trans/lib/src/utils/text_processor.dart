/// Utility class for processing and cleaning translation text
class TextProcessor {
  /// Clean translation result by removing unwanted prefixes, suffixes, and formatting
  static String cleanTranslationResult(String rawText, String targetLanguage) {
    if (rawText.trim().isEmpty) {
      return '';
    }

    String cleaned = rawText.trim();

    // Remove think tags and their content
    cleaned = _removeThinkTags(cleaned);

    // Remove common translation prefixes
    cleaned = _removePrefixes(cleaned);

    // Remove trailing punctuation that might be artifacts
    cleaned = _removeTrailingArtifacts(cleaned);

    // Remove quotes if they wrap the entire text
    cleaned = _removeWrappingQuotes(cleaned);

    // Handle multi-line responses by taking the first meaningful line
    cleaned = _extractMainTranslation(cleaned);

    // Remove emoji-only or invalid responses
    cleaned = _removeInvalidContent(cleaned);

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

      // Generic patterns - more specific to avoid removing actual translation content
      RegExp(r'^[a-zA-Z\s]*translation[a-zA-Z\s]*:\s*', caseSensitive: false),
      RegExp(r'^[a-zA-Z\s]*answer[a-zA-Z\s]*:\s*', caseSensitive: false),
      RegExp(r'^[a-zA-Z\s]*response[a-zA-Z\s]*:\s*', caseSensitive: false),
      RegExp(r'^[a-zA-Z\s]*result[a-zA-Z\s]*:\s*', caseSensitive: false),
      RegExp(r'^[a-zA-Z\s]*output[a-zA-Z\s]*:\s*', caseSensitive: false),
    ];

    String result = text;
    for (final pattern in prefixPatterns) {
      result = result.replaceFirst(pattern, '');
    }

    return result.trim();
  }

  /// Remove think tags and their content
  static String _removeThinkTags(String text) {
    String result = text;

    // Remove <think>...</think> blocks including multiline content
    result = result.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '');

    // Remove <thinking>...</thinking> blocks including multiline content
    result = result.replaceAll(
      RegExp(r'<thinking>.*?</thinking>', dotAll: true),
      '',
    );

    // Remove standalone opening/closing tags in case they got separated
    result = result.replaceAll(RegExp(r'</?think>', caseSensitive: false), '');
    result = result.replaceAll(
      RegExp(r'</?thinking>', caseSensitive: false),
      '',
    );

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
    if (text.length < 1) return false;

    // Check if it's mostly punctuation - be more lenient
    final alphanumericCount = text.replaceAll(RegExp(r'[^\w\s]'), '').length;
    return alphanumericCount >= text.length * 0.3; // Reduced from 0.5 to 0.3
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

  /// Remove invalid content like emoji-only responses or nonsense
  static String _removeInvalidContent(String text) {
    if (text.isEmpty) return text;

    // Check if text is only emoji/symbols (no actual letters or meaningful content)
    final hasLetters = RegExp(r'[a-zA-Z\u4e00-\u9fff\u3040-\u309F\u30A0-\u30FF\uAC00-\uD7AF\u0400-\u04FF]').hasMatch(text);
    
    if (!hasLetters && text.length < 10) {
      // Text has no letters and is short - likely emoji/invalid
      return '';
    }

    return text;
  }
}

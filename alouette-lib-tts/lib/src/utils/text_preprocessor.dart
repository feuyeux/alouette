import '../models/alouette_tts_config.dart';
import '../enums/tts_platform.dart';

/// Utility class for preprocessing text before TTS synthesis
class TextPreprocessor {
  /// Maximum text length for different platforms
  static const Map<TTSPlatform, int> _maxTextLengths = {
    TTSPlatform.android: 4000,
    TTSPlatform.ios: 4000,
    TTSPlatform.web: 2000,
    TTSPlatform.linux: 10000,
    TTSPlatform.macos: 10000,
    TTSPlatform.windows: 10000,
  };

  /// Preprocesses text for TTS synthesis
  /// 
  /// [text] - The input text to preprocess
  /// [config] - TTS configuration for context
  /// [platform] - Target platform for platform-specific preprocessing
  /// Returns the preprocessed text
  static String preprocessText(
    String text, {
    AlouetteTTSConfig? config,
    TTSPlatform? platform,
  }) {
    if (text.isEmpty) {
      throw ArgumentError('Text cannot be empty');
    }

    String processedText = text;

    // 1. Normalize whitespace
    processedText = _normalizeWhitespace(processedText);

    // 2. Handle special characters and symbols
    processedText = _processSpecialCharacters(processedText);

    // 3. Apply platform-specific preprocessing
    if (platform != null) {
      processedText = _applyPlatformSpecificProcessing(processedText, platform);
    }

    // 4. Validate text length
    if (platform != null) {
      _validateTextLength(processedText, platform);
    }

    // 5. Apply language-specific preprocessing
    if (config?.languageCode != null) {
      processedText = _applyLanguageSpecificProcessing(
        processedText,
        config!.languageCode,
      );
    }

    return processedText;
  }

  /// Normalizes whitespace in the text
  static String _normalizeWhitespace(String text) {
    // Replace multiple whitespace characters with single spaces
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Processes special characters and symbols
  static String _processSpecialCharacters(String text) {
    // Replace common symbols with spoken equivalents
    final replacements = {
      '&': ' and ',
      '@': ' at ',
      '#': ' hash ',
      '%': ' percent ',
      '+': ' plus ',
      '=': ' equals ',
      '<': ' less than ',
      '>': ' greater than ',
      '|': ' pipe ',
      '~': ' tilde ',
      '^': ' caret ',
      '`': ' backtick ',
    };

    String processedText = text;
    replacements.forEach((symbol, replacement) {
      processedText = processedText.replaceAll(symbol, replacement);
    });

    // Handle URLs
    processedText = _processUrls(processedText);

    // Handle email addresses
    processedText = _processEmails(processedText);

    // Handle numbers and dates
    processedText = _processNumbers(processedText);

    return processedText;
  }

  /// Processes URLs in the text
  static String _processUrls(String text) {
    final urlRegex = RegExp(
      r'https?://[^\s]+',
      caseSensitive: false,
    );

    return text.replaceAllMapped(urlRegex, (match) {
      final url = match.group(0)!;
      // Simplify URL for speech
      if (url.contains('://www.')) {
        return url.replaceFirst(RegExp(r'https?://www\.'), '');
      } else if (url.contains('://')) {
        return url.replaceFirst(RegExp(r'https?://'), '');
      }
      return url;
    });
  }

  /// Processes email addresses in the text
  static String _processEmails(String text) {
    final emailRegex = RegExp(
      r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
    );

    return text.replaceAllMapped(emailRegex, (match) {
      final email = match.group(0)!;
      // Replace @ and . with spoken equivalents
      return email
          .replaceAll('@', ' at ')
          .replaceAll('.', ' dot ');
    });
  }

  /// Processes numbers in the text
  static String _processNumbers(String text) {
    // Handle phone numbers
    text = text.replaceAllMapped(
      RegExp(r'\b\d{3}-\d{3}-\d{4}\b'),
      (match) => match.group(0)!.replaceAll('-', ' '),
    );

    // Handle years (4-digit numbers that look like years)
    text = text.replaceAllMapped(
      RegExp(r'\b(19|20)\d{2}\b'),
      (match) => match.group(0)!,
    );

    return text;
  }

  /// Applies platform-specific text preprocessing
  static String _applyPlatformSpecificProcessing(String text, TTSPlatform platform) {
    switch (platform) {
      case TTSPlatform.web:
        // Web Speech API has limited capabilities
        // Remove complex punctuation that might cause issues
        return text.replaceAll(RegExp(r'[^\w\s.,!?;:\-()"]'), ' ');
      
      case TTSPlatform.android:
      case TTSPlatform.ios:
        // Mobile platforms handle most text well
        return text;
      
      case TTSPlatform.linux:
      case TTSPlatform.macos:
      case TTSPlatform.windows:
        // Desktop platforms with Edge TTS can handle complex text
        return text;
    }
  }

  /// Applies language-specific text preprocessing
  static String _applyLanguageSpecificProcessing(String text, String languageCode) {
    final language = languageCode.toLowerCase();

    if (language.startsWith('zh')) {
      // Chinese text processing
      return _processChineseText(text);
    } else if (language.startsWith('ja')) {
      // Japanese text processing
      return _processJapaneseText(text);
    } else if (language.startsWith('ko')) {
      // Korean text processing
      return _processKoreanText(text);
    } else if (language.startsWith('ar')) {
      // Arabic text processing
      return _processArabicText(text);
    }

    // Default processing for Latin-based languages
    return text;
  }

  /// Processes Chinese text
  static String _processChineseText(String text) {
    // Add spaces between Chinese characters and Latin characters
    return text.replaceAllMapped(
      RegExp(r'([\u4e00-\u9fff])([a-zA-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    ).replaceAllMapped(
      RegExp(r'([a-zA-Z])([\u4e00-\u9fff])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
  }

  /// Processes Japanese text
  static String _processJapaneseText(String text) {
    // Similar processing to Chinese for mixed content
    return text.replaceAllMapped(
      RegExp(r'([\u3040-\u309f\u30a0-\u30ff\u4e00-\u9fff])([a-zA-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    ).replaceAllMapped(
      RegExp(r'([a-zA-Z])([\u3040-\u309f\u30a0-\u30ff\u4e00-\u9fff])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
  }

  /// Processes Korean text
  static String _processKoreanText(String text) {
    // Add spaces between Korean and Latin characters
    return text.replaceAllMapped(
      RegExp(r'([\uac00-\ud7af])([a-zA-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    ).replaceAllMapped(
      RegExp(r'([a-zA-Z])([\uac00-\ud7af])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
  }

  /// Processes Arabic text
  static String _processArabicText(String text) {
    // Add spaces between Arabic and Latin characters
    return text.replaceAllMapped(
      RegExp(r'([\u0600-\u06ff])([a-zA-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    ).replaceAllMapped(
      RegExp(r'([a-zA-Z])([\u0600-\u06ff])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
  }

  /// Validates text length for the target platform
  static void _validateTextLength(String text, TTSPlatform platform) {
    final maxLength = _maxTextLengths[platform] ?? 4000;
    
    if (text.length > maxLength) {
      throw ArgumentError(
        'Text length (${text.length}) exceeds maximum allowed length '
        'for ${platform.platformName} ($maxLength characters)',
      );
    }
  }

  /// Splits long text into chunks suitable for the platform
  static List<String> splitTextIntoChunks(
    String text,
    TTSPlatform platform, {
    int? customMaxLength,
  }) {
    final maxLength = customMaxLength ?? _maxTextLengths[platform] ?? 4000;
    
    if (text.length <= maxLength) {
      return [text];
    }

    final chunks = <String>[];
    final sentences = _splitIntoSentences(text);
    
    String currentChunk = '';
    
    for (final sentence in sentences) {
      if (sentence.length > maxLength) {
        // If a single sentence is too long, split it by words
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk.trim());
          currentChunk = '';
        }
        chunks.addAll(_splitLongSentence(sentence, maxLength));
      } else if (currentChunk.length + sentence.length + 1 <= maxLength) {
        currentChunk += (currentChunk.isEmpty ? '' : ' ') + sentence;
      } else {
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk.trim());
        }
        currentChunk = sentence;
      }
    }
    
    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk.trim());
    }
    
    return chunks;
  }

  /// Splits text into sentences
  static List<String> _splitIntoSentences(String text) {
    // Split on sentence-ending punctuation followed by whitespace or end of string
    final sentences = text
        .split(RegExp(r'[.!?]+\s+|[.!?]+$'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
    
    return sentences;
  }

  /// Splits a long sentence into smaller chunks
  static List<String> _splitLongSentence(String sentence, int maxLength) {
    final words = sentence.split(' ');
    final chunks = <String>[];
    String currentChunk = '';
    
    for (final word in words) {
      if (word.length > maxLength) {
        // If a single word is too long, split it arbitrarily
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk.trim());
          currentChunk = '';
        }
        
        for (int i = 0; i < word.length; i += maxLength) {
          final end = (i + maxLength < word.length) ? i + maxLength : word.length;
          chunks.add(word.substring(i, end));
        }
      } else if (currentChunk.length + word.length + 1 <= maxLength) {
        currentChunk += (currentChunk.isEmpty ? '' : ' ') + word;
      } else {
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk.trim());
        }
        currentChunk = word;
      }
    }
    
    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk.trim());
    }
    
    return chunks;
  }
}
import 'dart:convert';
import '../models/llm_config.dart';
import '../models/connection_status.dart';
import '../exceptions/translation_exceptions.dart';
import '../network/http_client_interface.dart';
import '../utils/logger_config.dart';
import 'base_translation_provider.dart';
import 'dart:async';

/// Ollama translation provider implementation
class OllamaProvider extends TranslationProvider {
  final HttpClient _httpClient;

  OllamaProvider({HttpClient? httpClient})
    : _httpClient = httpClient ?? DefaultHttpClient();

  @override
  String get providerName => 'ollama';

  @override
  Future<String> translateText({
    required String text,
    required String targetLanguage,
    required LLMConfig config,
    Map<String, dynamic>? additionalParams,
  }) async {
    if (!supportsConfig(config)) {
      throw TranslationException('Unsupported provider: ${config.provider}');
    }

    // Use a more specific system prompt for Qwen models
    final String systemPrompt;

    if (config.selectedModel.contains('qwen')) {
      // For Qwen models, use explicit examples to prevent emoji responses
      final langSpec = getExplicitLanguageSpec(targetLanguage);
      final scriptInstruction = _getScriptInstruction(targetLanguage);
      
      systemPrompt =
          '''You are a professional translator. Translate the following text to $langSpec.

CRITICAL RULES:
1. Output ONLY the translated text - nothing else
2. NO explanations, NO thinking process, NO meta-commentary
3. NO emojis, NO symbols, NO English words
4. Use natural, idiomatic expressions that native speakers would use
5. $scriptInstruction
6. Do NOT add any prefixes like "Translation:", "Output:", or similar
7. Do NOT wrap the translation in quotes or any markers

Examples:
- "hello" → "你好" (Chinese) / "こんにちは" (Japanese) / "안녕하세요" (Korean) / "Привет" (Russian)
- "thank you" → "谢谢" (Chinese) / "ありがとう" (Japanese) / "감사합니다" (Korean) / "Спасибо" (Russian)
- "text to translate" → "要翻译的文本" (Chinese) / "翻訳するテキスト" (Japanese) / "번역할 텍스트" (Korean) / "текст для перевода" (Russian)

Now translate to $langSpec:''';
    } else {
      systemPrompt = getSystemPrompt(targetLanguage);
    }

    final apiUrl = '${config.normalizedServerUrl}/api/generate';

    final requestBody = {
      'model': config.selectedModel,
      'prompt': text,
      'system': systemPrompt,
      'stream': false,
      'options': {
        'temperature': 0.3, // Slightly higher for better translations
        'num_predict': 200, // Allow longer outputs for proper translations
        'top_p': 0.5, // More diversity for natural translations
        'repeat_penalty': 1.1,
        'top_k': 40, // More options for word selection
        'num_ctx': 2048,
        'repeat_last_n': 64,
        ...?additionalParams?['options'],
      },
    };

    try {
      final response = await _httpClient.post(
        apiUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
        timeout: const Duration(seconds: 60),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final rawTranslation = responseData['response'] as String?;

        if (rawTranslation == null || rawTranslation.trim().isEmpty) {
          throw TranslationException(
            'Empty translation response from Ollama. Response data: ${responseData.toString()}',
          );
        }

        // Enhanced cleaning to extract only the actual translation
        String cleanedTranslation = rawTranslation.trim();
        
        // Log raw translation for debugging
        transLogger.d('[OLLAMA] Raw translation for $targetLanguage: $rawTranslation');
        
        // Specific cleaning for Qwen models
        if (config.selectedModel.contains('qwen')) {
          List<String> lines = cleanedTranslation.split('\n');
          List<String> validLines = [];
          for (String line in lines) {
            String trimmedLine = line.trim();
            if (trimmedLine.isEmpty ||
                trimmedLine.toLowerCase().contains('let me') ||
                trimmedLine.toLowerCase().contains('first') ||
                trimmedLine.toLowerCase().contains('thinking') ||
                trimmedLine.toLowerCase().contains('translation') ||
                trimmedLine.toLowerCase().contains('user wants') ||
                trimmedLine.contains('<|') ||
                trimmedLine.startsWith('====') ||
                trimmedLine.contains('think>')) {
              continue;
            }
            validLines.add(trimmedLine);
          }
          // 优先选取最后一条有效行，否则返回原始内容
          if (validLines.isNotEmpty) {
            cleanedTranslation = validLines.last;
          } else {
            cleanedTranslation = rawTranslation.trim();
          }
        }

        // Check for mixed scripts (indicates corrupted translation)
        if (_hasMixedScripts(cleanedTranslation)) {
          transLogger.w('[OLLAMA] Mixed scripts detected in translation: $cleanedTranslation');
          transLogger.w('[OLLAMA] Target language: $targetLanguage');
          
          // Try to extract the largest contiguous script block
          final extractedBlock = _extractLargestScriptBlock(cleanedTranslation);
          
          // Validate if extracted block matches target language script
          if (_isValidScriptForLanguage(extractedBlock, targetLanguage)) {
            cleanedTranslation = extractedBlock;
            transLogger.i('[OLLAMA] Successfully extracted valid script block: $cleanedTranslation');
          } else {
            transLogger.e('[OLLAMA] Extracted block does not match target language script');
            // Return error indicator that can be caught upstream for retry
            throw TranslationException(
              'Translation contains mixed scripts and cannot be cleaned for $targetLanguage',
              code: 'MIXED_SCRIPTS_ERROR',
              details: {
                'rawTranslation': rawTranslation,
                'targetLanguage': targetLanguage,
                'extractedBlock': extractedBlock,
              },
            );
          }
        }

        // Remove special characters at the beginning and end
        cleanedTranslation = cleanedTranslation.replaceAll(
          RegExp(r'^[^A-Za-zÀ-ÿ0-9\u0400-\u04FF\u0600-\u06FF\u0900-\u097F\u4E00-\u9FFF\u3040-\u309F\u30A0-\u30FF\uAC00-\uD7AF]*'),
          '',
        );
        cleanedTranslation = cleanedTranslation.replaceAll(
          RegExp(r'[^A-Za-zÀ-ÿ0-9.!?\u0400-\u04FF\u0600-\u06FF\u0900-\u097F\u4E00-\u9FFF\u3040-\u309F\u30A0-\u30FF\uAC00-\uD7AF]*$'),
          '',
        );

        // Final trim
        cleanedTranslation = cleanedTranslation.trim();

        transLogger.d('[OLLAMA] Cleaned translation for $targetLanguage: $cleanedTranslation');

        // If cleaning removed everything, return raw translation
        if (cleanedTranslation.isEmpty) {
          return rawTranslation.trim();
        }

        return cleanedTranslation;
      } else {
        throw TranslationException(
          'Ollama API request failed: HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      if (e is TranslationException) {
        rethrow;
      }
      throw TranslationException('Ollama translation failed: ${e.toString()}');
    }
  }

  @override
  Future<ConnectionStatus> testConnection(LLMConfig config) async {
    final startTime = DateTime.now();

    try {
      final apiUrl = '${config.normalizedServerUrl}/api/tags';
      final response = await _httpClient.get(
        apiUrl,
        timeout: const Duration(seconds: 10),
      );

      final responseTime = DateTime.now().difference(startTime).inMilliseconds;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = data['models'] as List?;
        final modelCount = models?.length ?? 0;

        return ConnectionStatus.success(
          message: 'Successfully connected to Ollama server',
          modelCount: modelCount,
          responseTimeMs: responseTime,
          details: {'models': models?.map((m) => m['name']).toList()},
        );
      } else {
        return ConnectionStatus.failure(
          message: 'Ollama server returned error: ${response.statusCode}',
          responseTimeMs: responseTime,
          details: {'statusCode': response.statusCode, 'body': response.body},
        );
      }
    } catch (e) {
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;

      if (e is TranslationException) {
        return ConnectionStatus.failure(
          message: 'Ollama connection test failed: ${e.toString()}',
          responseTimeMs: responseTime,
          details: {'error': e.toString()},
        );
      }

      return ConnectionStatus.failure(
        message: 'Ollama connection test failed: ${e.toString()}',
        responseTimeMs: responseTime,
        details: {'error': e.toString()},
      );
    }
  }

  /// Check if text contains mixed scripts (e.g., Devanagari + Arabic + Cyrillic)
  bool _hasMixedScripts(String text) {
    final hasDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(text);
    final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    final hasCyrillic = RegExp(r'[\u0400-\u04FF]').hasMatch(text);
    final hasLatin = RegExp(r'[A-Za-z]').hasMatch(text);
    final hasCJK = RegExp(r'[\u4E00-\u9FFF\u3040-\u309F\u30A0-\u30FF]').hasMatch(text);
    final hasKorean = RegExp(r'[\uAC00-\uD7AF]').hasMatch(text);
    
    // Count how many different scripts are present
    int scriptCount = 0;
    if (hasDevanagari) scriptCount++;
    if (hasArabic) scriptCount++;
    if (hasCyrillic) scriptCount++;
    if (hasLatin) scriptCount++;
    if (hasCJK) scriptCount++;
    if (hasKorean) scriptCount++;
    
    // If more than 2 scripts, it's likely corrupted
    return scriptCount > 2;
  }

  /// Extract the largest contiguous block of a single script
  String _extractLargestScriptBlock(String text) {
    // Define script patterns
    final scripts = {
      'devanagari': RegExp(r'[\u0900-\u097F\s]+'),
      'arabic': RegExp(r'[\u0600-\u06FF\s]+'),
      'cyrillic': RegExp(r'[\u0400-\u04FF\s]+'),
      'latin': RegExp(r'[A-Za-zÀ-ÿ\s]+'),
      'cjk': RegExp(r'[\u4E00-\u9FFF\u3040-\u309F\u30A0-\u30FF\s]+'),
      'korean': RegExp(r'[\uAC00-\uD7AF\s]+'),
    };
    
    String longestBlock = '';
    String longestScriptName = '';
    
    for (final entry in scripts.entries) {
      final matches = entry.value.allMatches(text);
      for (final match in matches) {
        final block = match.group(0)?.trim() ?? '';
        if (block.length > longestBlock.length) {
          longestBlock = block;
          longestScriptName = entry.key;
        }
      }
    }
    
    if (longestBlock.isNotEmpty) {
      transLogger.d('[OLLAMA] Extracted $longestScriptName script block: $longestBlock');
    }
    
    return longestBlock.isNotEmpty ? longestBlock : text;
  }

  /// Get script-specific instruction for the target language
  String _getScriptInstruction(String targetLanguage) {
    final normalized = targetLanguage.toLowerCase().trim();
    final lang = normalized.split('-').first.split('_').first;
    
    switch (lang) {
      case 'hindi':
      case 'hi':
      case 'in':
        return 'Use ONLY Devanagari script (देवनागरी लिपि). Do NOT mix with Arabic, Cyrillic, or any other scripts.';
      
      case 'arabic':
      case 'ar':
      case 'sa':
        return 'Use ONLY Arabic script (الأبجدية العربية). Do NOT mix with other scripts.';
      
      case 'russian':
      case 'ru':
        return 'Use ONLY Cyrillic script (кириллица). Do NOT mix with other scripts.';
      
      case 'chinese':
      case 'zh':
      case 'cn':
        return 'Use ONLY Chinese characters (汉字). Do NOT mix with other scripts.';
      
      case 'japanese':
      case 'ja':
      case 'jp':
        return 'Use ONLY Japanese scripts (hiragana, katakana, kanji). Do NOT mix with other scripts.';
      
      case 'korean':
      case 'ko':
      case 'kr':
        return 'Use ONLY Hangul script (한글). Do NOT mix with other scripts.';
      
      case 'greek':
      case 'el':
      case 'gr':
        return 'Use ONLY Greek alphabet (ελληνικό αλφάβητο). Do NOT mix with other scripts.';
      
      default:
        return 'Use ONLY the native script of the target language. Do NOT mix scripts.';
    }
  }

  /// Validate if the extracted script matches the target language
  bool _isValidScriptForLanguage(String text, String targetLanguage) {
    final normalized = targetLanguage.toLowerCase().trim();
    final lang = normalized.split('-').first.split('_').first;
    
    // Define expected scripts for each language
    switch (lang) {
      case 'hindi':
      case 'hi':
      case 'in':
        return RegExp(r'[\u0900-\u097F]').hasMatch(text);
      
      case 'arabic':
      case 'ar':
      case 'sa':
        return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
      
      case 'russian':
      case 'ru':
        return RegExp(r'[\u0400-\u04FF]').hasMatch(text);
      
      case 'chinese':
      case 'zh':
      case 'cn':
        return RegExp(r'[\u4E00-\u9FFF]').hasMatch(text);
      
      case 'japanese':
      case 'ja':
      case 'jp':
        return RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]').hasMatch(text);
      
      case 'korean':
      case 'ko':
      case 'kr':
        return RegExp(r'[\uAC00-\uD7AF]').hasMatch(text);
      
      case 'greek':
      case 'el':
      case 'gr':
        return RegExp(r'[\u0370-\u03FF]').hasMatch(text);
      
      // Latin-based languages
      case 'english':
      case 'en':
      case 'french':
      case 'fr':
      case 'german':
      case 'de':
      case 'spanish':
      case 'es':
      case 'italian':
      case 'it':
      case 'portuguese':
      case 'pt':
        return RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(text);
      
      default:
        // For unknown languages, accept any non-empty text
        return text.trim().isNotEmpty;
    }
  }

  @override
  Future<List<String>> getAvailableModels(LLMConfig config) async {
    try {
      final apiUrl = '${config.normalizedServerUrl}/api/tags';
      final response = await _httpClient.get(
        apiUrl,
        timeout: const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = data['models'] as List?;

        if (models != null) {
          return models
              .map((model) => model['name'] as String? ?? '')
              .where((name) => name.isNotEmpty)
              .toList();
        }
      } else {
        throw TranslationException(
          'Ollama API request failed: HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      if (e is TranslationException) {
        rethrow;
      }
      throw TranslationException('Ollama translation failed: ${e.toString()}');
    }

    return [];
  }
}

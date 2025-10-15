import 'dart:convert';
import '../models/llm_config.dart';
import '../models/connection_status.dart';
import '../exceptions/translation_exceptions.dart';
import '../network/http_client_interface.dart';
import '../utils/text_processor.dart';
import 'base_translation_provider.dart';
import 'dart:async';

/// LM Studio translation provider implementation
class LMStudioProvider extends TranslationProvider {
  final HttpClient _httpClient;

  LMStudioProvider({HttpClient? httpClient})
    : _httpClient = httpClient ?? DefaultHttpClient();

  @override
  String get providerName => 'lmstudio';

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

    final systemPrompt = getSystemPrompt(targetLanguage);
    final apiUrl = '${config.normalizedServerUrl}/v1/chat/completions';

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': text},
    ];

    final requestBody = {
      'model': config.selectedModel,
      'messages': messages,
      'temperature': 0.1,
      'max_tokens': 150,
      'stream': false,
      ...?additionalParams,
    };

    final headers = {'Content-Type': 'application/json'};

    try {
      final response = await _httpClient.post(
        apiUrl,
        headers: headers,
        body: json.encode(requestBody),
        timeout: const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final choices = responseData['choices'] as List?;

        if (choices != null && choices.isNotEmpty) {
          final choice = choices.first;
          final message = choice['message'];
          final rawTranslation = message['content'] as String?;

          if (rawTranslation != null && rawTranslation.trim().isNotEmpty) {
            // Use TextProcessor for consistent cleaning across the library
            String cleanedTranslation = TextProcessor.cleanTranslationResult(
              rawTranslation,
              targetLanguage,
            );

            if (cleanedTranslation.trim().isEmpty) {
              throw InvalidTranslationException(
                'Translation result is empty after cleaning',
                text,
                targetLanguage,
              );
            }

            return cleanedTranslation;
          }
        }

        throw TranslationException(
          'No valid translation in LM Studio response',
        );
      } else {
        throw TranslationException(
          'LM Studio API request failed: HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      if (e is TranslationException) {
        rethrow;
      }
      throw TranslationException(
        'LM Studio translation failed: ${e.toString()}',
      );
    }
  }

  @override
  Future<ConnectionStatus> testConnection(LLMConfig config) async {
    final startTime = DateTime.now();

    try {
      final apiUrl = '${config.normalizedServerUrl}/v1/models';

      final headers = {'Content-Type': 'application/json'};

      final response = await _httpClient.get(
        apiUrl,
        headers: headers,
        timeout: const Duration(seconds: 10),
      );

      final responseTime = DateTime.now().difference(startTime).inMilliseconds;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = data['data'] as List?;
        final modelCount = models?.length ?? 0;

        return ConnectionStatus.success(
          message: 'Successfully connected to LM Studio server',
          modelCount: modelCount,
          responseTimeMs: responseTime,
          details: {'models': models?.map((m) => m['id']).toList()},
        );
      } else {
        return ConnectionStatus.failure(
          message: 'LM Studio server returned error: ${response.statusCode}',
          responseTimeMs: responseTime,
          details: {'statusCode': response.statusCode, 'body': response.body},
        );
      }
    } catch (e) {
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;

      if (e is TranslationException) {
        return ConnectionStatus.failure(
          message: 'LM Studio connection test failed: ${e.toString()}',
          responseTimeMs: responseTime,
          details: {'error': e.toString()},
        );
      }

      return ConnectionStatus.failure(
        message: 'LM Studio connection test failed: ${e.toString()}',
        responseTimeMs: responseTime,
        details: {'error': e.toString()},
      );
    }
  }

  @override
  Future<List<String>> getAvailableModels(LLMConfig config) async {
    try {
      final apiUrl = '${config.normalizedServerUrl}/v1/models';

      final headers = {'Content-Type': 'application/json'};

      final response = await _httpClient.get(
        apiUrl,
        headers: headers,
        timeout: const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = data['data'] as List?;

        if (models != null) {
          return models
              .map((model) => model['id'] as String? ?? '')
              .where((id) => id.isNotEmpty)
              .toList();
        }
      } else {
        throw TranslationException(
          'LM Studio API request failed: HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      if (e is TranslationException) {
        rethrow;
      }
      throw TranslationException(
        'LM Studio translation failed: ${e.toString()}',
      );
    }

    return [];
  }
}

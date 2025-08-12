import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/llm_config.dart';
import '../models/connection_status.dart';
import '../exceptions/translation_exceptions.dart';
import '../utils/text_cleaner.dart';
import 'translation_provider.dart';

/// LM Studio translation provider implementation
class LMStudioProvider extends TranslationProvider {
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
    final apiUrl = '${config.serverUrl.trimRight()}/v1/chat/completions';

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
    if (config.apiKey != null && config.apiKey!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${config.apiKey}';
    }

    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: headers,
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final choices = responseData['choices'] as List?;

        if (choices != null && choices.isNotEmpty) {
          final choice = choices.first;
          final message = choice['message'];
          final rawTranslation = message['content'] as String?;

          if (rawTranslation != null && rawTranslation.trim().isNotEmpty) {
            final cleanedTranslation = TextCleaner.cleanTranslationResult(
              rawTranslation.trim(),
              targetLanguage,
            );
            
            if (cleanedTranslation.trim().isEmpty) {
              throw TranslationException('Translation result is empty after cleaning');
            }
            
            return cleanedTranslation;
          }
        }

        throw TranslationException('No valid translation in LM Studio response');
      } else if (response.statusCode == 401) {
        throw LLMAuthenticationException('Authentication failed. Please check your API key.');
      } else if (response.statusCode == 404) {
        throw LLMModelNotFoundException('Model "${config.selectedModel}" not found. Please check if the model is available.', config.selectedModel);
      } else {
        final errorText = response.body;
        throw TranslationException('LM Studio API request failed: HTTP ${response.statusCode}: $errorText');
      }
    } catch (e) {
      if (e is TranslationException) rethrow;
      
      if (e.toString().contains('Connection refused') || e.toString().contains('network')) {
        throw LLMConnectionException(
          'Cannot connect to LM Studio server at ${config.serverUrl}. Please check if the server is running and accessible.',
        );
      } else if (e.toString().contains('timeout')) {
        throw TranslationTimeoutException('Translation request timed out. The server may be overloaded.');
      } else {
        throw TranslationException('LM Studio translation failed: ${e.toString()}');
      }
    }
  }

  @override
  Future<ConnectionStatus> testConnection(LLMConfig config) async {
    final startTime = DateTime.now();
    
    try {
      final apiUrl = '${config.serverUrl.trimRight()}/v1/models';
      
      final headers = {'Content-Type': 'application/json'};
      if (config.apiKey != null && config.apiKey!.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${config.apiKey}';
      }
      
      final response = await http
          .get(Uri.parse(apiUrl), headers: headers)
          .timeout(const Duration(seconds: 10));

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
      } else if (response.statusCode == 401) {
        return ConnectionStatus.failure(
          message: 'Authentication failed. Please check your API key.',
          responseTimeMs: responseTime,
          details: {'statusCode': response.statusCode},
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
      
      if (e.toString().contains('Connection refused') || e.toString().contains('network')) {
        return ConnectionStatus.failure(
          message: 'Cannot connect to LM Studio server at ${config.serverUrl}',
          responseTimeMs: responseTime,
          details: {'error': e.toString()},
        );
      } else if (e.toString().contains('timeout')) {
        return ConnectionStatus.failure(
          message: 'Connection to LM Studio server timed out',
          responseTimeMs: responseTime,
          details: {'error': e.toString()},
        );
      } else {
        return ConnectionStatus.failure(
          message: 'LM Studio connection test failed: ${e.toString()}',
          responseTimeMs: responseTime,
          details: {'error': e.toString()},
        );
      }
    }
  }

  @override
  Future<List<String>> getAvailableModels(LLMConfig config) async {
    try {
      final apiUrl = '${config.serverUrl.trimRight()}/v1/models';
      
      final headers = {'Content-Type': 'application/json'};
      if (config.apiKey != null && config.apiKey!.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${config.apiKey}';
      }
      
      final response = await http
          .get(Uri.parse(apiUrl), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = data['data'] as List?;
        
        if (models != null) {
          return models
              .map((model) => model['id'] as String? ?? '')
              .where((id) => id.isNotEmpty)
              .toList();
        }
      } else if (response.statusCode == 401) {
        throw LLMAuthenticationException('Authentication failed. Please check your API key.');
      } else {
        throw LLMConnectionException('Failed to fetch models: HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (e is TranslationException) rethrow;
      throw LLMConnectionException('Failed to get available models: ${e.toString()}');
    }
    
    return [];
  }
}
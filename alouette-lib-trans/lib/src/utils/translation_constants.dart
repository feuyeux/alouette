/// Constants used throughout the translation library
class TranslationConstants {
  /// Default timeout for translation requests
  static const Duration defaultTimeout = Duration(seconds: 30);
  
  /// Default timeout for connection tests
  static const Duration connectionTimeout = Duration(seconds: 10);
  
  /// Maximum number of retry attempts for failed requests
  static const int maxRetryAttempts = 3;
  
  /// Default temperature for translation requests (lower = more deterministic)
  static const double defaultTemperature = 0.1;
  
  /// Default maximum tokens for translation responses
  static const int defaultMaxTokens = 150;
  
  /// Supported providers
  static const List<String> supportedProviders = ['ollama', 'lmstudio'];
  
  /// Default server URLs for each provider
  static const Map<String, String> defaultServerUrls = {
    'ollama': 'http://localhost:11434',
    'lmstudio': 'http://localhost:1234',
  };
  
  /// Default ports for each provider
  static const Map<String, int> defaultPorts = {
    'ollama': 11434,
    'lmstudio': 1234,
  };
  
  /// API endpoints for each provider
  static const Map<String, Map<String, String>> apiEndpoints = {
    'ollama': {
      'generate': '/api/generate',
      'models': '/api/tags',
      'show': '/api/show',
    },
    'lmstudio': {
      'chat': '/v1/chat/completions',
      'models': '/v1/models',
      'completions': '/v1/completions',
    },
  };
  
  /// Common language codes and their display names
  static const Map<String, String> languageNames = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'ru': 'Russian',
    'ja': 'Japanese',
    'ko': 'Korean',
    'zh': 'Chinese (Simplified)',
    'zh-tw': 'Chinese (Traditional)',
    'ar': 'Arabic',
    'hi': 'Hindi',
    'th': 'Thai',
    'vi': 'Vietnamese',
    'nl': 'Dutch',
    'sv': 'Swedish',
    'da': 'Danish',
    'no': 'Norwegian',
    'fi': 'Finnish',
    'pl': 'Polish',
    'cs': 'Czech',
    'hu': 'Hungarian',
    'ro': 'Romanian',
    'bg': 'Bulgarian',
    'hr': 'Croatian',
    'sk': 'Slovak',
    'sl': 'Slovenian',
    'et': 'Estonian',
    'lv': 'Latvian',
    'lt': 'Lithuanian',
    'el': 'Greek',
    'tr': 'Turkish',
    'he': 'Hebrew',
    'fa': 'Persian',
    'ur': 'Urdu',
    'bn': 'Bengali',
    'ta': 'Tamil',
    'te': 'Telugu',
    'ml': 'Malayalam',
    'kn': 'Kannada',
    'gu': 'Gujarati',
    'pa': 'Punjabi',
    'mr': 'Marathi',
    'ne': 'Nepali',
    'si': 'Sinhala',
    'my': 'Myanmar',
    'km': 'Khmer',
    'lo': 'Lao',
    'ka': 'Georgian',
    'am': 'Amharic',
    'sw': 'Swahili',
    'zu': 'Zulu',
    'af': 'Afrikaans',
    'is': 'Icelandic',
    'mt': 'Maltese',
    'cy': 'Welsh',
    'ga': 'Irish',
    'gd': 'Scottish Gaelic',
    'eu': 'Basque',
    'ca': 'Catalan',
    'gl': 'Galician',
  };
  
  /// Language codes that use right-to-left text direction
  static const List<String> rtlLanguages = [
    'ar', 'he', 'fa', 'ur', 'ps', 'sd', 'ku', 'dv'
  ];
  
  /// Common error messages
  static const Map<String, String> errorMessages = {
    'emptyText': 'Please enter text to translate',
    'noLanguages': 'Please select at least one target language',
    'noConfig': 'Please configure LLM settings first',
    'unsupportedProvider': 'Unsupported provider',
    'connectionFailed': 'Failed to connect to the server',
    'authenticationFailed': 'Authentication failed',
    'modelNotFound': 'Model not found',
    'timeout': 'Request timed out',
    'invalidResponse': 'Invalid response from server',
    'emptyTranslation': 'Empty translation received',
    'rateLimitExceeded': 'Rate limit exceeded',
  };
  
  /// HTTP status codes and their meanings
  static const Map<int, String> httpStatusMessages = {
    200: 'OK',
    400: 'Bad Request',
    401: 'Unauthorized',
    403: 'Forbidden',
    404: 'Not Found',
    429: 'Too Many Requests',
    500: 'Internal Server Error',
    502: 'Bad Gateway',
    503: 'Service Unavailable',
    504: 'Gateway Timeout',
  };
  
  /// Default request options for different providers
  static const Map<String, Map<String, dynamic>> defaultRequestOptions = {
    'ollama': {
      'temperature': 0.1,
      'num_predict': 150,
      'top_p': 0.1,
      'repeat_penalty': 1.05,
      'top_k': 10,
      'num_ctx': 2048,
      'repeat_last_n': 64,
      'stop': ['\n\n', 'Translation:', 'Explanation:', 'Note:', 'Original:', 'Source:'],
    },
    'lmstudio': {
      'temperature': 0.1,
      'max_tokens': 150,
      'top_p': 0.1,
      'frequency_penalty': 0.0,
      'presence_penalty': 0.0,
    },
  };
  
  /// Validation patterns
  static const Map<String, String> validationPatterns = {
    'url': r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    'ipAddress': r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    'port': r'^([1-9][0-9]{0,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$',
    'languageCode': r'^[a-z]{2}(-[A-Z]{2})?$',
  };
  
  /// Configuration keys for storage
  static const Map<String, String> configKeys = {
    'provider': 'llm_provider',
    'serverUrl': 'llm_server_url',
    'apiKey': 'llm_api_key',
    'selectedModel': 'llm_selected_model',
    'lastUsed': 'llm_last_used',
    'autoSave': 'llm_auto_save',
  };
  
  /// Feature flags
  static const Map<String, bool> features = {
    'autoRetry': true,
    'caching': false,
    'analytics': false,
    'offlineMode': false,
    'batchTranslation': true,
    'customProviders': true,
  };
}
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
    'ar',
    'he',
    'fa',
    'ur',
    'ps',
    'sd',
    'ku',
    'dv',
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

  /// Default request options for different providers
  static const Map<String, Map<String, dynamic>> defaultRequestOptions = {
    'ollama': {
      'temperature': 0.3, // Increased from 0.1 for better translation quality
      'num_predict': 150,
      'top_p': 0.3, // Increased from 0.1 for more diverse output
      'repeat_penalty': 1.05,
      'top_k': 20, // Increased from 10 for better quality
      'num_ctx': 2048,
      'repeat_last_n': 64,
    },
    'lmstudio': {
      'temperature': 0.1,
      'max_tokens': 150,
      'top_p': 0.1,
      'frequency_penalty': 0.0,
      'presence_penalty': 0.0,
    },
  };

  /// Validation pattern for language code
  static const String languageCodePattern = r'^[a-z]{2}(-[A-Z]{2})?$';
}

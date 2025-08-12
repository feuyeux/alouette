/// A Flutter library for AI-powered translation functionality.
/// 
/// This library provides a unified API for integrating AI translation
/// capabilities into Flutter applications, with support for multiple
/// LLM providers including Ollama and LM Studio.
library alouette_lib_trans;

// Models
export 'src/models/llm_config.dart';
export 'src/models/translation_request.dart';
export 'src/models/translation_result.dart';
export 'src/models/connection_status.dart';

// Services
export 'src/services/translation_service.dart';
export 'src/services/llm_config_service.dart';

// Providers
export 'src/providers/translation_provider.dart';
export 'src/providers/ollama_provider.dart';
export 'src/providers/lmstudio_provider.dart';

// Exceptions
export 'src/exceptions/translation_exceptions.dart';

// Utils
export 'src/utils/translation_constants.dart';
export 'src/utils/text_cleaner.dart';
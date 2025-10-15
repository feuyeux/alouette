import 'dart:async';

import 'package:flutter/material.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import 'package:alouette_lib_tts/alouette_tts.dart' as tts_lib;

import '../../components/organisms/translation_page_base.dart';
import '../../dialogs/llm_config_dialog.dart';
import '../../services/core/configuration_manager.dart';
import '../../services/core/service_locator.dart';
import '../../utils/ui_utils.dart';

/// High-level translation experience widget that encapsulates
/// text input, language selection, translation results, and optional TTS.
///
/// Applications can embed this widget directly to get a fully wired
/// translation workflow with minimal glue code.
class TranslationPageView extends StatefulWidget {
  /// Whether to expose TTS playback controls in the results area.
  final bool enableTTS;

  /// Whether to use the compact layout variant.
  final bool isCompactLayout;

  const TranslationPageView({
    super.key,
    this.enableTTS = false,
    this.isCompactLayout = true,
  });

  @override
  State<TranslationPageView> createState() => _TranslationPageViewState();
}

class _TranslationPageViewState extends State<TranslationPageView> {
  final TextEditingController _textController = TextEditingController();
  final Set<String> _selectedLanguages = <String>{};
  bool _isTranslating = false;
  bool _isConfigurationLoaded = false;

  late final TranslationService _translationService;
  tts_lib.TTSService? _ttsService;
  ConfigurationManager? _configurationManager;
  LLMConfig _manualConfig = const LLMConfig(
    provider: 'ollama',
    serverUrl: 'http://localhost:11434',
    selectedModel: '',
  );

  @override
  void initState() {
    super.initState();
    _translationService = ServiceLocator.get<TranslationService>();
    _translationService.addListener(_onTranslationServiceChanged);

    if (widget.enableTTS && ServiceLocator.isRegistered<tts_lib.TTSService>()) {
      _ttsService = ServiceLocator.get<tts_lib.TTSService>();
    }

    _loadStoredConfiguration();
  }

  Future<void> _loadStoredConfiguration() async {
    try {
      _configurationManager = ServiceLocator.get<ConfigurationManager>();
      await _configurationManager!.initialize();
      final appConfig = await _configurationManager!.getConfiguration();
      if (!mounted) return;
      final savedConfig = appConfig.translationConfig;
      
      final logger = ServiceLocator.logger;
      logger.info('TranslationPageView: Loaded configuration', tag: 'Translation', details: {
        'hasSavedConfig': savedConfig != null,
        'provider': savedConfig?.provider ?? 'none',
        'serverUrl': savedConfig?.serverUrl ?? 'none',
        'model': savedConfig?.selectedModel ?? 'none',
      });
      
      setState(() {
        if (savedConfig != null) {
          _manualConfig = savedConfig;
        }
        _isConfigurationLoaded = true;
      });
      
      // If no manual config is set, try to auto-detect
      if (_manualConfig.selectedModel.isEmpty) {
        logger.info('TranslationPageView: No manual config, attempting auto-detection', tag: 'Translation');
        final autoConfig = await _translationService.autoConfigureLLM(enableRetry: false);
        if (autoConfig != null && autoConfig.selectedModel.isNotEmpty) {
          logger.info('TranslationPageView: Auto-detected config available', tag: 'Translation', details: {
            'provider': autoConfig.provider,
            'serverUrl': autoConfig.serverUrl,
            'model': autoConfig.selectedModel,
          });
          
          setState(() {
            _manualConfig = autoConfig;
          });
          await _persistConfiguration(autoConfig);
        }
      }
    } catch (e) {
      final logger = ServiceLocator.logger;
      logger.error('TranslationPageView: Failed to load configuration', tag: 'Translation', error: e);
      if (!mounted) return;
      setState(() {
        _isConfigurationLoaded = true;
      });
      // Ignore configuration bootstrap errors – users can configure manually.
    }
  }

  void _onTranslationServiceChanged() {
    if (!mounted) return;
    
    final logger = ServiceLocator.logger;
    
    logger.debug('TranslationPageView: Service changed', tag: 'Translation', details: {
      'manualModel': _manualConfig.selectedModel,
      'isConfigured': _isConfigured,
    });
    
    // Just trigger rebuild for state updates
    setState(() {});
  }

  Future<void> _persistConfiguration(LLMConfig config) async {
    try {
      _configurationManager ??= ServiceLocator.get<ConfigurationManager>();
      await _configurationManager!.initialize();
      await _configurationManager!.updateTranslationConfig(config);
    } catch (_) {
      // Non-fatal – persistence failure should not block the UI flow.
    }
  }

  @override
  void dispose() {
    _translationService.removeListener(_onTranslationServiceChanged);
    _textController.dispose();
    super.dispose();
  }

  List<String> get _languages => _selectedLanguages.toList(growable: false);

  bool get _isConfigured {
    // Check if we have a valid manual config or still loading
    if (_manualConfig.selectedModel.isNotEmpty) return true;
    return !_isConfigurationLoaded;
  }

  void _onLanguagesChanged(List<String> languages) {
    setState(() {
      _selectedLanguages
        ..clear()
        ..addAll(languages);
    });
    _translationService.clearTranslation();
  }

  void _onLanguageToggle(String language, bool selected) {
    setState(() {
      if (selected) {
        _selectedLanguages.add(language);
      } else {
        _selectedLanguages.remove(language);
      }
    });
    _translationService.clearTranslation();
  }

  void _onTranslate() {
    unawaited(_handleTranslate());
  }

  Future<void> _handleTranslate() async {
    final input = _textController.text.trim();
    if (input.isEmpty) {
      context.showErrorMessage('Please enter text to translate');
      return;
    }

    if (_selectedLanguages.isEmpty) {
      context.showErrorMessage('Please select target languages');
      return;
    }

    setState(() => _isTranslating = true);

    try {
      final configToUse = _manualConfig.selectedModel.isNotEmpty
          ? _manualConfig
          : null;

      final result = await _translationService.translateWithAutoConfig(
        input,
        _languages,
        config: configToUse,
      );

      if (!mounted) return;

      setState(() => _isTranslating = false);

      if (result.config.selectedModel.isNotEmpty &&
          result.config != _manualConfig) {
        setState(() {
          _manualConfig = result.config;
        });
        await _persistConfiguration(result.config);
      }
    } on ConfigurationException catch (error) {
      if (!mounted) return;
      setState(() => _isTranslating = false);
      await _handleConfigurationError(error);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isTranslating = false);
      await ErrorUtils.handleError(context, error, onRetry: _handleTranslate);
    }
  }

  Future<void> _handleConfigurationError(Object error) async {
    context.showErrorMessage(error.toString());
    await _showConfigDialog();
  }

  Future<void> _showConfigDialog() async {
    final result = await showTranslationConfigDialog(
      context,
      fallbackConfig: _manualConfig,
    );

    if (result != null && mounted) {
      setState(() {
        _manualConfig = result;
      });
      await _persistConfiguration(result);
      context.showSuccessMessage('Configuration updated successfully');
    }
  }

  void _clearResults() {
    _translationService.clearTranslation();
    setState(() => _isTranslating = false);
  }

  @override
  Widget build(BuildContext context) {
    final ttsService = widget.enableTTS ? _ttsService : null;

    return TranslationPageBase(
      translationService: _translationService,
      ttsService: ttsService,
      showTTS: widget.enableTTS,
      isCompactMode: widget.isCompactLayout,
      textController: _textController,
      selectedLanguages: _languages,
      onLanguagesChanged: _onLanguagesChanged,
      onLanguageToggle: _onLanguageToggle,
      onTranslate: _onTranslate,
      onClearResults: _clearResults,
      isTranslating: _isTranslating,
      isConfigured: _isConfigured,
    );
  }
}

/// Helper that opens the shared LLM configuration dialog, persists the result,
/// and returns the newly saved configuration (if any).
Future<LLMConfig?> showTranslationConfigDialog(
  BuildContext context, {
  LLMConfig? fallbackConfig,
}) async {
  final translationService = ServiceLocator.get<TranslationService>();
  ConfigurationManager? configurationManager;

  LLMConfig initialConfig =
      fallbackConfig ??
      const LLMConfig(
        provider: 'ollama',
        serverUrl: 'http://localhost:11434',
        selectedModel: '',
      );

  try {
    configurationManager = ServiceLocator.get<ConfigurationManager>();
    await configurationManager.initialize();
    final appConfig = await configurationManager.getConfiguration();
    initialConfig =
        appConfig.translationConfig ??
        initialConfig;
  } catch (_) {
    // Configuration manager might not be available yet – fall back gracefully.
  }

  final result = await showDialog<LLMConfig>(
    context: context,
    builder: (context) => LLMConfigDialog(
      initialConfig: initialConfig,
      translationService: translationService,
    ),
  );

  if (result != null) {
    try {
      if (configurationManager != null) {
        await configurationManager.updateTranslationConfig(result);
      }
    } catch (_) {
      // Persist failure is non-fatal.
    }
  }

  return result;
}

import 'package:flutter/material.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import '../services/core/service_locator.dart';
import '../services/core/configuration_manager.dart';
import '../dialogs/llm_config_dialog.dart';
import 'custom_button.dart';

/// Shared configuration status indicator widget
/// Shows the current LLM connection status across translation apps
class ConfigStatusWidget extends StatelessWidget {
  final bool isAutoConfiguring;
  final bool isConfigured;
  final String autoConfigStatus;
  final LLMConfig llmConfig;
  final VoidCallback onConfigurePressed;

  const ConfigStatusWidget({
    super.key,
    required this.isAutoConfiguring,
    required this.isConfigured,
    required this.autoConfigStatus,
    required this.llmConfig,
    required this.onConfigurePressed,
  });

  @override
  Widget build(BuildContext context) {
    // If auto-configuring, show progress status
    if (isAutoConfiguring) {
      return Card(
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue.shade600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  autoConfigStatus.isEmpty
                      ? 'Auto-configuring LLM connection...'
                      : autoConfigStatus,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade800,
                    fontSize: 13, // Smaller font
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If configured successfully, show success status
    if (isConfigured) {
      return Card(
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Determine display format based on available width
              final isNarrow = constraints.maxWidth < 400;
              
              String displayText;
              if (llmConfig.selectedModel.isNotEmpty) {
                if (isNarrow) {
                  // Compact format for narrow screens (mobile)
                  // Capitalize first letter of provider
                  final provider = llmConfig.provider[0].toUpperCase() + 
                                 llmConfig.provider.substring(1);
                  displayText = '$provider: ${llmConfig.selectedModel}';
                } else {
                  // Full format for wider screens
                  displayText = 'Connected to ${llmConfig.provider} - Model: ${llmConfig.selectedModel}';
                }
              } else {
                displayText = 'Connected to ${llmConfig.provider}';
              }
              
              return Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayText,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade800,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    // If configuration failed, show error status
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade600, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Auto-configuration failed. Click settings to configure manually.',
                style: TextStyle(fontSize: 13), // Smaller font
                overflow: TextOverflow.ellipsis,
              ),
            ),
            CustomButton(
              text: 'Configure',
              onPressed: onConfigurePressed,
              type: CustomButtonType.text,
              size: CustomButtonSize.small,
            ),
          ],
        ),
      ),
    );
  }
}

/// Complete Translation Status Widget with auto-initialization
/// This is the stateful wrapper that handles auto-configuration
class TranslationStatusWidget extends StatefulWidget {
  const TranslationStatusWidget({super.key});

  @override
  State<TranslationStatusWidget> createState() =>
      _TranslationStatusWidgetState();
}

class _TranslationStatusWidgetState extends State<TranslationStatusWidget> {
  late TranslationService _translationService;
  bool _isChecking = true;
  bool _isConfigured = false;
  LLMConfig? _currentConfig;

  @override
  void initState() {
    super.initState();
    _translationService = ServiceLocator.get<TranslationService>();
    
    // Listen to service changes to update status automatically
    _translationService.addListener(_onServiceChanged);
    
    // Delay check until after first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkConfiguration();
    });
  }

  @override
  void dispose() {
    _translationService.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    // When service state changes, re-check configuration
    if (mounted && !_isChecking) {
      _checkConfiguration();
    }
  }

  Future<void> _checkConfiguration() async {
    if (!mounted) return;
    setState(() => _isChecking = true);

    final logger = ServiceLocator.logger;

    try {
      // Strategy 0: Check if we have a saved configuration in persistent storage
      final configManager = ConfigurationManager.instance;
      final appConfig = await configManager.getConfiguration();
      
      if (appConfig.translationConfig != null && 
          appConfig.translationConfig!.selectedModel.isNotEmpty) {
        final savedConfig = appConfig.translationConfig!;
        logger.debug('ConfigStatusWidget: Found saved configuration', tag: 'ConfigStatus', details: {
          'provider': savedConfig.provider,
          'serverUrl': savedConfig.serverUrl,
          'model': savedConfig.selectedModel,
        });
        
        // Test the saved configuration
        final status = await _translationService.testConnection(savedConfig);
        logger.info('ConfigStatusWidget: Saved config test result', tag: 'ConfigStatus', details: {
          'success': status.success,
          'modelCount': status.modelCount,
        });
        
        if (!mounted) return;
        if (status.success) {
          setState(() {
            _isConfigured = true;
            _currentConfig = savedConfig;
            _isChecking = false;
          });
          return;
        } else {
          logger.warning('ConfigStatusWidget: Saved config test failed, trying other options', tag: 'ConfigStatus');
        }
      }
      
      // Strategy 1: Check if we already have a working config in memory
      if (_currentConfig != null && _currentConfig!.selectedModel.isNotEmpty) {
        // We have a complete config, test it
        logger.debug('ConfigStatusWidget: Testing existing config', tag: 'ConfigStatus');
        final status = await _translationService.testConnection(_currentConfig!);
        logger.info('ConfigStatusWidget: Existing config test result', tag: 'ConfigStatus', details: {
          'success': status.success,
          'modelCount': status.modelCount,
        });
        if (!mounted) return;
        setState(() {
          _isConfigured = status.success;
          _isChecking = false;
        });
        return;
      }

      // Strategy 2: Try default Ollama configuration (most common setup)
      logger.info('ConfigStatusWidget: No existing config, trying default Ollama', tag: 'ConfigStatus');
      const defaultConfig = LLMConfig(
        provider: 'ollama',
        serverUrl: 'http://localhost:11434',
        selectedModel: '', // Will be auto-detected
      );

      // Quick connection test with 5 second timeout (increased from 3)
      final status = await _translationService
          .testConnection(defaultConfig, timeout: const Duration(seconds: 5))
          .timeout(const Duration(seconds: 6));
      
      logger.info('ConfigStatusWidget: Default Ollama test result', tag: 'ConfigStatus', details: {
        'success': status.success,
        'modelCount': status.modelCount,
        'message': status.message,
      });
      
      if (!mounted) return;
      
      if (status.success) {
        // Connection successful, get available models
        final models = _translationService.availableModels;
        final model = models.isNotEmpty ? models.first : '';
        
        logger.info('ConfigStatusWidget: Ollama connection successful', tag: 'ConfigStatus', details: {
          'availableModels': models.length,
          'selectedModel': model,
        });
        
        final workingConfig = LLMConfig(
          provider: 'ollama',
          serverUrl: 'http://localhost:11434',
          selectedModel: model,
        );
        
        setState(() {
          _isConfigured = true;
          _currentConfig = workingConfig;
          _isChecking = false;
        });
      } else {
        // Connection failed - show manual configuration option
        logger.warning('ConfigStatusWidget: Ollama connection failed', tag: 'ConfigStatus');
        setState(() {
          _isConfigured = false;
          _currentConfig = null;
          _isChecking = false;
        });
      }
    } catch (e, stackTrace) {
      logger.error('ConfigStatusWidget: Error checking configuration', tag: 'ConfigStatus', error: e, stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _isConfigured = false;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConfigStatusWidget(
      isAutoConfiguring: _isChecking,
      isConfigured: _isConfigured,
      autoConfigStatus: _isChecking ? 'Checking connection...' : 'Ready',
      llmConfig: _currentConfig ??
          const LLMConfig(
            provider: 'ollama',
            serverUrl: 'http://localhost:11434',
            selectedModel: '',
          ),
      onConfigurePressed: () => _showConfigDialog(context),
    );
  }

  void _showConfigDialog(BuildContext context) async {
    final result = await showDialog<LLMConfig>(
      context: context,
      builder: (context) => LLMConfigDialog(
        initialConfig: _currentConfig ??
            const LLMConfig(
              provider: 'ollama',
              serverUrl: 'http://localhost:11434',
              selectedModel: '',
            ),
        translationService: _translationService,
      ),
    );

    if (result != null && mounted) {
      // Save the new configuration to persistent storage
      try {
        final configManager = ConfigurationManager.instance;
        final success = await configManager.updateTranslationConfig(result);
        
        final logger = ServiceLocator.logger;
        if (success) {
          logger.info('ConfigStatusWidget: Saved LLM configuration', tag: 'ConfigStatus', details: {
            'provider': result.provider,
            'serverUrl': result.serverUrl,
            'model': result.selectedModel,
          });
          
          // Update the current config in memory
          setState(() {
            _currentConfig = result;
            _isConfigured = true;
          });
        } else {
          logger.error('ConfigStatusWidget: Failed to save configuration', tag: 'ConfigStatus');
        }
      } catch (e, stackTrace) {
        final logger = ServiceLocator.logger;
        logger.error('ConfigStatusWidget: Error saving configuration', tag: 'ConfigStatus', error: e, stackTrace: stackTrace);
      }
      
      // Recheck configuration after dialog closes
      _checkConfiguration();
    }
  }
}


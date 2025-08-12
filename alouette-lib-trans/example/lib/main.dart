import 'package:flutter/material.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alouette Translation Library Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TranslationDemo(),
    );
  }
}

class TranslationDemo extends StatefulWidget {
  const TranslationDemo({super.key});

  @override
  State<TranslationDemo> createState() => _TranslationDemoState();
}

class _TranslationDemoState extends State<TranslationDemo> {
  final _translationService = TranslationService();
  final _configService = LLMConfigService();
  final _textController = TextEditingController();
  
  LLMConfig _config = const LLMConfig(
    provider: 'ollama',
    serverUrl: 'http://localhost:11434',
    selectedModel: 'llama3.2',
  );
  
  final List<String> _selectedLanguages = ['es', 'fr', 'de'];
  TranslationResult? _currentResult;
  String _statusMessage = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _textController.text = 'Hello, world! How are you today?';
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing connection...';
    });

    try {
      final status = await _configService.testConnection(_config);
      setState(() {
        _statusMessage = status.success 
            ? 'Connected successfully! Found ${status.modelCount ?? 0} models.'
            : 'Connection failed: ${status.message}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Connection test failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _translateText() async {
    if (_textController.text.trim().isEmpty) {
      setState(() {
        _statusMessage = 'Please enter text to translate';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Translating...';
      _currentResult = null;
    });

    try {
      final result = await _translationService.translateText(
        _textController.text,
        _selectedLanguages,
        _config,
      );

      setState(() {
        _currentResult = result;
        _statusMessage = 'Translation completed successfully!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Translation failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _autoDetectConfig() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Auto-detecting configuration...';
    });

    try {
      final detectedConfig = await _configService.autoDetectConfig();
      if (detectedConfig != null) {
        setState(() {
          _config = detectedConfig;
          _statusMessage = 'Auto-detected ${detectedConfig.provider} configuration';
        });
      } else {
        setState(() {
          _statusMessage = 'No working configuration found. Please configure manually.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Auto-detection failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Translation Library Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Configuration Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LLM Configuration',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _config.provider,
                            decoration: const InputDecoration(labelText: 'Provider'),
                            items: const [
                              DropdownMenuItem(value: 'ollama', child: Text('Ollama')),
                              DropdownMenuItem(value: 'lmstudio', child: Text('LM Studio')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _config = _config.copyWith(provider: value);
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _autoDetectConfig,
                          child: const Text('Auto-detect'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: _config.serverUrl,
                      decoration: const InputDecoration(labelText: 'Server URL'),
                      onChanged: (value) {
                        _config = _config.copyWith(serverUrl: value);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: _config.selectedModel,
                      decoration: const InputDecoration(labelText: 'Model'),
                      onChanged: (value) {
                        _config = _config.copyWith(selectedModel: value);
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testConnection,
                      child: const Text('Test Connection'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Translation Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Translation',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        labelText: 'Text to translate',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    const Text('Target Languages:'),
                    Wrap(
                      spacing: 8,
                      children: TranslationConstants.languageNames.entries
                          .take(10) // Show first 10 languages
                          .map((entry) => FilterChip(
                                label: Text(entry.value),
                                selected: _selectedLanguages.contains(entry.key),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedLanguages.add(entry.key);
                                    } else {
                                      _selectedLanguages.remove(entry.key);
                                    }
                                  });
                                },
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _translateText,
                      child: _isLoading 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Translate'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Status Section
            if (_statusMessage.isNotEmpty)
              Card(
                color: _statusMessage.contains('failed') || _statusMessage.contains('error')
                    ? Colors.red.shade50
                    : Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _statusMessage.contains('failed') || _statusMessage.contains('error')
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                ),
              ),
            
            // Results Section
            if (_currentResult != null) ...[
              const SizedBox(height: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Translation Results',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Original: ${_currentResult!.original}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _currentResult!.translations.length,
                            itemBuilder: (context, index) {
                              final entry = _currentResult!.translations.entries.elementAt(index);
                              final languageName = TranslationConstants.languageNames[entry.key] ?? entry.key;
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  title: Text(languageName),
                                  subtitle: Text(
                                    entry.value,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  leading: CircleAvatar(
                                    child: Text(entry.key.toUpperCase()),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
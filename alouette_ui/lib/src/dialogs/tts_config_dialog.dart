import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import '../core/logger.dart';
import '../tokens/dimension_tokens.dart';
import '../tokens/typography_tokens.dart';
import '../widgets/custom_button.dart';

class TTSConfigDialog extends StatefulWidget {
  final TTSService? ttsService;

  const TTSConfigDialog({super.key, this.ttsService});

  @override
  State<TTSConfigDialog> createState() => _TTSConfigDialogState();
}

class _TTSConfigDialogState extends State<TTSConfigDialog> {
  bool _isInitialized = false;
  List<VoiceModel> _voices = [];
  String? _currentVoice;
  AudioPlayer? _audioPlayer;
  TTSEngineType? _currentEngine;

  @override
  void initState() {
    super.initState();
    _initializeTTSSettings();
  }

  Future<void> _initializeTTSSettings() async {
    if (widget.ttsService != null) {
      try {
        // Initialize audio player
        _audioPlayer = AudioPlayer();

        // Get current engine type
        _currentEngine = widget.ttsService!.currentEngine;

        // Get available voices
        final voices = await widget.ttsService!.getVoices();

        if (mounted) {
          setState(() {
            _voices = voices;
            _currentVoice = voices.isNotEmpty ? voices.first.name : null;
            _isInitialized = true;
          });
        }
      } catch (e, stack) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('TTS Error: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 10),
              action: SnackBarAction(
                label: 'Details',
                textColor: Colors.white,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('TTS Error Details'),
                      content: SingleChildScrollView(
                        child: Text('$e\n\n$stack'),
                      ),
                      actions: [
                        CustomButton(
                          onPressed: () => Navigator.pop(context),
                          text: 'Close',
                          type: CustomButtonType.text,
                          size: CustomButtonSize.medium,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        }
      }
    } else {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _testTTS() async {
    if (widget.ttsService == null ||
        _currentVoice == null ||
        _audioPlayer == null)
      return;

    try {
      final audioData = await widget.ttsService!.synthesizeText(
        "Hello, this is a test of the text to speech settings.",
        _currentVoice!,
      );
      await _audioPlayer!.playBytes(audioData);
    } on TTSError catch (e) {
      if (mounted) {
        String errorMessage = 'TTS Test Failed: ${e.message}';
        if (e.code != null) {
          errorMessage += ' (Code: ${e.code})';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected TTS Test Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopTTS() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
      }
      if (widget.ttsService != null) {
        await widget.ttsService!.stop();
      }
    } catch (e) {
      // Some implementations may not support stopping
      logger.d('[TTS] Stop not supported', error: e);
    }
  }

  Future<void> _switchEngine(TTSEngineType engineType) async {
    if (widget.ttsService == null) return;

    try {
      await widget.ttsService!.switchEngine(engineType);
      setState(() {
        _currentEngine = engineType;
        _voices = [];
        _currentVoice = null;
      });

      // Reload voices for the new engine
      final voices = await widget.ttsService!.getVoices();
      setState(() {
        _voices = voices;
        _currentVoice = voices.isNotEmpty ? voices.first.name : null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch engine: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 500.0, // Standard dialog width
        height: 500,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(
                SpacingTokens.xxl,
                SpacingTokens.xxl,
                SpacingTokens.xxl,
                SpacingTokens.l,
              ),
              child: Row(
                children: [
                  const Icon(Icons.record_voice_over, size: SpacingTokens.xxl),
                  const SizedBox(width: 12),
                  Text(
                    'TTS Configuration',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      SpacingTokens.xxl,
                      0,
                      SpacingTokens.xxl,
                      SpacingTokens.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        if (_isInitialized) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: widget.ttsService != null
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: widget.ttsService != null
                                    ? Colors.green.shade200
                                    : Colors.orange.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  widget.ttsService != null
                                      ? Icons.check_circle
                                      : Icons.warning,
                                  color: widget.ttsService != null
                                      ? Colors.green.shade600
                                      : Colors.orange.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.ttsService != null
                                      ? 'TTS Service Available'
                                      : 'TTS Service Not Available',
                                  style: TextStyle(
                                    color: widget.ttsService != null
                                        ? Colors.green.shade800
                                        : Colors.orange.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: SpacingTokens.xxl),

                          // Engine Selection
                          Text(
                            'TTS Engine',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: CustomButton(
                                  onPressed:
                                      _currentEngine == TTSEngineType.edge
                                      ? null
                                      : () => _switchEngine(TTSEngineType.edge),
                                  text: 'Edge TTS',
                                  type: _currentEngine == TTSEngineType.edge
                                      ? CustomButtonType.primary
                                      : CustomButtonType.outline,
                                  size: CustomButtonSize.medium,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: CustomButton(
                                  onPressed:
                                      _currentEngine == TTSEngineType.flutter
                                      ? null
                                      : () => _switchEngine(
                                          TTSEngineType.flutter,
                                        ),
                                  text: 'Flutter TTS',
                                  type: _currentEngine == TTSEngineType.flutter
                                      ? CustomButtonType.primary
                                      : CustomButtonType.outline,
                                  size: CustomButtonSize.medium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: SpacingTokens.l),

                          Text(
                            'Current Engine: ${_currentEngine?.name ?? 'Unknown'}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: SpacingTokens.xxl),

                          if (_voices.isNotEmpty) ...[
                            Text(
                              'Available Voices (${_voices.length})',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _currentVoice,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              isExpanded: true,
                              items: _voices.map((voice) {
                                return DropdownMenuItem<String>(
                                  value: voice.name,
                                  child: Text(
                                    '${voice.displayName} (${voice.locale}, ${voice.gender})',
                                    style: const TextStyle(
                                      fontSize: TypographyTokens.titleLarge,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _currentVoice = newValue;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Neural voices: ${_voices.where((v) => v.isNeural).length}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: SpacingTokens.xxl),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              CustomButton(
                                onPressed:
                                    (widget.ttsService != null &&
                                        _currentVoice != null)
                                    ? _testTTS
                                    : null,
                                text: 'Test',
                                icon: Icons.play_arrow,
                                type: CustomButtonType.primary,
                                size: CustomButtonSize.medium,
                              ),
                              CustomButton(
                                onPressed: widget.ttsService != null
                                    ? _stopTTS
                                    : null,
                                text: 'Stop',
                                icon: Icons.stop,
                                type: CustomButtonType.secondary,
                                size: CustomButtonSize.medium,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: Visibility(
                      visible: !_isInitialized,
                      maintainState: true,
                      maintainAnimation: true,
                      maintainSize: true,
                      child: Container(
                        color: Colors.transparent,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

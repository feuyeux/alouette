import 'package:flutter/material.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import 'package:alouette_lib_tts/alouette_tts.dart' as tts_lib;
import 'package:alouette_ui/alouette_ui.dart';

/// 通用翻译页面基类，支持可选TTS扩展
class TranslationPageBase extends StatelessWidget {
  final TranslationService translationService;
  final tts_lib.TTSService? ttsService;
  final bool showTTS;
  final bool isCompactMode;
  final VoidCallback? onTranslate;
  final VoidCallback? onClearResults;
  final TextEditingController textController;
  final List<String> selectedLanguages;
  final ValueChanged<List<String>>? onLanguagesChanged;
  final void Function(String, bool)? onLanguageToggle;
  final bool isTranslating;
  final bool isConfigured;

  const TranslationPageBase({
    super.key,
    required this.translationService,
    this.ttsService,
    this.showTTS = false,
    this.isCompactMode = true,
    this.onTranslate,
    this.onClearResults,
    required this.textController,
    required this.selectedLanguages,
    this.onLanguagesChanged,
    this.onLanguageToggle,
    this.isTranslating = false,
    this.isConfigured = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.s,
            vertical: SpacingTokens.xxs,
          ),
          child: TranslationInputWidget(
            textController: textController,
            selectedLanguages: selectedLanguages,
            onLanguagesChanged: onLanguagesChanged,
            onLanguageToggle: onLanguageToggle,
            onTranslate: onTranslate ?? () {},
            onClearResults: onClearResults,
            isTranslating: isTranslating,
            isConfigured: isConfigured,
          ),
        ),
        Expanded(
          child: Card(
            margin: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.s,
              vertical: SpacingTokens.xs,
            ),
            child: Padding(
              padding: const EdgeInsets.all(SpacingTokens.s),
              child: TranslationResultWidget(
                translationService: translationService,
                ttsService: showTTS ? ttsService : null,
                isTTSInitialized: showTTS && ttsService != null
                    ? (ttsService!.isInitialized)
                    : false,
                isCompactMode: isCompactMode,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

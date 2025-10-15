import 'package:flutter/material.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import '../constants/language_constants.dart';
import '../components/organisms/translation_panel.dart';

/// Translation Input Widget - Migrated to use Atomic Design
///
/// This widget now uses the new TranslationPanel organism component
/// for consistent UI across all applications.
class TranslationInputWidget extends StatefulWidget {
  final TextEditingController textController;
  final List<String> selectedLanguages;
  final VoidCallback onTranslate;
  final TranslationService? translationService;
  final void Function(String language, bool selected)? onLanguageToggle;
  final ValueChanged<List<String>>? onLanguagesChanged;
  final VoidCallback? onReset;
  final VoidCallback? onSelectAll;
  final VoidCallback? onClearResults;
  final bool isTranslating;
  final bool isConfigured;

  const TranslationInputWidget({
    super.key,
    required this.textController,
    required this.selectedLanguages,
    required this.onTranslate,
    this.translationService,
    this.onLanguageToggle,
    this.onLanguagesChanged,
    this.onReset,
    this.onSelectAll,
    this.onClearResults,
    this.isTranslating = false,
    this.isConfigured = true,
  });

  @override
  State<TranslationInputWidget> createState() => _TranslationInputWidgetState();
}

class _TranslationInputWidgetState extends State<TranslationInputWidget> {
  bool get _isCompactMode => widget.onLanguagesChanged != null;

  @override
  Widget build(BuildContext context) {
    // Convert string language codes to LanguageOption objects
    final selectedLanguageOptions = widget.selectedLanguages
        .map(
          (code) => LanguageConstants.supportedLanguages.firstWhere(
            (lang) => lang.code == code || lang.name == code,
            orElse: () => LanguageOption(
              code: code,
              name: code,
              nativeName: code,
              flag: '🌐',
              order: 999, // Unknown languages go to the end
              sampleText: '$code. Sample text.',
            ),
          ),
        )
        .toList();

    return TranslationPanel(
      textController: widget.textController,
      selectedLanguages: selectedLanguageOptions,
      onLanguagesChanged: _onLanguagesChanged,
      onTranslate: widget.onTranslate,
      onClear: _onClear,
      isTranslating: widget.isTranslating,
      isCompactMode: _isCompactMode,
      isConfigured: widget.isConfigured, // Add this line
    );
  }

  void _onLanguagesChanged(List<LanguageOption> languages) {
    if (widget.onLanguagesChanged != null) {
      // Convert back to string codes for backward compatibility
      final languageCodes = languages.map((lang) => lang.code).toList();
      widget.onLanguagesChanged!(languageCodes);
    } else if (widget.onLanguageToggle != null) {
      // Handle individual language toggles for backward compatibility
      final currentCodes = widget.selectedLanguages.toSet();
      final newCodes = languages.map((lang) => lang.code).toSet();

      // Find added languages
      for (final code in newCodes.difference(currentCodes)) {
        widget.onLanguageToggle!(code, true);
      }

      // Find removed languages
      for (final code in currentCodes.difference(newCodes)) {
        widget.onLanguageToggle!(code, false);
      }
    }
  }

  void _onClear() {
    widget.textController.clear();
    widget.onReset?.call();

    // 同时清除语言选择
    if (widget.onLanguagesChanged != null) {
      widget.onLanguagesChanged!([]);
    }

    // 清除翻译结果
    if (widget.onClearResults != null) {
      widget.onClearResults!();
    }
  }
}

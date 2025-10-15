import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart' show VoiceModel;
import 'package:alouette_ui/alouette_ui.dart';
import '../controllers/tts_controller.dart' as local;

/// Widget for text input and voice selection
class TTSInputSection extends StatefulWidget {
  final local.TTSController controller;
  final TextEditingController textController;

  const TTSInputSection({
    super.key,
    required this.controller,
    required this.textController,
  });

  @override
  State<TTSInputSection> createState() => _TTSInputSectionState();
}

class _TTSInputSectionState extends State<TTSInputSection> {
  String? _selectedLanguage;
  String? _selectedVoice;

  @override
  void initState() {
    super.initState();
    // Initialize selected language and voice when controller is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSelection();
    });
  }

  void _initializeSelection() {
    if (!widget.controller.isInitialized ||
        widget.controller.availableVoices.isEmpty) {
      return;
    }

    // Try to find English voice first, otherwise use first available
    final englishVoice = widget.controller.availableVoices
        .where((voice) => voice.languageCode == 'en-US')
        .firstOrNull;
    
    final currentVoice = widget.controller.availableVoices
        .where((voice) => voice.id == widget.controller.currentVoice)
        .firstOrNull;
    
    final defaultVoice = englishVoice ?? currentVoice ?? widget.controller.availableVoices.first;
    final selectedLanguageCode = defaultVoice.languageCode;

    setState(() {
      _selectedLanguage = selectedLanguageCode;
      _selectedVoice = defaultVoice.id;
    });

    // Change voice if not already set
    if (widget.controller.currentVoice != defaultVoice.id) {
      widget.controller.changeVoice(defaultVoice.id);
    }

    // Set sample text for the selected language immediately
    if (widget.textController.text.isEmpty) {
      final languageOption = LanguageConstants.getLanguageByCode(selectedLanguageCode);
      if (languageOption != null) {
        widget.textController.text = languageOption.sampleText;
      }
    }
  }

  /// Get unique languages from available voices
  List<String> get _availableLanguages {
    if (!widget.controller.isInitialized) return [];

    final languages = widget.controller.availableVoices
        .map((voice) => voice.languageCode)
        .toSet()
        .toList();

    // Sort by LanguageConstants order, then alphabetically for unknown languages
    languages.sort((a, b) {
      final langA = LanguageConstants.getLanguageByCode(a);
      final langB = LanguageConstants.getLanguageByCode(b);
      
      if (langA != null && langB != null) {
        return langA.order.compareTo(langB.order);
      } else if (langA != null) {
        return -1; // Known languages come first
      } else if (langB != null) {
        return 1;
      } else {
        return a.compareTo(b); // Alphabetical for unknown languages
      }
    });
    
    return languages;
  }

  /// Get voices for selected language
  List<VoiceModel> get _voicesForSelectedLanguage {
    if (!widget.controller.isInitialized || _selectedLanguage == null) {
      return [];
    }

    return widget.controller.availableVoices
        .where((voice) => voice.languageCode == _selectedLanguage)
        .toList();
  }

  /// Get language display name
  String _getLanguageDisplayName(String languageCode) {
    // Try to get from LanguageConstants first
    final languageOption = LanguageConstants.getLanguageByCode(languageCode);
    if (languageOption != null) {
      return '${languageOption.nativeName} ${languageOption.name} (${languageOption.code})';
    }
    
    // Fallback for language codes not in LanguageConstants
    const fallbackLanguageNames = {
      'en-GB': 'English English (en-GB)',
      'en-AU': 'English English (en-AU)',
      'en-CA': 'English English (en-CA)',
      'zh-TW': '中文 Chinese (zh-TW)',
      'zh-HK': '中文 Chinese (zh-HK)',
      'fr-CA': 'Français French (fr-CA)',
      'es-MX': 'Español Spanish (es-MX)',
      'pt-BR': 'Português Portuguese (pt-BR)',
      'pt-PT': 'Português Portuguese (pt-PT)',
      'th-TH': 'ไทย Thai (th-TH)',
      'vi-VN': 'Tiếng Việt Vietnamese (vi-VN)',
    };

    return fallbackLanguageNames[languageCode] ?? languageCode;
  }

  /// Get voice display name with gender info
  String _getVoiceDisplayName(VoiceModel voice) {
    final parts = <String>[];

    parts.add(voice.displayName);

    // Add gender info - gender is an enum, always has a value
    parts.add('(${voice.gender.name})');

    return parts.join(' ');
  }

  void _onLanguageChanged(String? languageCode) {
    if (languageCode == null || languageCode == _selectedLanguage) return;

    setState(() {
      _selectedLanguage = languageCode;
      _selectedVoice = null; // Reset voice selection
    });

    // Update text input with sample text for the selected language
    final languageOption = LanguageConstants.getLanguageByCode(languageCode);
    if (languageOption != null) {
      widget.textController.text = languageOption.sampleText;
    }

    // Auto-select first voice for the new language
    final voicesForLanguage = _voicesForSelectedLanguage;
    if (voicesForLanguage.isNotEmpty) {
      final firstVoice = voicesForLanguage.first;
      setState(() {
        _selectedVoice = firstVoice.id;
      });
      widget.controller.changeVoice(firstVoice.id);
    }
  }

  void _onVoiceChanged(String? voiceId) {
    if (voiceId == null || voiceId == _selectedVoice) return;

    setState(() {
      _selectedVoice = voiceId;
    });

    widget.controller.changeVoice(voiceId);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        // Update selection when controller state changes
        if (widget.controller.isInitialized &&
            widget.controller.availableVoices.isNotEmpty &&
            _selectedLanguage == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeSelection();
          });
        }

        return CustomCard(
          child: Padding(
            padding: const EdgeInsets.all(8.0), // Reduced from 12 to 8
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.text_fields,
                      color: AppTheme.primaryColor,
                      size: 16, // Reduced from 18 to 16
                    ),
                    const SizedBox(width: 4), // Reduced from 6 to 4
                    const Text(
                      'Text Input',
                      style: TextStyle(
                        fontSize: 13, // Reduced from 14 to 13
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8), // Reduced from 12 to 8
                // Text input field
                Expanded(
                  child: CustomTextField(
                    controller: widget.textController,
                    hintText: 'Enter text to speak...',
                    maxLines: null,
                    expands: true,
                    enabled: widget.controller.isInitialized,
                  ),
                ),

                const SizedBox(height: 8), // Reduced from 12 to 8
                // Voice selection
                if (widget.controller.isInitialized &&
                    widget.controller.availableVoices.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Voice Selection',
                        style: TextStyle(
                          fontSize: 11, // Reduced from 12 to 11
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4), // Reduced from 6 to 4
                      // Language and Voice selection row
                      Row(
                        children: [
                          // Language selection (left side)
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Language',
                                  style: TextStyle(
                                    fontSize: 9, // Reduced from 10 to 9
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(
                                  height: 1,
                                ), // Reduced from 2 to 1
                                CustomDropdown<String>(
                                  value: _selectedLanguage,
                                  items: _availableLanguages
                                      .map(
                                        (languageCode) =>
                                            DropdownMenuItem<String>(
                                              value: languageCode,
                                              child: Text(
                                                _getLanguageDisplayName(
                                                  languageCode,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                      )
                                      .toList(),
                                  onChanged: widget.controller.isInitialized
                                      ? _onLanguageChanged
                                      : null,
                                  hint: 'Select Language',
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical:
                                        4.0, // Much smaller vertical padding
                                  ),
                                  isDense: true,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 6), // Reduced from 8 to 6
                          // Voice selection (right side)
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Voice',
                                  style: TextStyle(
                                    fontSize: 9, // Reduced from 10 to 9
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(
                                  height: 1,
                                ), // Reduced from 2 to 1
                                CustomDropdown<String>(
                                  value: _selectedVoice,
                                  items: _voicesForSelectedLanguage
                                      .map(
                                        (voice) => DropdownMenuItem<String>(
                                          value: voice.id,
                                          child: Text(
                                            _getVoiceDisplayName(voice),
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged:
                                      widget.controller.isInitialized &&
                                          _selectedLanguage != null
                                      ? _onVoiceChanged
                                      : null,
                                  hint: 'Select Voice',
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical:
                                        4.0, // Much smaller vertical padding
                                  ),
                                  isDense: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                // Loading indicator when not initialized
                if (!widget.controller.isInitialized)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0), // Reduced from 12 to 8
                      child: Column(
                        children: [
                          SizedBox(
                            width: 16, // Smaller loading indicator
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(height: 4), // Reduced from 6 to 4
                          Text(
                            'Initializing TTS...',
                            style: TextStyle(
                              fontSize: 10,
                            ), // Reduced from 12 to 10
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import '../../constants/language_constants.dart';
import '../atoms/language_flag_icon.dart';

/// Translation Panel Organism
///
/// Complex component for translation input, language selection, and results display
class TranslationPanel extends StatefulWidget {
  final TextEditingController textController;
  final List<LanguageOption> selectedLanguages;
  final ValueChanged<List<LanguageOption>>? onLanguagesChanged;
  final VoidCallback? onTranslate;
  final VoidCallback? onClear;
  final bool isTranslating;
  final bool isCompactMode;
  final bool isConfigured;
  final String? errorMessage;
  final Map<String, String>? translationResults;

  const TranslationPanel({
    super.key,
    required this.textController,
    required this.selectedLanguages,
    this.onLanguagesChanged,
    this.onTranslate,
    this.onClear,
    this.isTranslating = false,
    this.isCompactMode = false,
    this.isConfigured = true,
    this.errorMessage,
    this.translationResults,
  });

  @override
  State<TranslationPanel> createState() => _TranslationPanelState();
}

class _TranslationPanelState extends State<TranslationPanel> {
  String _currentText = '';

  @override
  void initState() {
    super.initState();
    _currentText = widget.textController.text;
  }

  void _onTextChanged(String text) {
    setState(() {
      _currentText = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Text input - smaller
        _buildTextInput(),
        const SizedBox(height: 4), // 统一间距为4px
        // Language chips - responsive grid layout
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: PlatformUtils.isMobile ? 110 : 75,
            minHeight: PlatformUtils.isMobile ? 110 : 75,
          ),
          child: SingleChildScrollView(child: _buildLanguageGrid()),
        ),
        const SizedBox(height: 4), // 统一间距为4px
        // Action buttons
        _buildActionBar(),
        // Error display
        if (widget.errorMessage != null) ...[
          const SizedBox(height: 4), // 统一间距为4px
          _buildErrorDisplay(),
        ],
      ],
    );
  }

  Widget _buildTextInput() {
    return SizedBox(
      height: 50, // 减少从90到50，最小化高度
      child: TextField(
        controller: widget.textController,
        maxLines: null,
        expands: true,
        decoration: const InputDecoration(
          labelText: 'Text to translate',
          hintText: 'Enter text to translate...',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.all(8),
          labelStyle: TextStyle(fontSize: 16),
        ),
        style: const TextStyle(fontSize: 14),
        enabled: !widget.isTranslating,
        onChanged: _onTextChanged,
      ),
    );
  }

  Widget _buildActionBar() {
    final hasText = _currentText.isNotEmpty;
    final hasLanguages = widget.selectedLanguages.isNotEmpty;
    // 修改条件：即使没有配置也允许点击翻译按钮，让用户在翻译时配置
    final canTranslate =
        hasText && hasLanguages && !widget.isTranslating;

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: ElevatedButton(
            onPressed: () {
              _clearLanguages();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              minimumSize: const Size(0, 36),
            ),
            child: const Text('Clear', style: TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 1,
          child: ElevatedButton(
            onPressed: () {
              _selectAllLanguages();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              minimumSize: const Size(0, 36),
            ),
            child: const Text('Select All', style: TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: canTranslate
                ? () {
                    widget.onTranslate?.call();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canTranslate ? null : Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              minimumSize: const Size(0, 36),
            ),
            icon: widget.isTranslating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.translate, size: 16),
            label: Text(
              widget.isTranslating 
                  ? 'Translating...' 
                  : widget.isConfigured 
                      ? 'Translate' 
                      : 'Translate (Setup Required)',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorDisplay() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.errorMessage!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _handleLanguageTap(LanguageOption language) {
    final currentSelection = List<LanguageOption>.from(
      widget.selectedLanguages,
    );

    // 通过语言代码比较来确定是否已选中
    final wasSelected = currentSelection.any(
      (selected) => selected.code == language.code,
    );

    if (wasSelected) {
      // 移除所有匹配的语言代码
      currentSelection.removeWhere(
        (selected) => selected.code == language.code,
      );
    } else {
      // 添加语言（确保不重复）
      if (!currentSelection.any((selected) => selected.code == language.code)) {
        currentSelection.add(language);
      }
    }

    widget.onLanguagesChanged?.call(currentSelection);
  }

  void _selectAllLanguages() {
    // 检查是否所有语言都已选中（通过比较语言代码）
    final selectedCodes = widget.selectedLanguages.map((l) => l.code).toSet();
    final allCodes = LanguageConstants.supportedLanguages
        .map((l) => l.code)
        .toSet();
    final isAllSelected =
        selectedCodes.containsAll(allCodes) &&
        allCodes.containsAll(selectedCodes);

    if (isAllSelected) {
      widget.onLanguagesChanged?.call([]);
    } else {
      // 否则全选
      final allLanguages = List<LanguageOption>.from(
        LanguageConstants.supportedLanguages,
      );
      widget.onLanguagesChanged?.call(allLanguages);
    }
  }

  void _clearLanguages() {
    widget.onLanguagesChanged?.call([]);
    widget.textController.clear();

    setState(() {
      _currentText = '';
    });

    // 调用 onClear 回调来清理翻译结果
    widget.onClear?.call();
  }

  Widget _buildLanguageGrid() {
    final languages = LanguageConstants.supportedLanguages;
    final rows = <Widget>[];

    // Mobile: 4 per row (3 rows), Desktop: 6 per row (2 rows)
    final itemsPerRow = PlatformUtils.isMobile ? 4 : 6;
    
    for (int i = 0; i < languages.length; i += itemsPerRow) {
      final rowLanguages = languages.skip(i).take(itemsPerRow).toList();
      rows.add(_buildLanguageRow(rowLanguages));
      if (i + itemsPerRow < languages.length) {
        rows.add(const SizedBox(height: 3));
      }
    }

    return Column(children: rows);
  }

  Widget _buildLanguageRow(List<LanguageOption> languages) {
    return Row(
      children: languages.map((language) {
        // 通过语言代码比较来确定是否选中，而不是对象引用
        final isSelected = widget.selectedLanguages.any(
          (selected) => selected.code == language.code,
        );

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 1,
            ),
            child: SizedBox(
              height: 32,
              width: double.infinity,
              child: FilterChip(
                selected: isSelected,
                onSelected: (selected) {
                  _handleLanguageTap(language);
                },
                avatar: LanguageFlagIcon(
                  language: language,
                  size: 16,
                  borderRadius: 3,
                ),
                label: SizedBox(
                  width: double.infinity,
                  child: Text(
                    PlatformUtils.isMobile 
                        ? language.shortCode 
                        : '${language.nativeName} ${language.name} (${language.code})',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                backgroundColor: Theme.of(context).colorScheme.surface,
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                showCheckmark: false,
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.4),
                  width: 1,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

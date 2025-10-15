import 'package:flutter/material.dart';
import '../../constants/language_constants.dart';
import '../../constants/ui_constants.dart';
import '../custom_button.dart';
import '../../components/atoms/language_flag_icon.dart';

/// 语言选择区域组件
/// 封装语言选择的头部、按钮和筛选逻辑
class LanguageSelectionSection extends StatelessWidget {
  final List<String> selectedLanguages;
  final Function(String language, bool selected) onLanguageToggle;
  final VoidCallback? onSelectAll;
  final VoidCallback? onClearAll;
  final bool showCompactButtons;

  const LanguageSelectionSection({
    super.key,
    required this.selectedLanguages,
    required this.onLanguageToggle,
    this.onSelectAll,
    this.onClearAll,
    this.showCompactButtons = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 头部标题和计数
        _buildHeader(context),
        const SizedBox(height: 6),

        // 语言筛选标签
        _buildLanguageChips(context),

        if (showCompactButtons) ...[
          const SizedBox(height: 8),
          _buildActionButtons(),
        ],
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    if (showCompactButtons) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Target Languages',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Row(
            children: [
              _buildCompactButton('Select All', onSelectAll),
              const SizedBox(width: 4),
              _buildCompactButton('Clear All', onClearAll),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        const Icon(Icons.language, size: 20),
        const SizedBox(width: 4),
        Text(
          'Target Languages',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const Spacer(),
        Text(
          'Selected: ${selectedLanguages.length}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
            fontSize: 10.0,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageChips(BuildContext context) {
    return SizedBox(
      height: AppSpecificSizes.fixedLanguageChipsHeight,
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 4,
          runSpacing: 2,
          children: LanguageConstants.supportedLanguages.map((language) {
            final isSelected = selectedLanguages.contains(language.code);
            return FilterChip(
              avatar: LanguageFlagIcon(
                language: language,
                size: 12,
                borderRadius: 3,
              ),
              label: Text(
                language.shortCode,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isSelected 
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Colors.black,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) =>
                  onLanguageToggle(language.code, selected),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundColor: Colors.grey.shade100,
              showCheckmark: false,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        CustomButton(
          text: 'Reset',
          icon: Icons.refresh,
          onPressed: onClearAll,
          type: CustomButtonType.text,
          size: CustomButtonSize.small,
        ),
        const SizedBox(width: 8),
        CustomButton(
          text: 'Select All',
          icon: Icons.select_all,
          onPressed: onSelectAll,
          type: CustomButtonType.text,
          size: CustomButtonSize.small,
        ),
      ],
    );
  }

  Widget _buildCompactButton(String text, VoidCallback? onPressed) {
    return Container(
      constraints: const BoxConstraints(minWidth: 60.0, maxWidth: 120.0),
      child: CustomButton(
        text: text,
        onPressed: onPressed,
        type: CustomButtonType.text,
        size: CustomButtonSize.small,
      ),
    );
  }
}

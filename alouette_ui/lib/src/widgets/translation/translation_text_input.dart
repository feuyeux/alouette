import 'package:flutter/material.dart';

/// 翻译文本输入组件
/// 提供统一的文本输入界面，支持多行和单行模式
class TranslationTextInput extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final bool multiLine;
  final double? height;

  const TranslationTextInput({
    super.key,
    required this.controller,
    this.hintText,
    this.multiLine = true,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (multiLine) {
      return Expanded(
        flex: 2,
        child: TextField(
          controller: controller,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          decoration: InputDecoration(
            hintText: hintText ?? 'Enter text to translate...',
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.all(8),
          ),
        ),
      );
    }

    return TextField(
      controller: controller,
      maxLines: multiLine ? null : 1,
      decoration: InputDecoration(
        hintText: hintText ?? 'Enter text to translate...',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

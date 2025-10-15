import 'package:flutter/material.dart';
import '../tokens/dimension_tokens.dart';
import '../themes/app_theme.dart';

/// 现代化的文本输入框组件，为所有Alouette应用提供一致的文本输入体验
class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final int? maxLines;
  final bool expands;
  final bool enabled;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool autofocus;
  final bool obscureText;
  final EdgeInsetsGeometry? contentPadding;
  final BorderRadius? borderRadius;

  const CustomTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.maxLines = 1,
    this.expands = false,
    this.enabled = true,
    this.keyboardType,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.focusNode,
    this.decoration,
    this.style,
    this.textAlign = TextAlign.start,
    this.autofocus = false,
    this.obscureText = false,
    this.contentPadding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = AppTheme.primaryColor;

    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(DimensionTokens.radiusM);
    final effectiveContentPadding =
        contentPadding ??
        const EdgeInsets.symmetric(
          horizontal: SpacingTokens.l,
          vertical: SpacingTokens.s,
        );

    return TextField(
      controller: controller,
      maxLines: expands ? null : maxLines,
      expands: expands,
      enabled: enabled,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      style: style ?? theme.textTheme.bodyMedium,
      textAlign: textAlign,
      autofocus: autofocus,
      obscureText: obscureText,
      decoration:
          decoration ??
          InputDecoration(
            hintText: hintText,
            labelText: labelText,
            contentPadding: effectiveContentPadding,
            filled: true,
            fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: BorderSide(color: primaryColor, width: 2.0),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: BorderSide(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                width: 1.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1.0,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 2.0,
              ),
            ),
          ),
    );
  }
}

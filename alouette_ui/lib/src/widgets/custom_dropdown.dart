import 'package:flutter/material.dart';
import '../tokens/dimension_tokens.dart';
import '../themes/app_theme.dart';

/// 现代化的下拉选择框组件，为所有Alouette应用提供一致的选择体验
class CustomDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>>? items;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final Widget? icon;
  final bool isExpanded;
  final bool isDense;
  final InputDecoration? decoration;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? contentPadding;

  const CustomDropdown({
    super.key,
    this.value,
    this.items,
    this.onChanged,
    this.hint,
    this.icon,
    this.isExpanded = true,
    this.isDense = false,
    this.decoration,
    this.borderRadius,
    this.contentPadding,
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

    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      icon: icon ?? const Icon(Icons.arrow_drop_down),
      isExpanded: isExpanded,
      isDense: isDense,
      hint: hint != null ? Text(hint!) : null,
      decoration:
          decoration ??
          InputDecoration(
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
      dropdownColor: isDark ? Colors.grey[850] : Colors.white,
      style: theme.textTheme.bodyMedium,
    );
  }
}

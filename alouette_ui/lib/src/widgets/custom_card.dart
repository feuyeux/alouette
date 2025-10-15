import 'package:flutter/material.dart';
import '../tokens/dimension_tokens.dart';
import '../tokens/motion_tokens.dart';

/// 现代化的卡片组件，为所有Alouette应用提供一致的内容展示容器
class CustomCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double? elevation;
  final double? hoverElevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool interactive;
  final bool addBorder;
  final Color? borderColor;
  final double? width;
  final double? height;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.elevation,
    this.hoverElevation,
    this.borderRadius,
    this.onTap,
    this.interactive = true,
    this.addBorder = false,
    this.borderColor,
    this.width,
    this.height,
  });

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBorderRadius = BorderRadius.circular(DimensionTokens.radiusXl);
    final defaultElevation = widget.elevation ?? 2.0;
    final defaultHoverElevation = widget.hoverElevation ?? 4.0;

    final effectiveElevation = _isHovering && widget.interactive
        ? defaultHoverElevation
        : defaultElevation;

    final effectiveBorderColor =
        widget.borderColor ??
        (isDark ? Colors.grey.shade700 : Colors.grey.shade300);

    return MouseRegion(
      onEnter: (_) =>
          widget.interactive ? setState(() => _isHovering = true) : null,
      onExit: (_) =>
          widget.interactive ? setState(() => _isHovering = false) : null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: MotionTokens.normal,
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? theme.cardTheme.color,
            borderRadius: widget.borderRadius ?? defaultBorderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                blurRadius: effectiveElevation * 2,
                spreadRadius: effectiveElevation / 2,
                offset: Offset(0, effectiveElevation / 2),
              ),
            ],
            border: widget.addBorder
                ? Border.all(color: effectiveBorderColor, width: 1)
                : null,
          ),
          child: ClipRRect(
            borderRadius: widget.borderRadius ?? defaultBorderRadius,
            child: Padding(
              padding: widget.padding ?? EdgeInsets.all(SpacingTokens.l),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

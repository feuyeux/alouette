import 'package:flutter/material.dart';
import '../../tokens/app_tokens.dart';

/// Base class for all atomic UI components
///
/// Provides common functionality and ensures consistent theming
/// across all atomic components in the design system.
abstract class AtomicWidget extends StatelessWidget {
  const AtomicWidget({super.key});

  /// Get the current theme colors
  ColorScheme getColorScheme(BuildContext context) {
    return Theme.of(context).colorScheme;
  }

  /// Get the current text theme
  TextTheme getTextTheme(BuildContext context) {
    return Theme.of(context).textTheme;
  }
}

/// Atomic Icon Component
///
/// Provides consistent icon rendering with proper sizing and colors.
class AtomicIcon extends AtomicWidget {
  final IconData icon;
  final AtomicIconSize size;
  final Color? color;
  final String? semanticLabel;

  const AtomicIcon(
    this.icon, {
    super.key,
    this.size = AtomicIconSize.medium,
    this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? getColorScheme(context).onSurface;

    return Icon(
      icon,
      size: size.value,
      color: iconColor,
      semanticLabel: semanticLabel,
    );
  }
}

/// Icon size enumeration for atomic icons
enum AtomicIconSize {
  small(DimensionTokens.iconS),
  medium(DimensionTokens.iconM),
  large(DimensionTokens.iconL),
  extraLarge(DimensionTokens.iconXl);

  const AtomicIconSize(this.value);
  final double value;
}

/// Atomic Text Component
///
/// Provides consistent text rendering with semantic styling.
class AtomicText extends AtomicWidget {
  final String text;
  final AtomicTextVariant variant;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AtomicText(
    this.text, {
    super.key,
    this.variant = AtomicTextVariant.body,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? getColorScheme(context).onSurface;

    return Text(
      text,
      style: variant.getStyle(context).copyWith(color: textColor),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Text variant enumeration for semantic text styling
enum AtomicTextVariant {
  displayLarge,
  displayMedium,
  displaySmall,
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  labelLarge,
  labelMedium,
  labelSmall,
  body,
  bodySmall,
  caption;

  TextStyle getStyle(BuildContext context) {
    switch (this) {
      case AtomicTextVariant.displayLarge:
        return TypographyTokens.displayLargeStyle;
      case AtomicTextVariant.displayMedium:
        return TypographyTokens.displayMediumStyle;
      case AtomicTextVariant.displaySmall:
        return TypographyTokens.displaySmallStyle;
      case AtomicTextVariant.headlineLarge:
        return TypographyTokens.headlineLargeStyle;
      case AtomicTextVariant.headlineMedium:
        return TypographyTokens.headlineMediumStyle;
      case AtomicTextVariant.headlineSmall:
        return TypographyTokens.headlineSmallStyle;
      case AtomicTextVariant.titleLarge:
        return TypographyTokens.titleLargeStyle;
      case AtomicTextVariant.titleMedium:
        return TypographyTokens.titleMediumStyle;
      case AtomicTextVariant.titleSmall:
        return TypographyTokens.titleSmallStyle;
      case AtomicTextVariant.labelLarge:
        return TypographyTokens.labelLargeStyle;
      case AtomicTextVariant.labelMedium:
        return TypographyTokens.labelMediumStyle;
      case AtomicTextVariant.labelSmall:
        return TypographyTokens.labelSmallStyle;
      case AtomicTextVariant.body:
        return TypographyTokens.bodyLargeStyle;
      case AtomicTextVariant.bodySmall:
        return TypographyTokens.bodySmallStyle;
      case AtomicTextVariant.caption:
        return TypographyTokens.captionStyle;
    }
  }
}

/// Atomic Spacer Component
///
/// Provides consistent spacing using design tokens.
class AtomicSpacer extends AtomicWidget {
  final AtomicSpacing spacing;
  final AtomicSpacerDirection direction;

  const AtomicSpacer(
    this.spacing, {
    super.key,
    this.direction = AtomicSpacerDirection.vertical,
  });

  @override
  Widget build(BuildContext context) {
    switch (direction) {
      case AtomicSpacerDirection.vertical:
        return SizedBox(height: spacing.value);
      case AtomicSpacerDirection.horizontal:
        return SizedBox(width: spacing.value);
    }
  }
}

/// Spacing enumeration using design tokens
enum AtomicSpacing {
  xs(SpacingTokens.xs),
  small(SpacingTokens.s),
  medium(SpacingTokens.m),
  large(SpacingTokens.l),
  xl(SpacingTokens.xl),
  xxl(SpacingTokens.xxl),
  xxxl(SpacingTokens.xxxl);

  const AtomicSpacing(this.value);
  final double value;
}

/// Spacer direction enumeration
enum AtomicSpacerDirection { vertical, horizontal }

/// Atomic Divider Component
///
/// Provides consistent visual separation between elements.
class AtomicDivider extends AtomicWidget {
  final AtomicDividerType type;
  final Color? color;
  final double? thickness;

  const AtomicDivider({
    super.key,
    this.type = AtomicDividerType.horizontal,
    this.color,
    this.thickness,
  });

  @override
  Widget build(BuildContext context) {
    final dividerColor = color ?? getColorScheme(context).outline;
    final dividerThickness = thickness ?? 1.0;

    switch (type) {
      case AtomicDividerType.horizontal:
        return Divider(
          color: dividerColor,
          thickness: dividerThickness,
          height: dividerThickness,
        );
      case AtomicDividerType.vertical:
        return VerticalDivider(
          color: dividerColor,
          thickness: dividerThickness,
          width: dividerThickness,
        );
    }
  }
}

/// Divider type enumeration
enum AtomicDividerType { horizontal, vertical }

/// Atomic Card Component
///
/// Provides consistent card styling with elevation and borders.
class AtomicCard extends AtomicWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Border? border;
  final VoidCallback? onTap;

  const AtomicCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getColorScheme(context);
    final cardBorderRadius =
        borderRadius ?? BorderRadius.circular(DimensionTokens.radiusL);

    Widget card = Card(
      color: backgroundColor ?? colorScheme.surface,
      elevation: elevation ?? 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: cardBorderRadius,
        side: border?.top ?? BorderSide.none,
      ),
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );

    if (onTap != null) {
      card = InkWell(onTap: onTap, borderRadius: cardBorderRadius, child: card);
    }

    return card;
  }
}

/// Atomic Badge Component
///
/// Small status or count indicator.
class AtomicBadge extends AtomicWidget {
  final String? text;
  final Widget? child;
  final Color? backgroundColor;
  final Color? textColor;
  final AtomicBadgeSize size;

  const AtomicBadge({
    super.key,
    this.text,
    this.child,
    this.backgroundColor,
    this.textColor,
    this.size = AtomicBadgeSize.medium,
  }) : assert(
         text != null || child != null,
         'Either text or child must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final colorScheme = getColorScheme(context);
    final bgColor = backgroundColor ?? colorScheme.primary;
    final fgColor = textColor ?? colorScheme.onPrimary;

    return Container(
      padding: size.padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size.borderRadius),
      ),
      child:
          child ?? AtomicText(text!, variant: size.textVariant, color: fgColor),
    );
  }
}

/// Badge size enumeration
enum AtomicBadgeSize {
  small(
    EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    8.0,
    AtomicTextVariant.caption,
  ),
  medium(
    EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    12.0,
    AtomicTextVariant.labelSmall,
  ),
  large(
    EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    16.0,
    AtomicTextVariant.labelMedium,
  );

  const AtomicBadgeSize(this.padding, this.borderRadius, this.textVariant);

  final EdgeInsets padding;
  final double borderRadius;
  final AtomicTextVariant textVariant;
}

/// Atomic Chip Component
///
/// Interactive chip for selections and filters.
class AtomicChip extends AtomicWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final ValueChanged<bool>? onSelected;
  final VoidCallback? onDeleted;
  final Color? backgroundColor;
  final Color? selectedColor;

  const AtomicChip({
    super.key,
    required this.label,
    this.icon,
    this.isSelected = false,
    this.onSelected,
    this.onDeleted,
    this.backgroundColor,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getColorScheme(context);

    if (onDeleted != null) {
      return Chip(
        avatar: icon != null
            ? AtomicIcon(icon!, size: AtomicIconSize.small)
            : null,
        label: AtomicText(label, variant: AtomicTextVariant.labelMedium),
        onDeleted: onDeleted,
        backgroundColor: backgroundColor ?? colorScheme.surfaceContainerHighest,
        deleteIconColor: colorScheme.onSurfaceVariant,
      );
    }

    return FilterChip(
      avatar: icon != null
          ? AtomicIcon(icon!, size: AtomicIconSize.small)
          : null,
      label: AtomicText(label, variant: AtomicTextVariant.labelMedium),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: backgroundColor ?? colorScheme.surfaceContainerHighest,
      selectedColor: selectedColor ?? colorScheme.primaryContainer,
      checkmarkColor: colorScheme.primary,
    );
  }
}

/// Atomic Progress Indicator Component
///
/// Shows loading or progress state.
class AtomicProgressIndicator extends AtomicWidget {
  final double? value;
  final AtomicProgressType type;
  final AtomicProgressSize size;
  final Color? color;
  final Color? backgroundColor;

  const AtomicProgressIndicator({
    super.key,
    this.value,
    this.type = AtomicProgressType.circular,
    this.size = AtomicProgressSize.medium,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getColorScheme(context);
    final progressColor = color ?? colorScheme.primary;
    final bgColor = backgroundColor ?? colorScheme.surfaceContainerHighest;

    switch (type) {
      case AtomicProgressType.circular:
        return SizedBox(
          width: size.circularSize,
          height: size.circularSize,
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: size.strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            backgroundColor: bgColor,
          ),
        );
      case AtomicProgressType.linear:
        return SizedBox(
          height: size.linearHeight,
          child: LinearProgressIndicator(
            value: value,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            backgroundColor: bgColor,
          ),
        );
    }
  }
}

/// Progress indicator type enumeration
enum AtomicProgressType { circular, linear }

/// Progress indicator size enumeration
enum AtomicProgressSize {
  small(16.0, 2.0, 2.0),
  medium(24.0, 3.0, 4.0),
  large(32.0, 4.0, 6.0);

  const AtomicProgressSize(
    this.circularSize,
    this.strokeWidth,
    this.linearHeight,
  );

  final double circularSize;
  final double strokeWidth;
  final double linearHeight;
}

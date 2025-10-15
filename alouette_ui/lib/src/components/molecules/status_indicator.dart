import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import '../../tokens/app_tokens.dart';
import '../atoms/atomic_elements.dart';

/// Status Indicator Molecule
///
/// Consolidated status display component that shows status with icon, text, and optional action.
/// Replaces various status widgets throughout the applications.
class StatusIndicator extends StatelessWidget {
  final StatusType status;
  final String message;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final bool showIcon;
  final Widget? customIcon;

  const StatusIndicator({
    super.key,
    required this.status,
    required this.message,
    this.actionText,
    this.onActionPressed,
    this.showIcon = true,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: status.getBackgroundColor(colorScheme),
        borderRadius: BorderRadius.circular(DimensionTokens.radiusL),
        border: Border.all(color: status.getBorderColor(colorScheme)),
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            customIcon ??
                AtomicIcon(
                  status.icon,
                  size: AtomicIconSize.medium,
                  color: status.getIconColor(colorScheme),
                ),
            const AtomicSpacer(
              AtomicSpacing.small,
              direction: AtomicSpacerDirection.horizontal,
            ),
          ],
          Expanded(
            child: AtomicText(
              message,
              variant: AtomicTextVariant.body,
              color: status.getTextColor(colorScheme),
            ),
          ),
          if (actionText != null && onActionPressed != null) ...[
            const AtomicSpacer(
              AtomicSpacing.small,
              direction: AtomicSpacerDirection.horizontal,
            ),
            TextButton(onPressed: onActionPressed, child: Text(actionText!)),
          ],
        ],
      ),
    );
  }
}

/// Compact Status Indicator
///
/// Smaller version for inline status display
class CompactStatusIndicator extends StatelessWidget {
  final StatusType status;
  final String message;
  final bool showIcon;

  const CompactStatusIndicator({
    super.key,
    required this.status,
    required this.message,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.s,
        vertical: SpacingTokens.xs,
      ),
      decoration: BoxDecoration(
        color: status.getBackgroundColor(colorScheme),
        borderRadius: BorderRadius.circular(DimensionTokens.radiusS),
        border: Border.all(
          color: status.getBorderColor(colorScheme),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            AtomicIcon(
              status.icon,
              size: AtomicIconSize.small,
              color: status.getIconColor(colorScheme),
            ),
            const AtomicSpacer(
              AtomicSpacing.xs,
              direction: AtomicSpacerDirection.horizontal,
            ),
          ],
          AtomicText(
            message,
            variant: AtomicTextVariant.labelSmall,
            color: status.getTextColor(colorScheme),
          ),
        ],
      ),
    );
  }
}

/// Status Badge
///
/// Minimal status indicator for badges and chips
class StatusBadge extends StatelessWidget {
  final StatusType status;
  final String? text;
  final double size;

  const StatusBadge({
    super.key,
    required this.status,
    this.text,
    this.size = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (text != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: status.getBorderColor(colorScheme),
          borderRadius: BorderRadius.circular(size),
        ),
        child: AtomicText(
          text!,
          variant: AtomicTextVariant.caption,
          color: status.getOnColor(colorScheme),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: status.getBorderColor(colorScheme),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Status type enumeration
enum StatusType {
  info(Icons.info_outline),
  success(Icons.check_circle_outline),
  warning(Icons.warning_outlined),
  error(Icons.error_outline),
  loading(Icons.hourglass_empty),
  offline(Icons.wifi_off),
  online(Icons.wifi),
  processing(Icons.sync);

  const StatusType(this.icon);

  final IconData icon;

  Color getBackgroundColor(ColorScheme colorScheme) {
    switch (this) {
      case StatusType.info:
        return ColorTokens.infoContainer;
      case StatusType.success:
        return ColorTokens.successContainer;
      case StatusType.warning:
        return ColorTokens.warningContainer;
      case StatusType.error:
        return colorScheme.errorContainer;
      case StatusType.loading:
        return colorScheme.surfaceContainerHighest;
      case StatusType.offline:
        return colorScheme.errorContainer.withValues(alpha: 0.1);
      case StatusType.online:
        return ColorTokens.successContainer;
      case StatusType.processing:
        return colorScheme.primaryContainer.withValues(alpha: 0.1);
    }
  }

  Color getBorderColor(ColorScheme colorScheme) {
    switch (this) {
      case StatusType.info:
        return ColorTokens.info;
      case StatusType.success:
        return ColorTokens.success;
      case StatusType.warning:
        return ColorTokens.warning;
      case StatusType.error:
        return colorScheme.error;
      case StatusType.loading:
        return colorScheme.outline;
      case StatusType.offline:
        return colorScheme.error;
      case StatusType.online:
        return ColorTokens.success;
      case StatusType.processing:
        return colorScheme.primary;
    }
  }

  Color getIconColor(ColorScheme colorScheme) {
    return getBorderColor(colorScheme);
  }

  Color getTextColor(ColorScheme colorScheme) {
    switch (this) {
      case StatusType.info:
        return ColorTokens.onInfoContainer;
      case StatusType.success:
        return ColorTokens.onSuccessContainer;
      case StatusType.warning:
        return ColorTokens.onWarningContainer;
      case StatusType.error:
        return colorScheme.onErrorContainer;
      case StatusType.loading:
        return colorScheme.onSurfaceVariant;
      case StatusType.offline:
        return colorScheme.error;
      case StatusType.online:
        return ColorTokens.onSuccessContainer;
      case StatusType.processing:
        return colorScheme.primary;
    }
  }

  Color getOnColor(ColorScheme colorScheme) {
    switch (this) {
      case StatusType.info:
        return Colors.white;
      case StatusType.success:
        return Colors.white;
      case StatusType.warning:
        return Colors.black;
      case StatusType.error:
        return Colors.white;
      case StatusType.loading:
        return Colors.white;
      case StatusType.offline:
        return Colors.white;
      case StatusType.online:
        return Colors.white;
      case StatusType.processing:
        return Colors.white;
    }
  }
}

/// TTS Status Indicator
///
/// Specialized status indicator for TTS functionality that shows
/// initialization, playing, error, and ready states with appropriate
/// icons and messages.
class TTSStatusIndicator extends StatelessWidget {
  final bool isInitialized;
  final bool isPlaying;
  final TTSEngineType? currentEngine;
  final String? lastError;

  const TTSStatusIndicator({
    super.key,
    required this.isInitialized,
    required this.isPlaying,
    this.currentEngine,
    this.lastError,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Error state
    if (lastError != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AtomicIcon(
            Icons.error,
            size: AtomicIconSize.small,
            color: colorScheme.error,
          ),
          const AtomicSpacer(
            AtomicSpacing.xs,
            direction: AtomicSpacerDirection.horizontal,
          ),
          AtomicText(
            'Error',
            variant: AtomicTextVariant.labelSmall,
            color: colorScheme.error,
          ),
        ],
      );
    }

    // Initializing state
    if (!isInitialized) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: DimensionTokens.iconS,
            height: DimensionTokens.iconS,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const AtomicSpacer(
            AtomicSpacing.xs,
            direction: AtomicSpacerDirection.horizontal,
          ),
          AtomicText(
            'Initializing...',
            variant: AtomicTextVariant.labelSmall,
            color: colorScheme.primary,
          ),
        ],
      );
    }

    // Playing state
    if (isPlaying) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AtomicIcon(
            Icons.volume_up,
            size: AtomicIconSize.small,
            color: colorScheme.primary,
          ),
          const AtomicSpacer(
            AtomicSpacing.xs,
            direction: AtomicSpacerDirection.horizontal,
          ),
          AtomicText(
            'Speaking...',
            variant: AtomicTextVariant.labelSmall,
            color: colorScheme.primary,
          ),
        ],
      );
    }

    // Ready state
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AtomicIcon(
          Icons.check_circle,
          size: AtomicIconSize.small,
          color: colorScheme.primary,
        ),
        const AtomicSpacer(
          AtomicSpacing.xs,
          direction: AtomicSpacerDirection.horizontal,
        ),
        AtomicText(
          currentEngine != null
              ? '${_getEngineName(currentEngine!)} Ready'
              : 'Ready',
          variant: AtomicTextVariant.labelSmall,
          color: colorScheme.primary,
        ),
      ],
    );
  }

  String _getEngineName(TTSEngineType engine) {
    switch (engine) {
      case TTSEngineType.edge:
        return 'Edge TTS';
      case TTSEngineType.flutter:
        return 'Flutter TTS';
    }
  }
}

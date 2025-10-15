import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import '../themes/app_theme.dart';
import '../tokens/dimension_tokens.dart';
import 'custom_button.dart';

/// TTS状态指示卡片 - 紧凑版本，类似翻译应用的配置状态组件
class TTSStatusCard extends StatelessWidget {
  final bool isInitialized;
  final bool isPlaying;
  final TTSEngineType? currentEngine;
  final VoidCallback? onConfigurePressed;

  const TTSStatusCard({
    super.key,
    required this.isInitialized,
    required this.isPlaying,
    this.currentEngine,
    this.onConfigurePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(SpacingTokens.s),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DimensionTokens.radiusM),
        border: Border.all(
          color: _getStatusColor().withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(_getStatusIcon(), color: _getStatusColor(), size: 20),
          const SizedBox(width: 4), // Fixed small spacing to avoid overflow
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getStatusText(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (currentEngine != null)
                  Text(
                    'Engine: ${currentEngine!.name}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getStatusColor().withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
          if (!isInitialized && onConfigurePressed != null)
            CustomButton(
              text: 'Configure',
              onPressed: onConfigurePressed,
              type: CustomButtonType.text,
              size: CustomButtonSize.small,
              color: _getStatusColor(),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (!isInitialized) return Colors.orange;
    if (isPlaying) return Colors.green;
    return AppTheme.primaryColor;
  }

  IconData _getStatusIcon() {
    if (!isInitialized) return Icons.warning_outlined;
    if (isPlaying) return Icons.volume_up;
    return Icons.volume_off;
  }

  String _getStatusText() {
    if (!isInitialized) return 'TTS Not Initialized';
    if (isPlaying) return 'Currently Speaking...';
    return 'Ready to Speak';
  }
}

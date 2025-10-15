import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';
import '../controllers/tts_controller.dart' as local;

/// Widget for displaying TTS status information
class TTSStatusSection extends StatelessWidget {
  final local.TTSController controller;
  final VoidCallback? onConfigurePressed;

  const TTSStatusSection({
    super.key,
    required this.controller,
    this.onConfigurePressed,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getStatusColor(),
            ),
          ),
          const SizedBox(width: 12),

          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getStatusText(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (controller.isInitialized && controller.currentEngine != null)
                  Text(
                    'Engine: ${controller.currentEngine!.name.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),

          // Playing indicator
          if (controller.isPlaying)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Speaking...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

          // Configure button
          if (onConfigurePressed != null)
            IconButton(
              icon: const Icon(Icons.settings, size: 20),
              onPressed: onConfigurePressed,
              tooltip: 'Configure TTS',
            ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (!controller.isInitialized) {
      return Colors.orange;
    }
    
    if (controller.lastError != null) {
      return Colors.red;
    }
    
    if (controller.isPlaying) {
      return Colors.blue;
    }
    
    return Colors.green;
  }

  String _getStatusText() {
    if (!controller.isInitialized) {
      return 'Initializing TTS...';
    }
    
    if (controller.lastError != null) {
      return 'TTS Error';
    }
    
    if (controller.isPlaying) {
      return 'TTS Active';
    }
    
    return 'TTS Ready';
  }
}
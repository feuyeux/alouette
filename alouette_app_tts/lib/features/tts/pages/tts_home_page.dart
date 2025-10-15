import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';
import '../controllers/tts_controller.dart' as local;
import 'tts_page.dart';
// Restore simple status inline to avoid missing widget dependency
import '../../../config/tts_app_config.dart';

/// Home page for the TTS application
class TTSHomePage extends StatefulWidget {
  const TTSHomePage({super.key});

  @override
  State<TTSHomePage> createState() => _TTSHomePageState();
}

class _TTSHomePageState extends State<TTSHomePage> {
  late local.TTSController _ttsController;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ttsController = local.TTSController();
    _ttsController.addListener(_onControllerChanged);
    _initializeTTS();
  }

  Future<void> _initializeTTS() async {
    await _ttsController.initialize();
  }

  @override
  void dispose() {
    _textController.dispose();
    _ttsController.removeListener(_onControllerChanged);
    _ttsController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _showTTSSettings() async {
    // Show TTS configuration dialog
    final platformInfo = await _ttsController.getPlatformInfo();

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('TTS Settings'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Current Engine: ${_ttsController.currentEngine?.name ?? 'None'}',
                ),
                const SizedBox(height: 8),
                Text('Platform: ${platformInfo['platform'] ?? 'Unknown'}'),
                const SizedBox(height: 8),
                Text('Backend: ${platformInfo['currentBackend'] ?? 'Unknown'}'),
                const SizedBox(height: 8),
                Text(
                  'Supported Engines: ${platformInfo['supportedEngines']?.join(', ') ?? 'None'}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Available Engines: ${platformInfo['availableEngines']?.join(', ') ?? 'None'}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Recommended Engine: ${platformInfo['recommendedEngine'] ?? 'None'}',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Voice Parameters:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Rate: ${_ttsController.rate.toStringAsFixed(1)}x'),
                Text('Pitch: ${_ttsController.pitch.toStringAsFixed(1)}x'),
                Text('Volume: ${(_ttsController.volume * 100).toInt()}%'),
                const SizedBox(height: 16),
                const Text(
                  'Platform Features:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Desktop: ${platformInfo['isDesktop'] ?? false}'),
                Text('Mobile: ${platformInfo['isMobile'] ?? false}'),
                Text('Web: ${platformInfo['isWeb'] ?? false}'),
                Text(
                  'Process Execution: ${platformInfo['supportsProcessExecution'] ?? false}',
                ),
                Text(
                  'File System: ${platformInfo['supportsFileSystem'] ?? false}',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show error if there's one
    if (_ttsController.lastError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showError(_ttsController.lastError!);
      });
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: TTSAppConfig.appTitle,
        showLogo: true,
        statusWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _ttsController.isInitialized ? Icons.check_circle : Icons.error,
              color: _ttsController.isInitialized ? Colors.green : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              _ttsController.isInitialized
                  ? (_ttsController.isPlaying ? 'Playing' : 'Ready')
                  : 'Not ready',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showTTSSettings,
            tooltip: 'TTS Settings',
          ),
          AboutHelper.createAboutButton(
            context,
            appName: 'Alouette TTS',
            copyright: 'Copyright © 2025 @feuyeux. All rights reserved.',
          ),
        ],
      ),
      body: TTSPage(
        controller: _ttsController,
        textController: _textController,
      ),
    );
  }
}

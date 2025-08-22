import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../../exceptions/tts_exception.dart';
import '../../models/alouette_tts_config.dart';
import '../../enums/tts_platform.dart';

/// Command-line client for Edge TTS as a fallback when WebSocket fails
class EdgeTTSCommandLineClient {
  static const String _edgeTTSCommand = 'edge-tts';

  /// Checks if edge-tts command is available on the system
  static Future<bool> isAvailable() async {
    try {
      // On Windows, use 'where' instead of 'which'
      if (Platform.isWindows) {
        final result = await Process.run('where', [_edgeTTSCommand]);
        return result.exitCode == 0;
      } else {
        final result = await Process.run('which', [_edgeTTSCommand]);
        return result.exitCode == 0;
      }
    } catch (e) {
      // Try alternative check - run the command with --help
      try {
        final result = await Process.run(_edgeTTSCommand, ['--help']);
        return result.exitCode == 0;
      } catch (e) {
        return false;
      }
    }
  }

  /// Synthesizes text to audio using the edge-tts command-line tool
  Future<Uint8List> synthesize(String text, AlouetteTTSConfig config) async {
    if (!await isAvailable()) {
      throw TTSPlatformException(
        'edge-tts command-line tool is not available. Please install it using: pip install edge-tts',
        TTSPlatform.linux, // Default to Linux, could be any desktop platform
      );
    }

    final tempDir = Directory.systemTemp;
    final outputFile = File(
      '${tempDir.path}/tts_output_${const Uuid().v4()}.mp3',
    );

    try {
      await _runEdgeTTSCommand(text, config, outputFile.path);

      if (!await outputFile.exists()) {
        throw TTSSynthesisException(
          'Edge TTS command failed to generate audio file',
          text: text,
        );
      }

      final audioData = await outputFile.readAsBytes();
      return Uint8List.fromList(audioData);
    } finally {
      // Clean up temporary file
      if (await outputFile.exists()) {
        try {
          final savedPath = '/tmp/alouette_last_tts.mp3';
          final savedFile = File(savedPath);
          await outputFile.copy(savedFile.path);
        } catch (e) {
          // Failed to copy generated audio for debugging
        }

        try {
          await outputFile.delete();
        } catch (e) {
          // Ignore cleanup errors
        }
      }
    }
  }

  /// Runs the edge-tts command with the specified parameters
  Future<void> _runEdgeTTSCommand(
    String text,
    AlouetteTTSConfig config,
    String outputPath,
  ) async {
    final args = <String>['--text', text, '--write-media', outputPath];

    // Add voice if specified
    if (config.voiceName != null) {
      args.addAll(['--voice', config.voiceName!]);
    } else {
      // Use default voice based on language
      final defaultVoice = _getDefaultVoiceForLanguage(config.languageCode);
      args.addAll(['--voice', defaultVoice]);
    }

    // Add rate if different from default
    if (config.speechRate != 1.0) {
      // Edge TTS expects rate as +/-N% format
      final rateChange = ((config.speechRate - 1.0) * 100).round();
      final rateParam = rateChange >= 0 ? '+${rateChange}%' : '${rateChange}%';
      args.addAll(['--rate', rateParam]);
    }

    // Add volume if different from default
    if (config.volume != 1.0) {
      // Edge TTS expects volume as +/-N% format
      final volumeChange = ((config.volume - 1.0) * 100).round();
      final volumeParam = volumeChange >= 0
          ? '+${volumeChange}%'
          : '${volumeChange}%';
      args.addAll(['--volume', volumeParam]);
    }

    // Add pitch if different from default
    if (config.pitch != 1.0) {
      final pitchHz = _convertPitchToHz(config.pitch);
      args.addAll(['--pitch', '${pitchHz}Hz']);
    }

    try {
      final result = await Process.run(_edgeTTSCommand, args);

      if (result.exitCode != 0) {
        final errorOutput = result.stderr as String? ?? 'Unknown error';
        throw TTSSynthesisException(
          'Edge TTS command failed: $errorOutput',
          text: text,
        );
      }
    } catch (e) {
      if (e is TTSException) rethrow;
      throw TTSSynthesisException(
        'Failed to run edge-tts command: $e',
        text: text,
      );
    }
  }

  /// Gets the default voice name for a language code
  String _getDefaultVoiceForLanguage(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'en-us':
        return 'en-US-AriaNeural';
      case 'en-gb':
        return 'en-GB-SoniaNeural';
      case 'en-au':
        return 'en-AU-NatashaNeural';
      case 'en-ca':
        return 'en-CA-ClaraNeural';
      case 'es-es':
        return 'es-ES-ElviraNeural';
      case 'es-mx':
        return 'es-MX-DaliaNeural';
      case 'fr-fr':
        return 'fr-FR-DeniseNeural';
      case 'fr-ca':
        return 'fr-CA-SylvieNeural';
      case 'de-de':
        return 'de-DE-KatjaNeural';
      case 'it-it':
        return 'it-IT-ElsaNeural';
      case 'pt-br':
        return 'pt-BR-FranciscaNeural';
      case 'pt-pt':
        return 'pt-PT-RaquelNeural';
      case 'ru-ru':
        return 'ru-RU-SvetlanaNeural';
      case 'ja-jp':
        return 'ja-JP-NanamiNeural';
      case 'ko-kr':
        return 'ko-KR-SunHiNeural';
      case 'zh-cn':
        return 'zh-CN-XiaoxiaoNeural';
      case 'zh-tw':
        return 'zh-TW-HsiaoChenNeural';
      case 'ar':
      case 'ar-sa':
        return 'ar-SA-ZariyahNeural';
      case 'hi-in':
        return 'hi-IN-SwaraNeural';
      case 'el-gr':
        return 'el-GR-AthinaNeural';
      default:
        // Fallback to US English
        return 'en-US-AriaNeural';
    }
  }

  /// Converts pitch value (0.0-2.0) to Hz for edge-tts
  String _convertPitchToHz(double pitch) {
    // Convert pitch multiplier to Hz offset
    // 1.0 = 0Hz (default), 0.5 = -50Hz, 2.0 = +50Hz
    final hzOffset = ((pitch - 1.0) * 50).round();
    if (hzOffset >= 0) {
      return '+$hzOffset';
    } else {
      return hzOffset.toString();
    }
  }

  /// Lists available voices using the edge-tts command
  Future<List<String>> listAvailableVoices() async {
    if (!await isAvailable()) {
      throw TTSPlatformException(
        'edge-tts command-line tool is not available',
        TTSPlatform.linux,
      );
    }

    try {
      final result = await Process.run(_edgeTTSCommand, ['--list-voices']);

      if (result.exitCode != 0) {
        throw TTSPlatformException(
          'Failed to list voices: ${result.stderr}',
          TTSPlatform.linux,
        );
      }

      final output = result.stdout as String;
      final voices = <String>[];

      // Parse the voice list output
      for (final line in output.split('\n')) {
        if (line.trim().isNotEmpty && !line.startsWith('Name:')) {
          // Extract voice name from the line
          final match = RegExp(r'^([^:]+):').firstMatch(line.trim());
          if (match != null) {
            voices.add(match.group(1)!.trim());
          }
        }
      }

      return voices;
    } catch (e) {
      if (e is TTSException) rethrow;
      throw TTSPlatformException(
        'Failed to list voices: $e',
        TTSPlatform.linux,
      );
    }
  }

  /// Validates if a voice is available
  Future<bool> isVoiceAvailable(String voiceName) async {
    try {
      final availableVoices = await listAvailableVoices();
      return availableVoices.contains(voiceName);
    } catch (e) {
      return false;
    }
  }

  /// Gets voice information for a specific voice
  Future<Map<String, dynamic>?> getVoiceInfo(String voiceName) async {
    if (!await isAvailable()) {
      return null;
    }

    try {
      final result = await Process.run(_edgeTTSCommand, ['--list-voices']);

      if (result.exitCode != 0) {
        return null;
      }

      final output = result.stdout as String;

      // Find the voice in the output
      for (final line in output.split('\n')) {
        if (line.trim().startsWith('$voiceName:')) {
          // Parse voice information from the line
          final parts = line.split(',');
          final info = <String, dynamic>{
            'name': voiceName,
            'language': _extractLanguageFromVoiceName(voiceName),
            'gender': _extractGenderFromVoiceName(voiceName),
            'quality': _extractQualityFromVoiceName(voiceName),
          };

          return info;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Extracts language code from voice name
  String _extractLanguageFromVoiceName(String voiceName) {
    // Voice names often use formats like zh-CN-XiaoxiaoNeural; extract and normalize to lower-case
  // Match e.g. zh-CN or en-US (case-insensitive) at start
  final match = RegExp(r'^([a-z]{2}-[A-Z]{2})', caseSensitive: false).firstMatch(voiceName);
  final code = match?.group(1) ?? 'en-us';
  return code.toLowerCase();
  }

  /// Extracts gender from voice name
  String _extractGenderFromVoiceName(String voiceName) {
    if (voiceName.toLowerCase().contains('male')) {
      return 'male';
    } else if (voiceName.toLowerCase().contains('female')) {
      return 'female';
    }

    // Try to infer from common name patterns
    final namePart = voiceName.split('-').last.toLowerCase();
    final maleNames = ['guy', 'davis', 'tony', 'brian', 'connor'];
    final femaleNames = ['aria', 'jenny', 'sonia', 'clara', 'elvira', 'dalia'];

    if (maleNames.any((name) => namePart.contains(name))) {
      return 'male';
    } else if (femaleNames.any((name) => namePart.contains(name))) {
      return 'female';
    }

    return 'neutral';
  }

  /// Extracts quality from voice name
  String _extractQualityFromVoiceName(String voiceName) {
    if (voiceName.toLowerCase().contains('neural')) {
      return 'neural';
    } else if (voiceName.toLowerCase().contains('premium')) {
      return 'premium';
    }
    return 'standard';
  }
}

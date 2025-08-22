import '../../models/alouette_tts_config.dart';
import '../../models/alouette_voice.dart';

/// Generates SSML markup for Edge TTS synthesis
class EdgeTTSSSMLGenerator {
  /// Generates SSML from plain text and configuration
  static String generateSSML(
    String text,
    AlouetteTTSConfig config, {
    AlouetteVoice? voice,
  }) {
    // 优先使用配置中的voiceName，其次是voice对象，最后是根据languageCode的默认值
    final voiceName = config.voiceName ?? 
        voice?.toEdgeTTSVoiceName() ??
        _getDefaultVoiceName(config.languageCode);
    final rate = _formatRate(config.speechRate);
    final pitch = _formatPitch(config.pitch);
    final volume = _formatVolume(config.volume);

    return '''<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="${config.languageCode}">
  <voice name="$voiceName">
    <prosody rate="$rate" pitch="$pitch" volume="$volume">
      ${_escapeXml(text)}
    </prosody>
  </voice>
</speak>''';
  }

  /// Validates and processes existing SSML markup
  static String processSSML(
    String ssml,
    AlouetteTTSConfig config, {
    AlouetteVoice? voice,
  }) {
    // If the SSML already contains a speak element, use it as-is
    if (ssml.trim().startsWith('<speak')) {
      return _validateAndEnhanceSSML(ssml, config, voice);
    }

    // If it's partial SSML (like just prosody or voice tags), wrap it
    if (ssml.contains('<')) {
      return generateSSML(ssml, config, voice: voice);
    }

    // If it's plain text, generate full SSML
    return generateSSML(ssml, config, voice: voice);
  }

  /// Formats speech rate for Edge TTS
  static String _formatRate(double rate) {
    // Convert 0.0-2.0 range to percentage
    final percentage = (rate * 100).round();
    return '${percentage}%';
  }

  /// Formats pitch for Edge TTS
  static String _formatPitch(double pitch) {
    // Convert 0.0-2.0 range to semitones
    // 1.0 = 0st (default), 0.5 = -12st, 2.0 = +12st
    final semitones = ((pitch - 1.0) * 12).round();
    if (semitones >= 0) {
      return '+${semitones}st';
    } else {
      return '${semitones}st';
    }
  }

  /// Formats volume for Edge TTS
  static String _formatVolume(double volume) {
    // Convert 0.0-1.0 range to percentage
    final percentage = (volume * 100).round();
    return '${percentage}%';
  }

  /// Gets default voice name for a language code
  static String _getDefaultVoiceName(String languageCode) {
    // Map common language codes to Edge TTS voice names
    // Use the correct format that matches hello-edge-tts success pattern
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

  /// Validates and enhances existing SSML
  static String _validateAndEnhanceSSML(
    String ssml,
    AlouetteTTSConfig config,
    AlouetteVoice? voice,
  ) {
    // Basic SSML validation and enhancement
    String processedSSML = ssml;

    // Ensure proper XML declaration if missing
    if (!processedSSML.contains('version="1.0"')) {
      processedSSML = processedSSML.replaceFirst(
        '<speak',
        '<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis"',
      );
    }

    // Add xml:lang if missing
    if (!processedSSML.contains('xml:lang')) {
      processedSSML = processedSSML.replaceFirst(
        '<speak',
        '<speak xml:lang="${config.languageCode}"',
      );
    }

    return processedSSML;
  }

  /// Escapes XML special characters
  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// Validates SSML syntax
  static bool isValidSSML(String ssml) {
    try {
      // Basic validation - check for balanced tags
      final speakCount = '<speak'.allMatches(ssml).length;
      final speakEndCount = '</speak>'.allMatches(ssml).length;

      if (speakCount != speakEndCount) return false;

      // Check for required attributes
      if (ssml.contains('<speak') && !ssml.contains('version=')) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Extracts text content from SSML
  static String extractTextFromSSML(String ssml) {
    // Remove XML tags and return plain text
    return ssml
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .trim();
  }
}

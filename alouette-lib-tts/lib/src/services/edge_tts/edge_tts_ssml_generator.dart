import '../../models/alouette_tts_config.dart';
import '../../models/alouette_voice.dart';

/// Generates SSML markup for Edge TTS synthesis
class EdgeTTSSSMLGenerator {
  /// Generates SSML from plain text and configuration
  static String generateSSML(String text, AlouetteTTSConfig config, {AlouetteVoice? voice}) {
    final voiceName = voice?.toEdgeTTSVoiceName() ?? _getDefaultVoiceName(config.languageCode);
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
  static String processSSML(String ssml, AlouetteTTSConfig config, {AlouetteVoice? voice}) {
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
    switch (languageCode.toLowerCase()) {
      case 'en-us':
        return 'Microsoft Server Speech Text to Speech Voice (en-US, AriaNeural)';
      case 'en-gb':
        return 'Microsoft Server Speech Text to Speech Voice (en-GB, SoniaNeural)';
      case 'en-au':
        return 'Microsoft Server Speech Text to Speech Voice (en-AU, NatashaNeural)';
      case 'en-ca':
        return 'Microsoft Server Speech Text to Speech Voice (en-CA, ClaraNeural)';
      case 'es-es':
        return 'Microsoft Server Speech Text to Speech Voice (es-ES, ElviraNeural)';
      case 'es-mx':
        return 'Microsoft Server Speech Text to Speech Voice (es-MX, DaliaNeural)';
      case 'fr-fr':
        return 'Microsoft Server Speech Text to Speech Voice (fr-FR, DeniseNeural)';
      case 'fr-ca':
        return 'Microsoft Server Speech Text to Speech Voice (fr-CA, SylvieNeural)';
      case 'de-de':
        return 'Microsoft Server Speech Text to Speech Voice (de-DE, KatjaNeural)';
      case 'it-it':
        return 'Microsoft Server Speech Text to Speech Voice (it-IT, ElsaNeural)';
      case 'pt-br':
        return 'Microsoft Server Speech Text to Speech Voice (pt-BR, FranciscaNeural)';
      case 'pt-pt':
        return 'Microsoft Server Speech Text to Speech Voice (pt-PT, RaquelNeural)';
      case 'ru-ru':
        return 'Microsoft Server Speech Text to Speech Voice (ru-RU, SvetlanaNeural)';
      case 'ja-jp':
        return 'Microsoft Server Speech Text to Speech Voice (ja-JP, NanamiNeural)';
      case 'ko-kr':
        return 'Microsoft Server Speech Text to Speech Voice (ko-KR, SunHiNeural)';
      case 'zh-cn':
        return 'Microsoft Server Speech Text to Speech Voice (zh-CN, XiaoxiaoNeural)';
      case 'zh-tw':
        return 'Microsoft Server Speech Text to Speech Voice (zh-TW, HsiaoChenNeural)';
      case 'ar-sa':
        return 'Microsoft Server Speech Text to Speech Voice (ar-SA, ZariyahNeural)';
      case 'hi-in':
        return 'Microsoft Server Speech Text to Speech Voice (hi-IN, SwaraNeural)';
      default:
        // Fallback to US English
        return 'Microsoft Server Speech Text to Speech Voice (en-US, AriaNeural)';
    }
  }
  
  /// Validates and enhances existing SSML
  static String _validateAndEnhanceSSML(String ssml, AlouetteTTSConfig config, AlouetteVoice? voice) {
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
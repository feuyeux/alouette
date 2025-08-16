import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/alouette_voice.dart';
import '../../enums/tts_platform.dart';
import '../../enums/voice_gender.dart';
import '../../enums/voice_quality.dart';
import '../../exceptions/tts_exception.dart';
import 'edge_tts_command_line_client.dart';

/// Discovers and manages Edge TTS voices from multiple sources
class EdgeTTSVoiceDiscovery {
  static const String _edgeTTSVoicesUrl =
      'https://speech.platform.bing.com/consumer/speech/synthesize/realtimestreaming/edge/v1/voices';
  static const Duration _httpTimeout = Duration(seconds: 10);

  final http.Client _httpClient;

  EdgeTTSVoiceDiscovery({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Discovers voices from Edge TTS API
  Future<List<AlouetteVoice>> discoverVoicesFromAPI() async {
    try {
      final response = await _httpClient.get(
        Uri.parse(_edgeTTSVoicesUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'application/json',
        },
      ).timeout(_httpTimeout);

      if (response.statusCode != 200) {
        throw TTSNetworkException(
          'Failed to fetch voices from Edge TTS API',
          endpoint: _edgeTTSVoicesUrl,
          statusCode: response.statusCode,
        );
      }

      final List<dynamic> voicesJson = jsonDecode(response.body);
      final voices = <AlouetteVoice>[];

      for (final voiceData in voicesJson) {
        try {
          final voice = _parseVoiceFromAPI(voiceData);
          if (voice != null) {
            voices.add(voice);
          }
        } catch (e) {
          // Skip invalid voice entries but continue processing others
          continue;
        }
      }

      return voices;
    } catch (e) {
      if (e is TTSException) rethrow;
      throw TTSNetworkException(
        'Failed to discover voices from API: $e',
        endpoint: _edgeTTSVoicesUrl,
      );
    }
  }

  /// Discovers voices using the command-line client
  Future<List<AlouetteVoice>> discoverVoicesFromCommandLine() async {
    final cmdClient = EdgeTTSCommandLineClient();

    try {
      final voiceNames = await cmdClient.listAvailableVoices();
      final voices = <AlouetteVoice>[];

      for (final voiceName in voiceNames) {
        try {
          final voiceInfo = await cmdClient.getVoiceInfo(voiceName);
          if (voiceInfo != null) {
            final voice = _parseVoiceFromCommandLine(voiceName, voiceInfo);
            if (voice != null) {
              voices.add(voice);
            }
          }
        } catch (e) {
          // Skip invalid voices but continue processing others
          continue;
        }
      }

      return voices;
    } catch (e) {
      if (e is TTSException) rethrow;
      throw TTSPlatformException(
        'Failed to discover voices from command line: $e',
        TTSPlatform.linux,
      );
    }
  }

  /// Discovers voices using the best available method
  Future<List<AlouetteVoice>> discoverVoices() async {
    // Try API first as it's more comprehensive
    try {
      final apiVoices = await discoverVoicesFromAPI();
      if (apiVoices.isNotEmpty) {
        return apiVoices;
      }
    } catch (e) {
      // API failed, continue to command-line fallback
    }

    // Fallback to command-line if API fails or returns empty
    try {
      final cmdVoices = await discoverVoicesFromCommandLine();
      if (cmdVoices.isNotEmpty) {
        return cmdVoices;
      }
    } catch (cmdError) {
      // Command-line failed, continue to default fallback
    }

    // If both fail or return empty, return a default set of voices
    return _getDefaultVoices();
  }

  /// Parses voice data from the Edge TTS API response
  AlouetteVoice? _parseVoiceFromAPI(Map<String, dynamic> voiceData) {
    try {
      final name = voiceData['Name'] as String?;
      final displayName = voiceData['DisplayName'] as String?;
      final localName = voiceData['LocalName'] as String?;
      final shortName = voiceData['ShortName'] as String?;
      final gender = voiceData['Gender'] as String?;
      final locale = voiceData['Locale'] as String?;
      final styleList = voiceData['StyleList'] as List<dynamic>?;
      final voiceType = voiceData['VoiceType'] as String?;

      if (name == null || locale == null) return null;

      // Determine voice quality
      VoiceQuality quality = VoiceQuality.standard;
      if (name.toLowerCase().contains('neural')) {
        quality = VoiceQuality.neural;
      } else if (name.toLowerCase().contains('premium')) {
        quality = VoiceQuality.premium;
      }

      // Determine gender
      VoiceGender voiceGender = VoiceGender.neutral;
      if (gender != null) {
        switch (gender.toLowerCase()) {
          case 'male':
            voiceGender = VoiceGender.male;
            break;
          case 'female':
            voiceGender = VoiceGender.female;
            break;
          default:
            voiceGender = VoiceGender.neutral;
        }
      }

      // Extract country code from locale (e.g., 'en-US' -> 'US')
      final localeParts = locale.split('-');
      final countryCode = localeParts.length > 1 ? localeParts[1] : null;

      return AlouetteVoice.fromPlatformData(
        id: shortName ?? name,
        name: displayName ?? localName ?? name,
        languageCode: locale,
        platform: TTSPlatform.windows,
        countryCode: countryCode,
        gender: voiceGender,
        quality: quality,
        metadata: {
          'edgeTTSName': name,
          'shortName': shortName,
          'displayName': displayName,
          'localName': localName,
          'voiceType': voiceType,
          'styleList': styleList,
          'supportsSSML': true,
        },
      );
    } catch (e) {
      return null;
    }
  }

  /// Parses voice data from command-line client
  AlouetteVoice? _parseVoiceFromCommandLine(
      String voiceName, Map<String, dynamic> voiceInfo) {
    try {
      final language = voiceInfo['language'] as String? ?? 'en-US';
      final gender = voiceInfo['gender'] as String? ?? 'neutral';
      final quality = voiceInfo['quality'] as String? ?? 'standard';

      // Parse gender
      VoiceGender voiceGender = VoiceGender.neutral;
      switch (gender.toLowerCase()) {
        case 'male':
          voiceGender = VoiceGender.male;
          break;
        case 'female':
          voiceGender = VoiceGender.female;
          break;
        default:
          voiceGender = VoiceGender.neutral;
      }

      // Parse quality
      VoiceQuality voiceQuality = VoiceQuality.standard;
      switch (quality.toLowerCase()) {
        case 'neural':
          voiceQuality = VoiceQuality.neural;
          break;
        case 'premium':
          voiceQuality = VoiceQuality.premium;
          break;
        default:
          voiceQuality = VoiceQuality.standard;
      }

      // Extract country code from language
      final languageParts = language.split('-');
      final countryCode = languageParts.length > 1 ? languageParts[1] : null;

      return AlouetteVoice.fromPlatformData(
        id: voiceName,
        name: voiceName,
        languageCode: language,
        platform: TTSPlatform.windows,
        countryCode: countryCode,
        gender: voiceGender,
        quality: voiceQuality,
        metadata: {
          'edgeTTSName': voiceName,
          'supportsSSML': true,
        },
      );
    } catch (e) {
      return null;
    }
  }

  /// Returns a default set of voices when discovery fails
  List<AlouetteVoice> _getDefaultVoices() {
    return [
      // English voices
      AlouetteVoice.fromPlatformData(
        id: 'en-US-AriaNeural',
        name: 'Aria (Neural)',
        languageCode: 'en-US',
        platform: TTSPlatform.windows,
        countryCode: 'US',
        gender: VoiceGender.female,
        quality: VoiceQuality.neural,
        isDefault: true,
        metadata: {
          'edgeTTSName':
              'Microsoft Server Speech Text to Speech Voice (en-US, AriaNeural)',
          'supportsSSML': true,
        },
      ),
      AlouetteVoice.fromPlatformData(
        id: 'en-US-GuyNeural',
        name: 'Guy (Neural)',
        languageCode: 'en-US',
        platform: TTSPlatform.windows,
        countryCode: 'US',
        gender: VoiceGender.male,
        quality: VoiceQuality.neural,
        metadata: {
          'edgeTTSName':
              'Microsoft Server Speech Text to Speech Voice (en-US, GuyNeural)',
          'supportsSSML': true,
        },
      ),
      AlouetteVoice.fromPlatformData(
        id: 'en-GB-SoniaNeural',
        name: 'Sonia (Neural)',
        languageCode: 'en-GB',
        platform: TTSPlatform.windows,
        countryCode: 'GB',
        gender: VoiceGender.female,
        quality: VoiceQuality.neural,
        metadata: {
          'edgeTTSName':
              'Microsoft Server Speech Text to Speech Voice (en-GB, SoniaNeural)',
          'supportsSSML': true,
        },
      ),

      // Spanish voices
      AlouetteVoice.fromPlatformData(
        id: 'es-ES-ElviraNeural',
        name: 'Elvira (Neural)',
        languageCode: 'es-ES',
        platform: TTSPlatform.windows,
        countryCode: 'ES',
        gender: VoiceGender.female,
        quality: VoiceQuality.neural,
        metadata: {
          'edgeTTSName':
              'Microsoft Server Speech Text to Speech Voice (es-ES, ElviraNeural)',
          'supportsSSML': true,
        },
      ),
      AlouetteVoice.fromPlatformData(
        id: 'es-MX-DaliaNeural',
        name: 'Dalia (Neural)',
        languageCode: 'es-MX',
        platform: TTSPlatform.windows,
        countryCode: 'MX',
        gender: VoiceGender.female,
        quality: VoiceQuality.neural,
        metadata: {
          'edgeTTSName':
              'Microsoft Server Speech Text to Speech Voice (es-MX, DaliaNeural)',
          'supportsSSML': true,
        },
      ),

      // French voices
      AlouetteVoice.fromPlatformData(
        id: 'fr-FR-DeniseNeural',
        name: 'Denise (Neural)',
        languageCode: 'fr-FR',
        platform: TTSPlatform.windows,
        countryCode: 'FR',
        gender: VoiceGender.female,
        quality: VoiceQuality.neural,
        metadata: {
          'edgeTTSName':
              'Microsoft Server Speech Text to Speech Voice (fr-FR, DeniseNeural)',
          'supportsSSML': true,
        },
      ),

      // German voices
      AlouetteVoice.fromPlatformData(
        id: 'de-DE-KatjaNeural',
        name: 'Katja (Neural)',
        languageCode: 'de-DE',
        platform: TTSPlatform.windows,
        countryCode: 'DE',
        gender: VoiceGender.female,
        quality: VoiceQuality.neural,
        metadata: {
          'edgeTTSName':
              'Microsoft Server Speech Text to Speech Voice (de-DE, KatjaNeural)',
          'supportsSSML': true,
        },
      ),
    ];
  }

  /// Filters voices by language
  List<AlouetteVoice> filterByLanguage(
      List<AlouetteVoice> voices, String languageCode) {
    return voices
        .where((voice) =>
            voice.languageCode.toLowerCase() == languageCode.toLowerCase() ||
            voice.languageCode
                .toLowerCase()
                .startsWith('${languageCode.split('-').first.toLowerCase()}-'))
        .toList();
  }

  /// Filters voices by gender
  List<AlouetteVoice> filterByGender(
      List<AlouetteVoice> voices, VoiceGender gender) {
    return voices.where((voice) => voice.gender == gender).toList();
  }

  /// Filters voices by quality
  List<AlouetteVoice> filterByQuality(
      List<AlouetteVoice> voices, VoiceQuality quality) {
    return voices.where((voice) => voice.quality == quality).toList();
  }

  /// Sorts voices by preference (default first, then by quality)
  List<AlouetteVoice> sortByPreference(List<AlouetteVoice> voices) {
    final sortedVoices = List<AlouetteVoice>.from(voices);

    sortedVoices.sort((a, b) {
      // Default voices first
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;

      // Then by quality (neural > premium > standard)
      final qualityOrder = [
        VoiceQuality.neural,
        VoiceQuality.premium,
        VoiceQuality.standard
      ];
      final aQualityIndex = qualityOrder.indexOf(a.quality);
      final bQualityIndex = qualityOrder.indexOf(b.quality);

      if (aQualityIndex != bQualityIndex) {
        return aQualityIndex.compareTo(bQualityIndex);
      }

      // Finally by name
      return a.name.compareTo(b.name);
    });

    return sortedVoices;
  }

  /// Disposes of resources
  void dispose() {
    _httpClient.close();
  }
}

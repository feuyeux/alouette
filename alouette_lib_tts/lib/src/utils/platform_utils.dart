import 'dart:io' show Directory, Platform, Process;
import 'package:flutter/foundation.dart';
import '../enums/tts_engine_type.dart';

/// Platform detection and TTS engine selection utility class
/// Provides cross-platform detection and TTS strategy management
/// Combines functionality from both PlatformUtils and PlatformDetector
class PlatformUtils {
  /// Check if current platform is desktop
  /// Includes Windows, macOS, Linux
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// Check if current platform is mobile
  /// Includes Android, iOS
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Check if current platform is web
  static bool get isWeb => kIsWeb;

  /// Check if current platform should use narrow screen layout
  /// Returns true for mobile devices (iOS/Android), false for desktop/web
  /// This is used to determine UI layout (e.g., showing language short codes vs full names)
  static bool get isNarrowScreen => isMobile;

  /// Get the current platform name
  static String get platformName {
    if (kIsWeb) return 'web';
    if (!kIsWeb && Platform.isWindows) return 'windows';
    if (!kIsWeb && Platform.isMacOS) return 'macos';
    if (!kIsWeb && Platform.isLinux) return 'linux';
    if (!kIsWeb && Platform.isAndroid) return 'android';
    if (!kIsWeb && Platform.isIOS) return 'ios';
    return 'unknown';
  }

  /// Check if platform supports process execution
  static bool get supportsProcessExecution {
    return !kIsWeb && isDesktop;
  }

  /// Check if platform supports file system operations
  static bool get supportsFileSystem {
    return !kIsWeb;
  }

  /// Check if Flutter TTS is supported on this platform
  static bool get isFlutterTTSSupported => true;

  /// Check if current platform natively supports regional indicator emoji flags.
  ///
  /// Returns `false` for Windows desktop (lacks emoji glyphs in default fonts),
  /// `true` for all other platforms (web, macOS, iOS, Android, Linux).
  ///
  /// This determines the rendering strategy in LanguageFlagIcon:
  /// - `true`: Use emoji with EmojiFlagStyle font fallbacks
  /// - `false`: Use PNG assets from country_icons package
  static bool get supportsEmojiFlags {
    // Web browsers handle emoji fallback automatically
    if (kIsWeb) return true;

    // Windows lacks regional indicator glyphs in Segoe UI (default font)
    // Even with Segoe UI Emoji, coverage is incomplete - use PNG assets
    if (Platform.isWindows) return false;

    // macOS, iOS, Android, Linux have comprehensive emoji support
    return true;
  }

  /// Get platform-appropriate flag representation
  static String getFlag(String emojiFlag, String languageCode) {
    if (supportsEmojiFlags) {
      return emojiFlag;
    }
    // For Windows, use language codes in brackets
    return '[$languageCode]';
  }

  /// Get platform-appropriate flag widget font size
  static double get flagFontSize => supportsEmojiFlags ? 16.0 : 12.0;

  /// Get recommended TTS engine type
  /// Desktop platforms prefer Edge TTS, Mobile/Web platforms use Flutter TTS
  static TTSEngineType get recommendedEngine {
    if (isDesktop && supportsProcessExecution) {
      return TTSEngineType.edge;
    }
    return TTSEngineType.flutter;
  }

  /// Get platform-specific information
  static Map<String, dynamic> getPlatformInfo() {
    return {
      'platform': platformName,
      'isDesktop': isDesktop,
      'isMobile': isMobile,
      'isWeb': isWeb,
      'supportsProcessExecution': supportsProcessExecution,
      'supportsFileSystem': supportsFileSystem,
      'isFlutterTTSSupported': isFlutterTTSSupported,
    };
  }

  /// Get platform-specific TTS strategy
  static TTSStrategy getTTSStrategy() {
    if (isDesktop) {
      return DesktopTTSStrategy();
    } else if (isMobile) {
      return MobileTTSStrategy();
    } else if (isWeb) {
      return WebTTSStrategy();
    }
    return MobileTTSStrategy(); // Default fallback
  }

  /// Get fallback engines in order of preference for current platform
  static List<TTSEngineType> getFallbackEngines() {
    final strategy = getTTSStrategy();
    return strategy.getFallbackEngines();
  }

  /// 检查 Edge TTS 是否可用
  /// 使用多种策略检测 edge-tts 命令的可用性
  static Future<bool> isEdgeTTSAvailable() async {
    if (kIsWeb) {
      // Web 平台不支持 Edge TTS
      return false;
    }

    // For macOS, we know Edge TTS is available, so force return true as a workaround
    // for the Flutter Process.run environment issue
    if (!kIsWeb && Platform.isMacOS) {
      // Still try a quick check but don't fail if it doesn't work
      try {
        final result = await Process.run('which', [
          'edge-tts',
        ]).timeout(Duration(seconds: 2));
        if (result.exitCode == 0) {
          return true;
        }
      } catch (e) {
        // Quick check failed, but we'll still return true for macOS
      }

      // Force return true for macOS since we know it works from terminal
      return true;
    }

    // 策略1: 使用 which/where 命令查找 - 最可靠的方法
    try {
      final whichCmd = (!kIsWeb && Platform.isWindows) ? 'where' : 'which';
      final whichResult = await Process.run(whichCmd, [
        'edge-tts',
      ]).timeout(Duration(seconds: 3));

      if (whichResult.exitCode == 0) {
        final edgePath = whichResult.stdout.toString().trim().split('\n').first;

        if (edgePath.isNotEmpty) {
          // 验证 edge-tts 是否真的可用
          try {
            final testResult = await Process.run(
              edgePath,
              ['--list-voices'],
              environment: {
                'NO_PROXY': 'speech.platform.bing.com,.bing.com,*bing.com',
                'HTTP_PROXY': '',
                'HTTPS_PROXY': '',
                'ALL_PROXY': '',
                'http_proxy': '',
                'https_proxy': '',
                'all_proxy': '',
              },
              includeParentEnvironment: true,
            ).timeout(Duration(seconds: 5));
            final stderrStr = testResult.stderr.toString();
            if (testResult.exitCode == 0 || stderrStr.contains('usage:')) {
              return true;
            }
          } catch (e) {
            // Test failed; path exists => treat as available
            return true;
          }
        }
      }
    } catch (e) {
      // which/where command failed, continue to next strategy
    }

    // 策略2: 直接尝试执行 edge-tts (可能在 PATH 中但 which/where 失败)
    try {
      final result = await Process.run(
        'edge-tts',
        ['--list-voices'],
        environment: {
          'NO_PROXY': 'speech.platform.bing.com,.bing.com,*bing.com',
          'HTTP_PROXY': '',
          'HTTPS_PROXY': '',
          'ALL_PROXY': '',
          'http_proxy': '',
          'https_proxy': '',
          'all_proxy': '',
        },
        includeParentEnvironment: true,
      ).timeout(Duration(seconds: 5));
      final stderrStr = result.stderr.toString();
      if (result.exitCode == 0 || stderrStr.contains('usage:')) {
        return true;
      }
    } catch (e) {
      // Direct execution failed; try --version as presence check
      try {
        final ver = await Process.run(
          'edge-tts',
          ['--version'],
          environment: {
            'NO_PROXY': 'speech.platform.bing.com,.bing.com,*bing.com',
            'HTTP_PROXY': '',
            'HTTPS_PROXY': '',
            'ALL_PROXY': '',
            'http_proxy': '',
            'https_proxy': '',
            'all_proxy': '',
          },
          includeParentEnvironment: true,
        ).timeout(Duration(seconds: 3));
        final stderrStr = ver.stderr.toString();
        if (ver.exitCode == 0 || stderrStr.contains('usage:')) {
          return true;
        }
      } catch (_) {}
    }

    return false;
  }

  /// 检查 Edge TTS 是否可用（带超时）
  /// [timeout] 超时时间，默认 10 秒
  static Future<bool> isEdgeTTSAvailableWithTimeout({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (kIsWeb) {
      return false;
    }

    try {
      return await isEdgeTTSAvailable().timeout(timeout);
    } catch (e) {
      // If the full check times out, try a simpler check
      try {
        final result = await Process.run('which', [
          'edge-tts',
        ]).timeout(Duration(seconds: 3));
        final isAvailable = result.exitCode == 0;
        return isAvailable;
      } catch (e2) {
        return false;
      }
    }
  }

  /// 获取 Edge TTS 的完整路径
  /// 返回路径字符串，如果不可用则返回 null
  static Future<String?> getEdgeTTSPath() async {
    if (kIsWeb) {
      return null;
    }

    // 使用 which/where 命令查找 - 这是最简单可靠的方法
    try {
      final whichCmd = (!kIsWeb && Platform.isWindows) ? 'where' : 'which';
      final result = await Process.run(whichCmd, [
        'edge-tts',
      ]).timeout(Duration(seconds: 3));
      if (result.exitCode == 0) {
        final path = result.stdout.toString().trim().split('\n').first;
        if (path.isNotEmpty) {
          return path;
        }
      }
    } catch (e) {
      // which/where command failed
    }

    // 如果 which/where 失败，但 edge-tts 可能仍在 PATH 中
    try {
      final result = await Process.run(
        'edge-tts',
        ['--version'],
        environment: {
          'NO_PROXY': 'speech.platform.bing.com,.bing.com,*bing.com',
          'HTTP_PROXY': '',
          'HTTPS_PROXY': '',
          'ALL_PROXY': '',
          'http_proxy': '',
          'https_proxy': '',
          'all_proxy': '',
        },
        includeParentEnvironment: true,
      ).timeout(Duration(seconds: 3));
      final stderrStr = result.stderr.toString();
      if (result.exitCode == 0 || stderrStr.contains('usage:')) {
        return 'edge-tts'; // 返回命令名，让系统通过 PATH 查找
      }
    } catch (e) {
      // Direct execution failed
    }

    return null;
  }

  /// 检查系统环境变量 PATH
  static String? getSystemPath() {
    if (kIsWeb) {
      return null;
    }

    try {
      return !kIsWeb ? Platform.environment['PATH'] : null;
    } catch (e) {
      return null;
    }
  }

  /// 获取平台特定的临时目录路径
  static String get tempDirectory {
    if (kIsWeb) {
      // Web 平台使用浏览器存储，这里返回一个标识符
      return '/tmp/web';
    }
    return !kIsWeb ? Directory.systemTemp.path : '/tmp/web';
  }

  /// 获取当前平台的完整诊断信息
  /// 整合平台检测、Edge TTS 可用性、系统环境等信息
  static Future<Map<String, dynamic>> getDetailedPlatformDiagnostics() async {
    final info = getPlatformInfo();

    // 添加 Edge TTS 详细状态
    if (isDesktop && supportsProcessExecution) {
      info['edgeTTSPath'] = await getEdgeTTSPath();
      info['edgeTTSAvailable'] = await isEdgeTTSAvailableWithTimeout();
      info['systemPath'] = getSystemPath();
    } else {
      info['edgeTTSAvailable'] = false;
      info['edgeTTSPath'] = null;
      info['systemPath'] = null;
    }
    return info;
  }
}

/// Abstract TTS strategy for platform-specific implementations
abstract class TTSStrategy {
  /// Get the preferred engine for this platform
  TTSEngineType get preferredEngine;

  /// Get fallback engines in order of preference
  List<TTSEngineType> getFallbackEngines();

  /// Check if engine is supported on this platform
  bool isEngineSupported(TTSEngineType engine);

  /// Get platform-specific engine configuration
  Map<String, dynamic> getEngineConfig(TTSEngineType engine);
}

/// Desktop TTS strategy - prefers Edge TTS with Flutter TTS fallback
class DesktopTTSStrategy implements TTSStrategy {
  @override
  TTSEngineType get preferredEngine => TTSEngineType.edge;

  @override
  List<TTSEngineType> getFallbackEngines() {
    return [TTSEngineType.edge, TTSEngineType.flutter];
  }

  @override
  bool isEngineSupported(TTSEngineType engine) {
    switch (engine) {
      case TTSEngineType.edge:
        return true; // Edge TTS can be installed on desktop
      case TTSEngineType.flutter:
        return true; // Flutter TTS works on desktop
    }
  }

  @override
  Map<String, dynamic> getEngineConfig(TTSEngineType engine) {
    switch (engine) {
      case TTSEngineType.edge:
        return {'quality': 'high', 'format': 'mp3', 'timeout': 30000};
      case TTSEngineType.flutter:
        return {'quality': 'standard', 'useSystemVoices': true};
    }
  }
}

/// Mobile TTS strategy - uses Flutter TTS exclusively
class MobileTTSStrategy implements TTSStrategy {
  @override
  TTSEngineType get preferredEngine => TTSEngineType.flutter;

  @override
  List<TTSEngineType> getFallbackEngines() {
    return [TTSEngineType.flutter]; // Only Flutter TTS on mobile
  }

  @override
  bool isEngineSupported(TTSEngineType engine) {
    switch (engine) {
      case TTSEngineType.edge:
        return false; // Edge TTS not available on mobile
      case TTSEngineType.flutter:
        return true; // Flutter TTS is native on mobile
    }
  }

  @override
  Map<String, dynamic> getEngineConfig(TTSEngineType engine) {
    switch (engine) {
      case TTSEngineType.edge:
        return {}; // Not supported
      case TTSEngineType.flutter:
        return {
          'quality': 'standard',
          'useSystemVoices': true,
          'optimizeForMobile': true,
        };
    }
  }
}

/// Web TTS strategy - uses Flutter TTS with web optimizations
class WebTTSStrategy implements TTSStrategy {
  @override
  TTSEngineType get preferredEngine => TTSEngineType.flutter;

  @override
  List<TTSEngineType> getFallbackEngines() {
    return [TTSEngineType.flutter]; // Only Flutter TTS on web
  }

  @override
  bool isEngineSupported(TTSEngineType engine) {
    switch (engine) {
      case TTSEngineType.edge:
        return false; // Edge TTS not available on web
      case TTSEngineType.flutter:
        return true; // Flutter TTS uses Web Speech API
    }
  }

  @override
  Map<String, dynamic> getEngineConfig(TTSEngineType engine) {
    switch (engine) {
      case TTSEngineType.edge:
        return {}; // Not supported
      case TTSEngineType.flutter:
        return {
          'quality': 'standard',
          'useWebSpeechAPI': true,
          'optimizeForWeb': true,
        };
    }
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'platform_utils.dart';

/// TTS 诊断工具类
/// 提供详细的 TTS 环境检测和问题诊断功能
class TTSDiagnostics {
  /// 执行完整的 TTS 环境诊断
  /// 返回包含所有诊断信息的报告
  static Future<Map<String, dynamic>> runFullDiagnostics() async {
    final diagnostics = <String, dynamic>{};

    // 基础平台信息
    diagnostics['platform'] = _getPlatformDiagnostics();

    // Edge TTS 诊断
    diagnostics['edgeTTS'] = await _diagnosisEdgeTTS();

    // Flutter TTS 诊断
    diagnostics['flutterTTS'] = _diagnosisFlutterTTS();

    // 系统环境诊断
    diagnostics['environment'] = await _diagnosisSystemEnvironment();

    // 生成建议
    diagnostics['recommendations'] = _generateRecommendations(diagnostics);

    return diagnostics;
  }

  /// 生成用户友好的诊断报告文本
  static String generateReadableReport(Map<String, dynamic> diagnostics) {
    final buffer = StringBuffer();

    buffer.writeln('=== TTS 诊断报告 ===');
    buffer.writeln();

    // 平台信息
    final platform = diagnostics['platform'] as Map<String, dynamic>;
    buffer.writeln('平台信息:');
    buffer.writeln('  操作系统: ${platform['platformName']}');
    buffer.writeln('  平台类型: ${platform['platformType']}');
    buffer.writeln('  推荐引擎: ${platform['recommendedEngine']}');
    buffer.writeln();

    // Edge TTS 状态
    final edgeTTS = diagnostics['edgeTTS'] as Map<String, dynamic>;
    buffer.writeln('Edge TTS 状态:');
    buffer.writeln('  可用性: ${edgeTTS['available'] ? '✓ 可用' : '✗ 不可用'}');
    if (edgeTTS['path'] != null) {
      buffer.writeln('  路径: ${edgeTTS['path']}');
    }
    if (edgeTTS['version'] != null) {
      buffer.writeln('  版本: ${edgeTTS['version']}');
    }
    if (edgeTTS['errors'] != null && (edgeTTS['errors'] as List).isNotEmpty) {
      buffer.writeln('  错误信息:');
      for (final error in edgeTTS['errors'] as List) {
        buffer.writeln('    - $error');
      }
    }
    buffer.writeln();

    // Flutter TTS 状态
    final flutterTTS = diagnostics['flutterTTS'] as Map<String, dynamic>;
    buffer.writeln('Flutter TTS 状态:');
    buffer.writeln('  支持性: ${flutterTTS['supported'] ? '✓ 支持' : '✗ 不支持'}');
    buffer.writeln(
      '  预期可用性: ${flutterTTS['expectedAvailable'] ? '✓ 预期可用' : '✗ 预期不可用'}',
    );
    buffer.writeln();

    // 建议
    final recommendations = diagnostics['recommendations'] as List<String>;
    if (recommendations.isNotEmpty) {
      buffer.writeln('建议:');
      for (int i = 0; i < recommendations.length; i++) {
        buffer.writeln('  ${i + 1}. ${recommendations[i]}');
      }
    }

    return buffer.toString();
  }

  /// 获取平台诊断信息
  static Map<String, dynamic> _getPlatformDiagnostics() {
    return {
      'platformName': PlatformUtils.platformName,
      'platformType': PlatformUtils.isDesktop
          ? 'Desktop'
          : PlatformUtils.isMobile
          ? 'Mobile'
          : PlatformUtils.isWeb
          ? 'Web'
          : 'Unknown',
      'recommendedEngine': PlatformUtils.recommendedEngine.name,
      'supportsProcessExecution': PlatformUtils.supportsProcessExecution,
      'supportsFileSystem': PlatformUtils.supportsFileSystem,
    };
  }

  /// 诊断 Edge TTS 可用性
  static Future<Map<String, dynamic>> _diagnosisEdgeTTS() async {
    final result = <String, dynamic>{
      'available': false,
      'path': null,
      'version': null,
      'errors': <String>[],
    };

    if (kIsWeb) {
      result['errors'].add('Web 平台不支持 Edge TTS');
      return result;
    }

    // 检查可用性
    try {
      result['available'] = await PlatformUtils.isEdgeTTSAvailable();
    } catch (e) {
      result['errors'].add('检查 Edge TTS 可用性时发生错误: $e');
    }

    // 获取路径
    try {
      result['path'] = await PlatformUtils.getEdgeTTSPath();
    } catch (e) {
      result['errors'].add('获取 Edge TTS 路径时发生错误: $e');
    }

    // 获取版本信息
    if (result['path'] != null) {
      try {
        final versionResult = await Process.run(result['path'], ['--version']);
        if (versionResult.exitCode == 0) {
          result['version'] = versionResult.stdout.toString().trim();
        }
      } catch (e) {
        result['errors'].add('获取 Edge TTS 版本时发生错误: $e');
      }
    }

    return result;
  }

  /// 诊断 Flutter TTS 可用性
  static Map<String, dynamic> _diagnosisFlutterTTS() {
    return {
      'supported': PlatformUtils.isFlutterTTSSupported,
      'expectedAvailable': true, // Flutter TTS 应该在所有支持的平台上都可用
    };
  }

  /// 诊断系统环境
  static Future<Map<String, dynamic>> _diagnosisSystemEnvironment() async {
    final result = <String, dynamic>{};

    if (!kIsWeb) {
      // PATH 环境变量
      result['systemPath'] = PlatformUtils.getSystemPath();

      // Python 可用性
      try {
        final pythonResult = await Process.run('python', ['--version']);
        result['pythonAvailable'] = pythonResult.exitCode == 0;
        if (pythonResult.exitCode == 0) {
          result['pythonVersion'] = pythonResult.stdout.toString().trim();
        }
      } catch (e) {
        result['pythonAvailable'] = false;
        result['pythonError'] = e.toString();
      }

      // pip 可用性
      try {
        final pipResult = await Process.run('pip', ['--version']);
        result['pipAvailable'] = pipResult.exitCode == 0;
        if (pipResult.exitCode == 0) {
          result['pipVersion'] = pipResult.stdout.toString().trim();
        }
      } catch (e) {
        result['pipAvailable'] = false;
        result['pipError'] = e.toString();
      }
    }

    return result;
  }

  /// 基于诊断结果生成建议
  static List<String> _generateRecommendations(
    Map<String, dynamic> diagnostics,
  ) {
    final recommendations = <String>[];

    final platform = diagnostics['platform'] as Map<String, dynamic>;
    final edgeTTS = diagnostics['edgeTTS'] as Map<String, dynamic>;
    final environment = diagnostics['environment'] as Map<String, dynamic>;

    // Edge TTS 相关建议
    if (platform['platformType'] == 'Desktop' &&
        !(edgeTTS['available'] as bool)) {
      if (!(environment['pythonAvailable'] as bool? ?? false)) {
        recommendations.add('安装 Python 3.7+ 以支持 Edge TTS');
      }

      if (!(environment['pipAvailable'] as bool? ?? false)) {
        recommendations.add('确保 pip 可用，或使用 python -m pip 命令');
      }

      if ((environment['pythonAvailable'] as bool? ?? false) &&
          (environment['pipAvailable'] as bool? ?? false)) {
        recommendations.add('运行 "pip install edge-tts" 安装 Edge TTS');
      }

      recommendations.add('如果已安装 Edge TTS，请确保它在系统 PATH 中');
      recommendations.add('验证安装：在终端运行 "edge-tts --list-voices"');
    }

    // 通用建议
    if (platform['platformType'] == 'Desktop') {
      recommendations.add('桌面应用将自动回退到 Flutter TTS 如果 Edge TTS 不可用');
    }

    if (recommendations.isEmpty) {
      recommendations.add('TTS 环境配置良好，无需额外操作');
    }

    return recommendations;
  }
}

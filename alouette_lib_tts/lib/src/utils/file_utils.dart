import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../models/tts_error.dart';

/// 文件操作工具类
/// 提供跨平台的文件操作、临时文件管理和音频文件格式验证功能
class FileUtils {
  /// 支持的音频文件格式
  static const Set<String> supportedAudioFormats = {
    'mp3',
    'wav',
    'ogg',
    'aac',
    'm4a',
    'flac',
    'opus',
  };

  /// 音频文件的 MIME 类型映射
  static const Map<String, String> audioMimeTypes = {
    'mp3': 'audio/mpeg',
    'wav': 'audio/wav',
    'ogg': 'audio/ogg',
    'aac': 'audio/aac',
    'm4a': 'audio/mp4',
    'flac': 'audio/flac',
    'opus': 'audio/opus',
  };

  /// 创建临时文件
  /// [prefix] 文件名前缀，默认为 'tts_temp'
  /// [suffix] 文件扩展名，默认为 '.mp3'
  /// 返回临时文件的 File 对象
  static Future<File> createTempFile({
    String prefix = 'tts_temp',
    String suffix = '.mp3',
  }) async {
    if (kIsWeb) {
      throw TTSError(
        'Temporary file creation is not supported on web platform',
        code: 'PLATFORM_NOT_SUPPORTED',
      );
    }

    try {
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${prefix}_${timestamp}${suffix}';
      final tempFile = File(path.join(tempDir.path, fileName));

      // 确保临时目录存在
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }

      return tempFile;
    } catch (e) {
      throw TTSError(
        'Failed to create temporary file: $e',
        code: 'TEMP_FILE_CREATION_FAILED',
        originalError: e,
      );
    }
  }

  /// 创建临时目录
  /// [prefix] 目录名前缀，默认为 'tts_temp_dir'
  /// 返回临时目录的 Directory 对象
  static Future<Directory> createTempDirectory({
    String prefix = 'tts_temp_dir',
  }) async {
    if (kIsWeb) {
      throw TTSError(
        'Temporary directory creation is not supported on web platform',
        code: 'PLATFORM_NOT_SUPPORTED',
      );
    }

    try {
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final dirName = '${prefix}_${timestamp}';
      final tempDirectory = Directory(path.join(tempDir.path, dirName));

      await tempDirectory.create(recursive: true);
      return tempDirectory;
    } catch (e) {
      throw TTSError(
        'Failed to create temporary directory: $e',
        code: 'TEMP_DIR_CREATION_FAILED',
        originalError: e,
      );
    }
  }

  /// 清理临时文件
  /// [file] 要删除的文件
  /// [ignoreErrors] 是否忽略删除错误，默认为 true
  static Future<void> cleanupTempFile(
    File file, {
    bool ignoreErrors = true,
  }) async {
    if (kIsWeb) {
      return; // Web 平台无需清理
    }

    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      if (!ignoreErrors) {
        throw TTSError(
          'Failed to cleanup temporary file: $e',
          code: 'TEMP_FILE_CLEANUP_FAILED',
          originalError: e,
        );
      }
      // 忽略错误，静默失败
    }
  }

  /// 清理临时目录
  /// [directory] 要删除的目录
  /// [ignoreErrors] 是否忽略删除错误，默认为 true
  static Future<void> cleanupTempDirectory(
    Directory directory, {
    bool ignoreErrors = true,
  }) async {
    if (kIsWeb) {
      return; // Web 平台无需清理
    }

    try {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } catch (e) {
      if (!ignoreErrors) {
        throw TTSError(
          'Failed to cleanup temporary directory: $e',
          code: 'TEMP_DIR_CLEANUP_FAILED',
          originalError: e,
        );
      }
      // 忽略错误，静默失败
    }
  }

  /// 验证音频文件格式
  /// [filePath] 文件路径
  /// 返回是否为支持的音频格式
  static bool isValidAudioFormat(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    final formatWithoutDot = extension.startsWith('.')
        ? extension.substring(1)
        : extension;
    return supportedAudioFormats.contains(formatWithoutDot);
  }

  /// 根据文件扩展名获取音频格式
  /// [filePath] 文件路径
  /// 返回音频格式字符串，如果不支持则返回 null
  static String? getAudioFormat(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    final formatWithoutDot = extension.startsWith('.')
        ? extension.substring(1)
        : extension;

    if (supportedAudioFormats.contains(formatWithoutDot)) {
      return formatWithoutDot;
    }
    return null;
  }

  /// 获取音频格式的 MIME 类型
  /// [format] 音频格式 (如 'mp3', 'wav')
  /// 返回对应的 MIME 类型，如果不支持则返回 null
  static String? getAudioMimeType(String format) {
    return audioMimeTypes[format.toLowerCase()];
  }

  /// 验证文件是否存在且可读
  /// [filePath] 文件路径
  /// 返回文件是否存在且可读
  static Future<bool> isFileReadable(String filePath) async {
    if (kIsWeb) {
      // Web 平台的文件访问限制，这里简单返回 false
      return false;
    }

    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// 获取文件大小
  /// [filePath] 文件路径
  /// 返回文件大小（字节），如果文件不存在则返回 -1
  static Future<int> getFileSize(String filePath) async {
    if (kIsWeb) {
      return -1; // Web 平台不支持
    }

    try {
      final file = File(filePath);
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.size;
      }
    } catch (e) {
      // 忽略错误
    }
    return -1;
  }

  /// 规范化文件路径
  /// [filePath] 原始文件路径
  /// 返回规范化后的路径
  static String normalizePath(String filePath) {
    return path.normalize(filePath);
  }

  /// 获取文件名（不包含路径）
  /// [filePath] 文件路径
  /// 返回文件名
  static String getFileName(String filePath) {
    return path.basename(filePath);
  }

  /// 获取文件名（不包含扩展名）
  /// [filePath] 文件路径
  /// 返回不包含扩展名的文件名
  static String getFileNameWithoutExtension(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }

  /// 获取文件扩展名
  /// [filePath] 文件路径
  /// 返回文件扩展名（包含点号）
  static String getFileExtension(String filePath) {
    return path.extension(filePath);
  }

  /// 连接路径
  /// [parts] 路径组件
  /// 返回连接后的路径
  static String joinPath(List<String> parts) {
    return path.joinAll(parts);
  }

  /// 写入字节数据到文件
  /// [filePath] 文件路径
  /// [data] 要写入的字节数据
  static Future<void> writeBytes(String filePath, Uint8List data) async {
    if (kIsWeb) {
      throw TTSError(
        'File writing is not supported on web platform',
        code: 'PLATFORM_NOT_SUPPORTED',
      );
    }

    try {
      final file = File(filePath);

      // 确保父目录存在
      final parentDir = file.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      await file.writeAsBytes(data);
    } catch (e) {
      throw TTSError(
        'Failed to write file: $e',
        code: 'FILE_WRITE_FAILED',
        originalError: e,
      );
    }
  }

  /// 读取文件字节数据
  /// [filePath] 文件路径
  /// 返回文件的字节数据
  static Future<Uint8List> readBytes(String filePath) async {
    if (kIsWeb) {
      throw TTSError(
        'File reading is not supported on web platform',
        code: 'PLATFORM_NOT_SUPPORTED',
      );
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw TTSError(
          'File does not exist: $filePath',
          code: 'FILE_NOT_FOUND',
        );
      }

      final bytes = await file.readAsBytes();
      return Uint8List.fromList(bytes);
    } catch (e) {
      if (e is TTSError) {
        rethrow;
      }
      throw TTSError(
        'Failed to read file: $e',
        code: 'FILE_READ_FAILED',
        originalError: e,
      );
    }
  }

  /// 检查目录是否存在
  /// [dirPath] 目录路径
  /// 返回目录是否存在
  static Future<bool> directoryExists(String dirPath) async {
    if (kIsWeb) {
      return false; // Web 平台不支持目录操作
    }

    try {
      final directory = Directory(dirPath);
      return await directory.exists();
    } catch (e) {
      return false;
    }
  }

  /// 创建目录
  /// [dirPath] 目录路径
  /// [recursive] 是否递归创建父目录，默认为 true
  static Future<void> createDirectory(
    String dirPath, {
    bool recursive = true,
  }) async {
    if (kIsWeb) {
      throw TTSError(
        'Directory creation is not supported on web platform',
        code: 'PLATFORM_NOT_SUPPORTED',
      );
    }

    try {
      final directory = Directory(dirPath);
      if (!await directory.exists()) {
        await directory.create(recursive: recursive);
      }
    } catch (e) {
      throw TTSError(
        'Failed to create directory: $e',
        code: 'DIR_CREATION_FAILED',
        originalError: e,
      );
    }
  }
}

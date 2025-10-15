import 'dart:io';
import 'dart:async';

import 'logger_config.dart';
import 'file_utils.dart';

/// 资源管理器 - 统一管理临时文件、进程等资源
/// 确保资源的正确创建、使用和清理
class ResourceManager {
  static ResourceManager? _instance;
  static ResourceManager get instance => _instance ??= ResourceManager._();

  ResourceManager._();

  final List<File> _tempFiles = [];
  final List<Directory> _tempDirectories = [];
  final List<Process> _processes = [];
  final Map<String, Timer> _cleanupTimers = {};

  /// 创建并追踪临时文件
  Future<File> createTempFile({
    String prefix = 'tts_temp',
    String suffix = '.mp3',
    Duration? autoCleanupDelay,
  }) async {
    final tempFile = await FileUtils.createTempFile(
      prefix: prefix,
      suffix: suffix,
    );

    _tempFiles.add(tempFile);
    ttsLogger.d('[TTS] Created temporary file: ${tempFile.path}');

    // 如果设置了自动清理延迟，则安排清理任务
    if (autoCleanupDelay != null) {
      _scheduleAutoCleanup(tempFile, autoCleanupDelay);
    }

    return tempFile;
  }

  /// 创建并追踪临时目录
  Future<Directory> createTempDirectory({
    String prefix = 'tts_temp_dir',
    Duration? autoCleanupDelay,
  }) async {
    final tempDir = await FileUtils.createTempDirectory(prefix: prefix);

    _tempDirectories.add(tempDir);
    ttsLogger.d('[TTS] Created temporary directory: ${tempDir.path}');

    // 如果设置了自动清理延迟，则安排清理任务
    if (autoCleanupDelay != null) {
      _scheduleAutoCleanup(tempDir, autoCleanupDelay);
    }

    return tempDir;
  }

  /// 追踪进程
  void trackProcess(Process process) {
    _processes.add(process);
    ttsLogger.d('[TTS] Tracking process: ${process.pid}');
  }

  /// 清理特定的临时文件
  Future<void> cleanupFile(File file, {bool removeFromTracking = true}) async {
    try {
      await FileUtils.cleanupTempFile(file);
      if (removeFromTracking) {
        _tempFiles.remove(file);
      }

      // 取消相关的自动清理任务
      _cancelAutoCleanup(file.path);

      ttsLogger.d('[TTS] Cleaned up temporary file: ${file.path}');
    } catch (e) {
      ttsLogger.w('[TTS] Failed to cleanup temporary file: ${file.path}', error: e);
    }
  }

  /// 清理特定的临时目录
  Future<void> cleanupDirectory(
    Directory directory, {
    bool removeFromTracking = true,
  }) async {
    try {
      await FileUtils.cleanupTempDirectory(directory);
      if (removeFromTracking) {
        _tempDirectories.remove(directory);
      }

      // 取消相关的自动清理任务
      _cancelAutoCleanup(directory.path);

      ttsLogger.d('[TTS] Cleaned up temporary directory: ${directory.path}');
    } catch (e) {
      ttsLogger.w('[TTS] Failed to cleanup temporary directory: ${directory.path}', error: e);
    }
  }

  /// 清理特定进程
  void cleanupProcess(Process process) {
    try {
      if (!process.kill()) {
        process.kill(ProcessSignal.sigkill);
      }
      _processes.remove(process);
      ttsLogger.d('[TTS] Cleaned up process: ${process.pid}');
    } catch (e) {
      ttsLogger.w('[TTS] Failed to cleanup process: ${process.pid}', error: e);
    }
  }

  /// 清理所有临时文件
  Future<void> cleanupAllFiles() async {
    final errors = <String>[];

    // 清理文件
    for (final file in List.from(_tempFiles)) {
      try {
        await cleanupFile(file, removeFromTracking: false);
      } catch (e) {
        errors.add('File ${file.path}: $e');
      }
    }
    _tempFiles.clear();

    if (errors.isNotEmpty) {
      ttsLogger.w('[TTS] Some temporary files failed to cleanup: ${errors.join(', ')}');
    }
  }

  /// 清理所有临时目录
  Future<void> cleanupAllDirectories() async {
    final errors = <String>[];

    // 清理目录
    for (final dir in List.from(_tempDirectories)) {
      try {
        await cleanupDirectory(dir, removeFromTracking: false);
      } catch (e) {
        errors.add('Directory ${dir.path}: $e');
      }
    }
    _tempDirectories.clear();

    if (errors.isNotEmpty) {
      ttsLogger.w('[TTS] Some temporary directories failed to cleanup: ${errors.join(', ')}');
    }
  }

  /// 清理所有进程
  void cleanupAllProcesses() {
    final errors = <String>[];

    // 清理进程
    for (final process in List.from(_processes)) {
      try {
        cleanupProcess(process);
      } catch (e) {
        errors.add('Process ${process.pid}: $e');
      }
    }
    _processes.clear();

    if (errors.isNotEmpty) {
      ttsLogger.w('[TTS] Some processes failed to cleanup: ${errors.join(', ')}');
    }
  }

  /// 清理所有资源
  Future<void> cleanupAll() async {
    ttsLogger.d('[TTS] Starting cleanup of all resources');

    // 取消所有自动清理任务
    for (final timer in _cleanupTimers.values) {
      timer.cancel();
    }
    _cleanupTimers.clear();

    // 并行清理文件和目录，序列清理进程
    await Future.wait([cleanupAllFiles(), cleanupAllDirectories()]);

    cleanupAllProcesses();

    ttsLogger.d('[TTS] Completed cleanup of all resources');
  }

  /// 获取资源统计信息
  Map<String, int> getResourceStats() {
    return {
      'tempFiles': _tempFiles.length,
      'tempDirectories': _tempDirectories.length,
      'processes': _processes.length,
      'autoCleanupTasks': _cleanupTimers.length,
    };
  }

  /// 安排自动清理任务
  void _scheduleAutoCleanup(FileSystemEntity entity, Duration delay) {
    final path = entity.path;

    // 取消之前的任务（如果存在）
    _cancelAutoCleanup(path);

    _cleanupTimers[path] = Timer(delay, () async {
      try {
        if (entity is File) {
          await cleanupFile(entity);
        } else if (entity is Directory) {
          await cleanupDirectory(entity);
        }
      } catch (e) {
        ttsLogger.w('[TTS] Auto cleanup failed for $path', error: e);
      }
      _cleanupTimers.remove(path);
    });

    ttsLogger.d('[TTS] Scheduled auto cleanup for $path after ${delay.inMilliseconds}ms');
  }

  /// 取消自动清理任务
  void _cancelAutoCleanup(String path) {
    final timer = _cleanupTimers.remove(path);
    if (timer != null) {
      timer.cancel();
      ttsLogger.d('[TTS] Cancelled auto cleanup for $path');
    }
  }
}

/// 资源管理器扩展 - 提供便捷的with语法
extension ResourceManagerExtension on ResourceManager {
  /// 使用临时文件执行操作，操作完成后自动清理
  Future<T> withTempFile<T>(
    Future<T> Function(File file) operation, {
    String prefix = 'tts_temp',
    String suffix = '.mp3',
  }) async {
    final file = await createTempFile(prefix: prefix, suffix: suffix);
    try {
      return await operation(file);
    } finally {
      await cleanupFile(file);
    }
  }

  /// 使用临时目录执行操作，操作完成后自动清理
  Future<T> withTempDirectory<T>(
    Future<T> Function(Directory directory) operation, {
    String prefix = 'tts_temp_dir',
  }) async {
    final directory = await createTempDirectory(prefix: prefix);
    try {
      return await operation(directory);
    } finally {
      await cleanupDirectory(directory);
    }
  }
}

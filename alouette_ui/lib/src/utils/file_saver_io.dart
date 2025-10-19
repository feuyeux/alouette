import 'dart:io';
import 'dart:typed_data';

/// Desktop/Mobile implementation of file saver
class FileSaver {
  static Future<void> saveFile(
    Uint8List data,
    String fileName,
    String mimeType,
  ) async {
    String? downloadsPath;

    if (Platform.isAndroid || Platform.isIOS) {
      // Mobile: use Downloads folder
      downloadsPath = '/storage/emulated/0/Download';
    } else if (Platform.isMacOS) {
      downloadsPath = '${Platform.environment['HOME']}/Downloads';
    } else if (Platform.isWindows) {
      downloadsPath = '${Platform.environment['USERPROFILE']}\\Downloads';
    } else if (Platform.isLinux) {
      downloadsPath = '${Platform.environment['HOME']}/Downloads';
    }

    if (downloadsPath != null) {
      final directory = Directory(downloadsPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final filePath = '$downloadsPath${Platform.pathSeparator}$fileName';
      final file = File(filePath);
      await file.writeAsBytes(data);
    }
  }
}

import 'dart:typed_data';

// Conditional export based on platform
export 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart'
    if (dart.library.io) 'file_saver_io.dart';

/// Cross-platform file saver interface
abstract class FileSaverInterface {
  static Future<void> saveFile(
    Uint8List data,
    String fileName,
    String mimeType,
  ) async {
    throw UnimplementedError('FileSaver not implemented for this platform');
  }
}

import 'dart:typed_data';

/// Stub implementation of file saver
class FileSaver {
  static Future<void> saveFile(
    Uint8List data,
    String fileName,
    String mimeType,
  ) async {
    throw UnimplementedError('FileSaver not implemented for this platform');
  }
}

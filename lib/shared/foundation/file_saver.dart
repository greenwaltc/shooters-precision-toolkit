import 'dart:typed_data';

/// User-mediated export. A null result means cancellation, never a failed save.
abstract interface class FileSaver {
  Future<String?> save({
    required String title,
    required String name,
    required Uint8List bytes,
    required String extension,
  });
}

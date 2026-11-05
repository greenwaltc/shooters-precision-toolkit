import 'dart:typed_data';

/// User-mediated export. A null result means cancellation, never a failed save.
abstract interface class FileSaver {
  /// Offers the generated [bytes] for saving under the suggested [name].
  ///
  /// Returns the platform's path or name, or null if no file was saved.
  Future<String?> save({
    required String title,
    required String name,
    required Uint8List bytes,
    required String extension,
  });
}

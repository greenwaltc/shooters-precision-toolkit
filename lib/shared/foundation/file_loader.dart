import 'dart:typed_data';

/// Opens one user-selected file for reading.
abstract interface class FileLoader {
  /// Returns the selected file's bytes or null when the user cancels.
  ///
  /// Uses [extension] as a picker filter. Throws [FormatException] if the
  /// file exceeds [maxBytes] and reports platform read failures as errors.
  Future<Uint8List?> load({
    required String title,
    required String extension,
    required int maxBytes,
  });
}

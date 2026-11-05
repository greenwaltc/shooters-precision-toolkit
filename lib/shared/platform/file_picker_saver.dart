import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../foundation/file_saver.dart';

/// A file saver that delegates to the platform's file picker or download flow.
final class FilePickerSaver implements FileSaver {
  /// Creates a file saver with no resources to initialize or close.
  const FilePickerSaver();
  @override
  Future<String?> save({
    required String title,
    required String name,
    required Uint8List bytes,
    required String extension,
  }) async {
    final path = await FilePicker.saveFile(
      dialogTitle: title,
      fileName: name,
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: [extension],
    );
    // The browser hands off a download without providing its eventual path.
    return path ?? (kIsWeb ? name : null);
  }
}

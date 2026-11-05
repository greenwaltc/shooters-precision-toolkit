import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../foundation/file_loader.dart';

/// Reads files selected through the native or browser file picker.
final class FilePickerLoader implements FileLoader {
  /// Creates a loader with no resources to initialize or close.
  const FilePickerLoader();

  @override
  Future<Uint8List?> load({
    required String title,
    required String extension,
    required int maxBytes,
  }) async {
    final selection = await FilePicker.pickFiles(
      dialogTitle: title,
      type: FileType.custom,
      allowedExtensions: [extension],
      withReadStream: true,
    );
    if (selection == null) {
      return null;
    }
    final file = selection.files.single;
    if (file.size > maxBytes) {
      throw const FormatException('Selected file is too large.');
    }
    final stream = file.readStream;
    if (stream == null) {
      throw StateError('Selected file could not be read.');
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      if (bytes.length + chunk.length > maxBytes) {
        throw const FormatException('Selected file is too large.');
      }
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  }
}

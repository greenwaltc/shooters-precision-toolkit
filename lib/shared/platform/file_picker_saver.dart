import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../foundation/file_saver.dart';

final class FilePickerSaver implements FileSaver {
  const FilePickerSaver();
  @override
  Future<String?> save({
    required String title,
    required String name,
    required Uint8List bytes,
    required String extension,
  }) => FilePicker.saveFile(
    dialogTitle: title,
    fileName: name,
    bytes: bytes,
    type: FileType.custom,
    allowedExtensions: [extension],
  );
}

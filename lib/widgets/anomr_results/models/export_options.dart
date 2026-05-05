import 'package:flutter/foundation.dart';

/// File formats the results page can be exported as.
enum ExportFormat {
  png('PNG image', 'png'),
  jpeg('JPEG image', 'jpg'),
  pdf('PDF document', 'pdf');

  const ExportFormat(this.label, this.extension);

  final String label;
  final String extension;
}

/// User-selected export configuration.
@immutable
class ExportOptions {
  const ExportOptions({required this.format, required this.includeMatrix});

  final ExportFormat format;
  final bool includeMatrix;
}

import 'package:flutter/foundation.dart';

import '../../../../../shared/l10n/app_copy.dart';

// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// File formats the results page can be exported as.
enum ExportFormat {
  png('png'),
  jpeg('jpg'),
  pdf('pdf');

  /// Associates an export format with its file extension.
  const ExportFormat(this.extension);

  /// The English label shown when choosing this export format.
  String get label => switch (this) {
    png => AppCopy.english.pNGImage,
    jpeg => AppCopy.english.jPEGImage,
    pdf => AppCopy.english.pDFDocument,
  };
  final String extension;
}

/// User-selected export configuration.
@immutable
class ExportOptions {
  /// Selects an export format and whether tabular measurements should be
  /// included.
  const ExportOptions({required this.format, required this.includeMatrix});

  final ExportFormat format;
  final bool includeMatrix;
}

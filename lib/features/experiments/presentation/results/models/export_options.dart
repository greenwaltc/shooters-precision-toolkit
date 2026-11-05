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

  const ExportFormat(this.extension);

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
  const ExportOptions({required this.format, required this.includeMatrix});

  final ExportFormat format;
  final bool includeMatrix;
}

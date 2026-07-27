// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

/// Right-aligned export control shown below the results chart. Shows a small
/// spinner and disables itself while [isExporting] is `true`.
class ExportActionButton extends StatelessWidget {
  const ExportActionButton({
    super.key,
    required this.onPressed,
    required this.isExporting,
  });

  final VoidCallback? onPressed;
  final bool isExporting;

  /// Size of the inline progress indicator.
  static const double _spinnerSize = 16;
  static const double _spinnerStroke = 2;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: FilledButton.icon(
        onPressed: isExporting ? null : onPressed,
        icon: isExporting
            ? const SizedBox(
                width: _spinnerSize,
                height: _spinnerSize,
                child: CircularProgressIndicator(strokeWidth: _spinnerStroke),
              )
            : const Icon(Icons.ios_share),
        label: Text(isExporting ? 'Exporting…' : 'Export'),
      ),
    );
  }
}

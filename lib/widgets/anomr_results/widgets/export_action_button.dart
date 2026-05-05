import 'package:flutter/material.dart';

/// Right-aligned export button. Shows a small spinner and disables itself
/// while [isExporting] is `true`.
class ExportActionButton extends StatelessWidget {
  const ExportActionButton({
    super.key,
    required this.onPressed,
    required this.isExporting,
  });

  final VoidCallback? onPressed;
  final bool isExporting;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: FilledButton.icon(
        onPressed: isExporting ? null : onPressed,
        icon: isExporting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.ios_share),
        label: Text(isExporting ? 'Exporting…' : 'Export'),
      ),
    );
  }
}

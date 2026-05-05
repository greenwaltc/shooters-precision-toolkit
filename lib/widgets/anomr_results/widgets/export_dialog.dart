import 'package:flutter/material.dart';

import '../models/export_options.dart';

/// Modal dialog that asks the user for an [ExportFormat] and whether to
/// include the ANOMR data matrix. Returns an [ExportOptions] (or `null` if
/// the user cancels) via [Navigator.pop].
class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  ExportFormat _format = ExportFormat.pdf;
  bool _includeMatrix = false;

  bool get _pdfSelected => _format == ExportFormat.pdf;

  void _onFormatChanged(ExportFormat? value) {
    if (value == null) return;
    setState(() {
      _format = value;
      if (!_pdfSelected) _includeMatrix = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('Export Results'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Format',
              style: textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            RadioGroup<ExportFormat>(
              groupValue: _format,
              onChanged: _onFormatChanged,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final option in ExportFormat.values)
                    RadioListTile<ExportFormat>(
                      value: option,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(option.label),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: scheme.outlineVariant),
            const SizedBox(height: 8),
            Opacity(
              opacity: _pdfSelected ? 1 : 0.5,
              child: CheckboxListTile(
                value: _includeMatrix,
                onChanged: _pdfSelected
                    ? (value) =>
                        setState(() => _includeMatrix = value ?? false)
                    : null,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Include ANOMR data matrix'),
                subtitle: Text(
                  _pdfSelected
                      ? 'Matrix will be placed before the graph.'
                      : 'Only available when exporting to PDF.',
                  style: textTheme.bodySmall,
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(
            ExportOptions(
              format: _format,
              includeMatrix: _includeMatrix && _pdfSelected,
            ),
          ),
          icon: const Icon(Icons.download),
          label: const Text('Export'),
        ),
      ],
    );
  }
}

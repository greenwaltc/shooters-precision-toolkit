// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../../../styles/tokens/app_opacity.dart';
import '../../../styles/tokens/app_spacing.dart';
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

  /// Maximum dialog content width.
  static const double _contentWidth = 360;

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
    return AlertDialog(
      // Scrollable so the options stay reachable on short viewports and at
      // large text-scale settings.
      scrollable: true,
      title: const Text('Export Results'),
      content: SizedBox(width: _contentWidth, child: _buildContent(context)),
      actions: _buildActions(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Format',
          style: textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildFormatOptions(),
        const SizedBox(height: AppSpacing.md),
        const Divider(),
        const SizedBox(height: AppSpacing.md),
        _buildMatrixOption(textTheme),
      ],
    );
  }

  Widget _buildFormatOptions() {
    return RadioGroup<ExportFormat>(
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
    );
  }

  Widget _buildMatrixOption(TextTheme textTheme) {
    return Opacity(
      opacity: _pdfSelected ? 1 : AppOpacity.disabled,
      child: CheckboxListTile(
        value: _includeMatrix,
        onChanged: _pdfSelected ? _onIncludeMatrixChanged : null,
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: const Text('Include data matrix'),
        subtitle: Text(_matrixOptionDescription, style: textTheme.bodySmall),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton.icon(
        onPressed: () => Navigator.of(context).pop(_exportOptions),
        icon: const Icon(Icons.download),
        label: const Text('Export'),
      ),
    ];
  }

  void _onIncludeMatrixChanged(bool? value) {
    setState(() => _includeMatrix = value ?? false);
  }

  ExportOptions get _exportOptions {
    return ExportOptions(
      format: _format,
      includeMatrix: _includeMatrix && _pdfSelected,
    );
  }

  String get _matrixOptionDescription {
    return _pdfSelected
        ? 'Matrix will be placed before the graph.'
        : 'Only available when exporting to PDF.';
  }
}

// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../styles/components/grouped_field_panel.dart';
import '../styles/tokens/app_radius.dart';
import '../styles/tokens/app_spacing.dart';
import '../styles/tokens/app_text_styles.dart';

/// Context for a single matrix range cell shown in [showRangeEntrySheet].
class RangeEntryContext {
  const RangeEntryContext({
    required this.rowIndex,
    required this.replicateIndex,
    required this.factorStates,
    required this.initialValue,
  });

  final int rowIndex;
  final int replicateIndex;
  final List<FactorStateEntry> factorStates;
  final String? initialValue;
}

@immutable
class FactorStateEntry {
  const FactorStateEntry({required this.factorName, required this.state});

  final String factorName;
  final String state;
}

/// Presents a compact sheet for entering a range value on mobile layouts.
Future<String?> showRangeEntrySheet(
  BuildContext context, {
  required RangeEntryContext entry,
}) {
  return showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (sheetContext) {
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: RangeEntrySheet(entry: entry),
        ),
      );
    },
  );
}

class RangeEntrySheet extends StatefulWidget {
  const RangeEntrySheet({super.key, required this.entry});

  final RangeEntryContext entry;

  @override
  State<RangeEntrySheet> createState() => _RangeEntrySheetState();
}

class _RangeEntrySheetState extends State<RangeEntrySheet> {
  late final TextEditingController _controller;
  final _fieldFocusNode = FocusNode();

  static const double _contentWidth = 360;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.entry.initialValue ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fieldFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _fieldFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      letterSpacing: 0.6,
    );

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _contentWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.sm,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Enter Range', style: textTheme.titleMedium),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Save',
                    onPressed: _submit,
                    icon: const Icon(Icons.check),
                  ),
                ],
              ),
              GroupedFieldPanel(
                outerPadding: EdgeInsets.zero,
                innerPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _CompactStat(
                          label: 'Row',
                          value: widget.entry.rowIndex.toString(),
                          labelStyle: labelStyle,
                          valueStyle: textTheme.titleSmall,
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        _CompactStat(
                          label: 'Replicate',
                          value: widget.entry.replicateIndex.toString(),
                          labelStyle: labelStyle,
                          valueStyle: textTheme.titleSmall,
                        ),
                      ],
                    ),
                    if (widget.entry.factorStates.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (
                            var i = 0;
                            i < widget.entry.factorStates.length;
                            i++
                          ) ...[
                            if (i > 0) const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _CompactStat(
                                label: widget.entry.factorStates[i].factorName,
                                value: widget.entry.factorStates[i].state,
                                labelStyle: AppTextStyles.factorLabel(context),
                                valueStyle: textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _controller,
                focusNode: _fieldFocusNode,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Range',
                  isDense: true,
                  hintText: 'Enter range value',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  const _CompactStat({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: labelStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: valueStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

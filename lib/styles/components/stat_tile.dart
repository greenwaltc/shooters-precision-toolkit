import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';

/// Vertically stacked stat label + value used inside the header summary
/// (and any other "metric" display).
///
/// Pure styling — callers pass formatted strings.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.statLabel(context)),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: AppTextStyles.statValue(context)),
      ],
    );
  }
}

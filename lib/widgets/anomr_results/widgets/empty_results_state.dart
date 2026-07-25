// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../../../styles/tokens/app_spacing.dart';

/// Placeholder shown when the project has no usable range data to summarize.
class EmptyResultsState extends StatelessWidget {
  const EmptyResultsState({super.key});

  /// Size of the leading icon on the empty state.
  static const double _iconSize = 48;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: AppSpacing.emptyState,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insights_outlined,
              size: _iconSize,
              color: scheme.primary,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'No group size data available',
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Enter at least one group size in the data matrix to see results.',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

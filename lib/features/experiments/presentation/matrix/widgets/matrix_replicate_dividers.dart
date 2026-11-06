// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';

import '../../../../../shared/ui/theme/app_design.dart';

/// Paints dividers between the matrix's replicate and factor columns and rows.
class MatrixReplicateDividers extends StatelessWidget {
  /// Uses [manager] for grid geometry and scroll offsets. Row dividers can be
  /// hidden when [showRowBoundaries] is false, such as in randomized order.
  /// [showColumnGroups] reserves space above the vertical divider for grouped
  /// column headings.
  const MatrixReplicateDividers({
    super.key,
    required this.manager,
    required this.showRowBoundaries,
    required this.showColumnGroups,
  });

  final PlutoGridStateManager manager;
  final bool showRowBoundaries;
  final bool showColumnGroups;

  @override
  Widget build(BuildContext context) {
    final horizontal = manager.scroll.bodyRowsHorizontal;
    final vertical = manager.scroll.bodyRowsVertical;
    final columns = manager.columns;
    final replicate = columns.indexWhere((column) => column.field == 'group');
    if (horizontal == null || vertical == null || replicate < 0) {
      return const SizedBox.shrink();
    }
    final rows = manager.rows;
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.all(PlutoGridSettings.gridPadding),
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _DividerPainter(
              horizontal: horizontal,
              vertical: vertical,
              color: Theme.of(context).colorScheme.outline,
              rtl: Directionality.of(context) == TextDirection.rtl,
              columnTop: showColumnGroups ? manager.columnHeight : 0,
              columnBoundary: _widthOf(columns.take(replicate + 1)),
              matrixWidth: _widthOf(columns),
              rowsTop: manager.rowsTopOffset,
              rowBoundaries: [
                if (showRowBoundaries)
                  for (var index = 1; index < rows.length; index++)
                    if (rows[index - 1].cells['group']?.value !=
                        rows[index].cells['group']?.value)
                      index * manager.rowTotalHeight,
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _widthOf(Iterable<PlutoColumn> columns) =>
      columns.fold(0.0, (width, column) => width + column.width);
}

/// Moves the visible dividers on the paint pass as the grid scrolls.
class _DividerPainter extends CustomPainter {
  _DividerPainter({
    required this.horizontal,
    required this.vertical,
    required this.color,
    required this.rtl,
    required this.columnTop,
    required this.columnBoundary,
    required this.matrixWidth,
    required this.rowsTop,
    required this.rowBoundaries,
  }) : super(repaint: Listenable.merge([horizontal, vertical]));

  final ScrollController horizontal;
  final ScrollController vertical;
  final Color color;
  final bool rtl;
  final double columnTop;
  final double columnBoundary;
  final double matrixWidth;
  final double rowsTop;
  final List<double> rowBoundaries;

  @override
  void paint(Canvas canvas, Size size) {
    if (!horizontal.hasClients || !vertical.hasClients) {
      return;
    }
    final paint = Paint()..color = color;
    const thickness = AppDesign.borderFocus;
    final x = columnBoundary - horizontal.offset;
    final left = rtl ? size.width - x - thickness : x;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (left + thickness > 0 && left < size.width) {
      canvas.drawRect(
        Rect.fromLTWH(left, columnTop, thickness, size.height - columnTop),
        paint,
      );
    }

    final rowWidth = (matrixWidth - horizontal.offset).clamp(0.0, size.width);
    final rowLeft = rtl ? size.width - rowWidth : 0.0;
    for (final boundary in rowBoundaries) {
      final y = rowsTop + boundary - vertical.offset;
      if (y < rowsTop) {
        continue;
      }
      if (y >= size.height) {
        break;
      }
      canvas.drawRect(Rect.fromLTWH(rowLeft, y, rowWidth, thickness), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DividerPainter oldDelegate) =>
      oldDelegate.horizontal != horizontal ||
      oldDelegate.vertical != vertical ||
      oldDelegate.color != color ||
      oldDelegate.rtl != rtl ||
      oldDelegate.columnTop != columnTop ||
      oldDelegate.columnBoundary != columnBoundary ||
      oldDelegate.matrixWidth != matrixWidth ||
      oldDelegate.rowsTop != rowsTop ||
      !listEquals(oldDelegate.rowBoundaries, rowBoundaries);
}

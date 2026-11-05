import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../styles/chart/chart_layout.dart';
import '../../../styles/chart/chart_scale.dart';
import '../services/factor_row_locator.dart';

/// Measures the actual label rows, rather than reserving a fixed vertical band.
class ChartXAxis {
  const ChartXAxis._();

  static AxisTitles build({
    required BuildContext context,
    required FactorRowLocator locator,
    required ChartScale scale,
    required double plotWidth,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final stateStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
      fontSize: scale.stateLabelFontSize,
      fontWeight: FontWeight.w600,
      color: scheme.onSurfaceVariant,
      height: 1.15,
    );
    final factorStyle = stateStyle.copyWith(
      fontSize: scale.factorLabelFontSize,
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
    );
    final span = locator.rows.isEmpty
        ? 2.0
        : locator.rows.last.secondX + 2 * ChartLayout.edgePad;
    final unitWidth = plotWidth / span;
    final factorWidth = math.max(24.0, unitWidth * 2 - 8);
    Size measure(String text, TextStyle style, double width) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: width);
      final size = painter.size;
      painter.dispose();
      return size;
    }

    final labels = [
      for (final row in locator.rows) ...[row.firstLabel, row.secondLabel],
    ];
    final rotated = labels.any(
      (label) =>
          measure(label, stateStyle, double.infinity).width > unitWidth - 8,
    );
    final labelWidth = math.max(24.0, unitWidth - (rotated ? 14 : 8));
    final sizes = {
      for (final label in labels) label: measure(label, stateStyle, labelWidth),
    };
    double rotatedHeight(Size size) =>
        rotated ? (size.width + size.height) / math.sqrt2 : size.height;
    final stateHeight = sizes.values.fold<double>(
      0,
      (height, size) => math.max(height, rotatedHeight(size)),
    );
    final factorHeight = locator.rows.fold<double>(
      0,
      (height, row) => math.max(
        height,
        measure(row.displayName, factorStyle, factorWidth).height,
      ),
    );
    const topGap = 4.0;
    const rowGap = 8.0;

    final reserve = topGap + stateHeight + rowGap + factorHeight + 2;
    Widget labelBand(Widget child) => SizedBox(
      height: reserve,
      child: Align(alignment: Alignment.topCenter, child: child),
    );
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        interval: ChartLayout.segmentSpan / 2,
        reservedSize: reserve,
        getTitlesWidget: (value, _) {
          final factor = locator.factorAtMidpoint(value);
          if (factor != null) {
            return labelBand(
              Padding(
                padding: EdgeInsets.only(top: topGap + stateHeight + rowGap),
                child: SizedBox(
                  width: factorWidth,
                  child: Text(
                    factor.displayName,
                    style: factorStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }
          final label = locator.stateLabelAt(value);
          if (label == null) {
            return const SizedBox.shrink();
          }
          final size = sizes[label]!;
          return labelBand(
            Padding(
              padding: const EdgeInsets.only(top: topGap),
              child: SizedBox(
                width: rotated
                    ? (size.width + size.height) / math.sqrt2
                    : size.width,
                height: rotatedHeight(size),
                child: Center(
                  child: OverflowBox(
                    minWidth: size.width,
                    maxWidth: size.width,
                    minHeight: size.height,
                    maxHeight: size.height,
                    child: Transform.rotate(
                      angle: rotated ? -math.pi / 4 : 0,
                      child: SizedBox(
                        width: size.width,
                        height: size.height,
                        child: Text(
                          label,
                          style: stateStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

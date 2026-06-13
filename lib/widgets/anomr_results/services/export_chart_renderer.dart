// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';

import '../../../model/project_form_model.dart';
import '../../../styles/chart/chart_layout.dart';
import '../../../styles/chart/chart_scale.dart';
import '../widgets/results_chart_card.dart';
import 'anomr_calculator.dart';
import 'chart_capture.dart';

/// Renders the results chart at a fixed export size independent of the
/// on-screen layout, platform, or viewport.
class ExportChartRenderer {
  const ExportChartRenderer._();

  /// Builds and rasterizes the full results card for export.
  ///
  /// The widget is mounted briefly in an off-screen overlay so theming and
  /// text layout match the app, but dimensions and chart geometry always use
  /// [ChartScale.export] and [ChartLayout.export].
  static Future<Uint8List?> capture({
    required OverlayState overlay,
    required ProjectFormModel formModel,
    required PlutoGridStateManager stateManager,
  }) async {
    final summary = AnomrCalculator.summarize(
      formModel: formModel,
      stateManager: stateManager,
      layout: ChartLayout.export,
    );

    final chartKey = GlobalKey();
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -30000,
        top: -30000,
        child: RepaintBoundary(
          key: chartKey,
          child: SizedBox(
            width: ChartScale.exportWidth,
            child: ResultsChartCard(
              factorRows: summary.factorRows,
              grandMean: summary.grandMean,
              lowerBound: summary.lowerBound,
              upperBound: summary.upperBound,
              detectableDiffPercent: summary.detectableDiffPercent,
              riskLevel: formModel.riskLevel,
              scale: ChartScale.export,
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    try {
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;
      return ChartCapture.capture(
        chartKey,
        pixelRatio: ChartScale.exportPixelRatio,
      );
    } finally {
      entry.remove();
    }
  }
}

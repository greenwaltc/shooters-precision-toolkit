// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';

import '../../../model/project_form_model.dart';
import '../../../model/saved_project.dart';
import '../../../styles/chart/chart_layout.dart';
import '../models/export_options.dart';
import 'anomr_calculator.dart';
import 'anomr_export_service.dart';
import 'export_chart_renderer.dart';

/// Outcome of a single export attempt.
sealed class ExportOutcome {
  const ExportOutcome();
}

class ExportSucceeded extends ExportOutcome {
  const ExportSucceeded(this.path);
  final String path;
}

class ExportCancelled extends ExportOutcome {
  const ExportCancelled();
}

class ExportFailed extends ExportOutcome {
  const ExportFailed(this.message);
  final String message;
}

/// Coordinates fixed-layout render → bytes generation → user save dialog for a
/// single export request. Stateless / pure orchestration: no UI of its own.
class ExportController {
  const ExportController({
    required this.overlay,
    required this.formModel,
    required this.stateManager,
    required this.project,
  });

  final OverlayState overlay;
  final ProjectFormModel formModel;
  final PlutoGridStateManager stateManager;
  final SavedProject project;

  Future<ExportOutcome> run(ExportOptions options) async {
    try {
      final chartImage = await ExportChartRenderer.capture(
        overlay: overlay,
        formModel: formModel,
        stateManager: stateManager,
      );
      if (chartImage == null) {
        return const ExportFailed('Could not render chart for export.');
      }

      final summary = AnomrCalculator.summarize(
        formModel: formModel,
        stateManager: stateManager,
        layout: ChartLayout.export,
      );

      final artifact = await AnomrExportService.generate(
        options: options,
        chartImage: chartImage,
        formModel: formModel,
        stateManager: stateManager,
        grandMean: summary.grandMean,
        detectableDiffPercent: summary.detectableDiffPercent,
        projectTitle: project.displayName,
      );

      final defaultName = AnomrExportService.sanitizeFileName(
        project.displayName.isEmpty ? 'results' : project.displayName,
      );

      final savedPath = await FilePicker.saveFile(
        dialogTitle: 'Export Results',
        fileName: '$defaultName.${artifact.extension}',
        bytes: artifact.bytes,
        type: FileType.custom,
        allowedExtensions: [artifact.extension],
      );

      if (savedPath == null) return const ExportCancelled();
      return ExportSucceeded(savedPath);
    } catch (error) {
      return ExportFailed('Export failed: $error');
    }
  }
}

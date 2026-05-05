import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:pluto_grid/pluto_grid.dart';

import '../../../model/project_form_model.dart';
import '../../../model/saved_project.dart';
import '../models/anomr_summary.dart';
import '../models/export_options.dart';
import 'anomr_export_service.dart';
import 'chart_capture.dart';

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

/// Coordinates capture → bytes generation → user save dialog for a single
/// export request. Stateless / pure orchestration: no UI of its own.
class ExportController {
  const ExportController({
    required this.chartKey,
    required this.summary,
    required this.formModel,
    required this.stateManager,
    required this.project,
  });

  final GlobalKey chartKey;
  final AnomrSummary summary;
  final ProjectFormModel formModel;
  final PlutoGridStateManager stateManager;
  final SavedProject project;

  Future<ExportOutcome> run(ExportOptions options) async {
    try {
      final chartImage = await ChartCapture.capture(chartKey);
      if (chartImage == null) {
        return const ExportFailed('Could not capture chart.');
      }

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
        project.displayName.isEmpty ? 'anomr_results' : project.displayName,
      );

      final savedPath = await FilePicker.saveFile(
        dialogTitle: 'Export ANOMR Results',
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

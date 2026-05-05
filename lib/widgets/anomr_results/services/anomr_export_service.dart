import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pluto_grid/pluto_grid.dart';

import '../../../model/project_form_model.dart';
import '../../../styles/tokens/app_colors.dart';
import '../models/export_options.dart';
import 'anomr_pdf_builder.dart';

/// Result of producing the bytes for a single export operation.
class ExportArtifact {
  const ExportArtifact({required this.bytes, required this.extension});

  final Uint8List bytes;
  final String extension;
}

/// Format-aware bytes producer plus filename utilities.
class AnomrExportService {
  const AnomrExportService._();

  /// Produces the bytes for a single export, given the captured chart PNG.
  static Future<ExportArtifact> generate({
    required ExportOptions options,
    required Uint8List chartImage,
    required ProjectFormModel formModel,
    required PlutoGridStateManager stateManager,
    required double grandMean,
    required double detectableDiffPercent,
    required String projectTitle,
  }) async {
    final Uint8List bytes;
    switch (options.format) {
      case ExportFormat.png:
        bytes = chartImage;
        break;
      case ExportFormat.jpeg:
        bytes = await _reencodeAsJpeg(chartImage);
        break;
      case ExportFormat.pdf:
        bytes = await AnomrPdfBuilder.build(
          projectTitle: projectTitle,
          formModel: formModel,
          chartImage: chartImage,
          stateManager: stateManager,
          includeMatrix: options.includeMatrix,
          grandMean: grandMean,
          detectableDiffPercent: detectableDiffPercent,
        );
        break;
    }
    return ExportArtifact(bytes: bytes, extension: options.format.extension);
  }

  /// Sanitizes [name] into a safe default file name.
  static String sanitizeFileName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^\w\s.-]'), '').trim();
    final collapsed = cleaned.replaceAll(RegExp(r'\s+'), '_');
    return collapsed.isEmpty ? 'anomr_results' : collapsed;
  }

  /// JPEG quality used by [_reencodeAsJpeg].
  static const int _jpegQuality = 92;

  static Future<Uint8List> _reencodeAsJpeg(Uint8List pngBytes) async {
    final decoded = img.decodePng(pngBytes);
    if (decoded == null) return pngBytes;
    final withBackground = img.Image(
      width: decoded.width,
      height: decoded.height,
      numChannels: 4,
    );
    final bg = AppColors.exportImageBackground;
    img.fill(
      withBackground,
      color: img.ColorRgba8(
        (bg.r * 255).round(),
        (bg.g * 255).round(),
        (bg.b * 255).round(),
        (bg.a * 255).round(),
      ),
    );
    img.compositeImage(withBackground, decoded);
    return Uint8List.fromList(
      img.encodeJpg(withBackground, quality: _jpegQuality),
    );
  }
}

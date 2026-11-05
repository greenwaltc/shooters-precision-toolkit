// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Centralized PDF styling tokens used by the export pipeline.
///
/// Mirrors the on-screen design language for the export so the printable
/// output reads as a sibling of the in-app results card.
class PdfStyles {
  const PdfStyles._();

  // Page geometry
  static const pw.EdgeInsets pageMargin = pw.EdgeInsets.all(36);
  static const pw.EdgeInsets tableHeaderCell = pw.EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 6,
  );
  static const pw.EdgeInsets tableBodyCell = pw.EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 4,
  );

  // Spacing
  static const double gapXs = 2;
  static const double gapSm = 4;
  static const double gapMd = 8;
  static const double gapLg = 12;
  static const double gapXl = 18;
  static const double gapXxl = 24;

  // Colors
  static const PdfColor titleColor = PdfColors.black;
  static const PdfColor subtitleColor = PdfColors.grey700;
  static const PdfColor statLabelColor = PdfColors.grey600;
  static const PdfColor dividerColor = PdfColors.grey400;
  static const PdfColor tableHeaderFill = PdfColors.grey200;
  static const PdfColor tableBorderColor = PdfColors.grey400;

  // Borders
  static const double tableBorderWidth = 0.5;

  // Typography
  static pw.TextStyle title() => pw.TextStyle(
    fontSize: 22,
    fontWeight: pw.FontWeight.bold,
    color: titleColor,
  );

  static pw.TextStyle subtitle() =>
      const pw.TextStyle(fontSize: 14, color: subtitleColor);

  static pw.TextStyle sectionHeader() =>
      pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold);

  static pw.TextStyle statLabel() =>
      pw.TextStyle(fontSize: 9, color: statLabelColor, letterSpacing: 0.8);

  static pw.TextStyle statValue() =>
      pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);

  static pw.TextStyle tableHeaderCellText() =>
      pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10);

  static pw.TextStyle tableBodyCellText() => const pw.TextStyle(fontSize: 10);
}

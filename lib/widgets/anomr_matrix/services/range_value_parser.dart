// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// Result of parsing a range cell input string.
class RangeValueParseResult {
  const RangeValueParseResult.empty()
      : displayValue = null,
        numericValue = null,
        invalid = false;

  const RangeValueParseResult.invalid()
      : displayValue = null,
        numericValue = null,
        invalid = true;

  const RangeValueParseResult.valid({
    required this.displayValue,
    required this.numericValue,
  }) : invalid = false;

  /// Normalized value shown in the cell, or null when empty/invalid.
  final String? displayValue;

  /// Parsed numeric value used for calculations, or null when empty/invalid.
  final double? numericValue;

  /// True when the input was non-empty but could not be parsed as a number.
  final bool invalid;
}

/// Parses and normalizes user-entered range values (Excel-style).
class RangeValueParser {
  const RangeValueParser._();

  static const invalidInputMessage =
      'Range values must be numbers. Please correct any invalid cells.';

  static final RegExp _fractionPattern = RegExp(
    r'^(-?\d+)\s*/\s*(\d+)$',
  );

  static RangeValueParseResult parse(Object? raw) {
    if (raw == null) {
      return const RangeValueParseResult.empty();
    }

    final text = raw.toString().trim();
    if (text.isEmpty) {
      return const RangeValueParseResult.empty();
    }

    final numericValue = _parseNumeric(text);
    if (numericValue == null) {
      return const RangeValueParseResult.invalid();
    }

    return RangeValueParseResult.valid(
      displayValue: _formatDisplay(numericValue),
      numericValue: numericValue,
    );
  }

  static double? toDouble(Object? raw) => parse(raw).numericValue;

  static double? _parseNumeric(String text) {
    final fraction = _fractionPattern.firstMatch(text);
    if (fraction != null) {
      final numerator = int.parse(fraction.group(1)!);
      final denominator = int.parse(fraction.group(2)!);
      if (denominator == 0) {
        return null;
      }
      return numerator / denominator;
    }

    return double.tryParse(text);
  }

  static String _formatDisplay(double value) {
    if (value.isNaN || value.isInfinite) {
      return '';
    }

    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }

    return _trimTrailingZeros(value.toString());
  }

  static String _trimTrailingZeros(String text) {
    if (!text.contains('.')) {
      return text;
    }

    return text
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

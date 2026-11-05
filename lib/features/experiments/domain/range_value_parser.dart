// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// Result of parsing a range cell input string.
class RangeValueParseResult {
  /// Represents an empty cell with no display value or number.
  const RangeValueParseResult.empty()
    : displayValue = null,
      numericValue = null,
      invalid = false;

  /// Represents nonempty input that cannot be used as a measurement.
  const RangeValueParseResult.invalid()
    : displayValue = null,
      numericValue = null,
      invalid = true;

  /// Represents a normalized cell value and its numeric measurement.
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

/// A parser for group sizes entered in the matrix or pasted from a spreadsheet.
class RangeValueParser {
  const RangeValueParser._();

  static final RegExp _fractionPattern = RegExp(r'^(-?\d+)\s*/\s*(\d+)$');

  /// Parses a cell entry as a finite number or a simple fraction.
  ///
  /// Null and whitespace-only input count as empty. An invalid entry returns a
  /// result marked invalid.
  static RangeValueParseResult parse(Object? raw) {
    if (raw == null) {
      return const RangeValueParseResult.empty();
    }

    final text = raw.toString().trim();
    if (text.isEmpty) {
      return const RangeValueParseResult.empty();
    }

    final numericValue = _parseNumeric(text);
    if (numericValue == null || !numericValue.isFinite) {
      return const RangeValueParseResult.invalid();
    }

    return RangeValueParseResult.valid(
      displayValue: _formatDisplay(numericValue),
      numericValue: numericValue,
    );
  }

  /// Returns the parsed measurement, or null for empty or invalid input.
  static double? toDouble(Object? raw) => parse(raw).numericValue;

  static double? _parseNumeric(String text) {
    final fraction = _fractionPattern.firstMatch(text);
    if (fraction != null) {
      final numerator = double.tryParse(fraction.group(1)!);
      final denominator = double.tryParse(fraction.group(2)!);
      if (numerator == null ||
          denominator == null ||
          !numerator.isFinite ||
          !denominator.isFinite ||
          denominator == 0) {
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

    if (value.abs() <= _maxExactInteger && value == value.truncateToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  // Largest integer represented exactly by IEEE-754 doubles on all targets.
  static const _maxExactInteger = 9007199254740991;
}

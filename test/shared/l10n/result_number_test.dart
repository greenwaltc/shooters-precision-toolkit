import 'package:bramwells_precision_test_kit/shared/l10n/result_number.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('results trim fractional padding while preserving useful precision', () {
    expect(formatResultNumber(10), '10');
    expect(formatResultNumber(1.5), '1.5');
    expect(formatResultNumber(1.23456), '1.2346');
    expect(formatResultNumber(1.0001), '1.0001');
    expect(formatResultNumber(0), '0');
    expect(formatResultNumber(-0.0), '0');
    expect(formatResultNumber(-0.00001), '0');
    expect(formatResultNumber(-1.25), '-1.25');
    expect(formatResultNumber(1234.5), '1,234.5');
  });

  test('chart precision and locale are preserved without trailing zeros', () {
    expect(formatResultNumber(12.105, places: 2), '12.11');
    expect(formatResultNumber(12.1, places: 2), '12.1');
    expect(formatResultNumber(100, places: 2), '100');
    expect(formatResultNumber(1234.5, locale: 'de'), '1.234,5');
    expect(formatResultNumber(12, locale: 'de'), '12');
  });
}

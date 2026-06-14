import 'package:flutter_test/flutter_test.dart';
import 'package:shooters_precision_test_kit/widgets/anomr_matrix/services/range_value_parser.dart';

void main() {
  group('RangeValueParser.parse', () {
    test('parses whole numbers without a decimal suffix', () {
      final result = RangeValueParser.parse('7');
      expect(result.invalid, isFalse);
      expect(result.displayValue, '7');
      expect(result.numericValue, 7);
    });

    test('parses leading-decimal values', () {
      final result = RangeValueParser.parse('.7');
      expect(result.invalid, isFalse);
      expect(result.displayValue, '0.7');
      expect(result.numericValue, 0.7);
    });

    test('parses decimal values', () {
      final result = RangeValueParser.parse('1.7');
      expect(result.invalid, isFalse);
      expect(result.displayValue, '1.7');
      expect(result.numericValue, 1.7);
    });

    test('parses simple fractions into decimals', () {
      final result = RangeValueParser.parse('1/4');
      expect(result.invalid, isFalse);
      expect(result.displayValue, '0.25');
      expect(result.numericValue, 0.25);
    });

    test('treats empty input as null', () {
      final result = RangeValueParser.parse('   ');
      expect(result.invalid, isFalse);
      expect(result.displayValue, isNull);
      expect(result.numericValue, isNull);
    });

    test('marks non-numeric input invalid', () {
      final result = RangeValueParser.parse('abc');
      expect(result.invalid, isTrue);
      expect(result.displayValue, isNull);
      expect(result.numericValue, isNull);
    });
  });
}

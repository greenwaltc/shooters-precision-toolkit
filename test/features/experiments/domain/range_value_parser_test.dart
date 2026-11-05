import 'package:bramwells_precision_test_kit/features/experiments/domain/range_value_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'scientific readings round-trip without integer truncation or exponent trimming',
    () {
      for (final value in [1e100, 1.25e100, -1.25e100, 1.25e-100]) {
        final parsed = RangeValueParser.parse(value.toString());
        expect(parsed.invalid, isFalse);
        expect(RangeValueParser.toDouble(parsed.displayValue), value);
      }
      expect(RangeValueParser.parse('${'9' * 600}/1').invalid, isTrue);
    },
  );

  group('RangeValueParser.parse', () {
    test('rejects non-finite values and zero denominators', () {
      for (final input in ['NaN', 'Infinity', '-Infinity', '1e999', '1/0']) {
        final result = RangeValueParser.parse(input);
        expect(result.invalid, isTrue, reason: input);
        expect(result.numericValue, isNull, reason: input);
      }
    });
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

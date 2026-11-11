import 'package:intl/intl.dart';

import '../foundation/behavior_policy.dart';

/// Localized result display with bounded precision and no fractional padding.
/// Calculation and stored measurement precision are unaffected.
String formatResultNumber(
  num value, {
  String locale = 'en',
  int places = BehaviorPolicy.resultDecimalPlaces,
}) {
  final format = NumberFormat.decimalPattern(locale)
    ..minimumFractionDigits = 0
    ..maximumFractionDigits = places;
  // Avoid displaying a minus sign when rounding a tiny negative value to zero.
  return format.format(
    value == 0 ||
            (value < 0 && double.parse(value.toStringAsFixed(places)) == 0)
        ? 0
        : value,
  );
}

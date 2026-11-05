import 'package:intl/intl.dart';

/// Display only; persistence stores UTC ISO-8601 instants independently.
String formatProjectTimestamp(DateTime instant, {required String locale}) =>
    DateFormat.yMd(locale).add_jm().format(instant.toLocal());

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;

import '../../../model/project_form_model.dart';
import 'effect_status.dart';
import 'factor_stats.dart';

/// All data needed to render a single factor's line segment, label set, and
/// conclusion within the combined results chart.
@immutable
class FactorRow {
  const FactorRow({
    required this.index,
    required this.factor,
    required this.stats,
    required this.color,
    required this.status,
    required this.firstX,
    required this.secondX,
    required this.firstLabel,
    required this.secondLabel,
    required this.displayName,
  });

  final int index;
  final FactorDefinition factor;
  final FactorStats stats;
  final Color color;
  final EffectStatus status;
  final double firstX;
  final double secondX;
  final String firstLabel;
  final String secondLabel;
  final String displayName;

  double get midpointX => (firstX + secondX) / 2;
}

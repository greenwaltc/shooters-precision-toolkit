/// X-axis layout constants for the combined ANOMR results chart.
///
/// Values are chosen so that every factor-state tick lands on an integer x
/// coordinate. That guarantees `fl_chart`'s `SideTitles` (interval 1) calls
/// `getTitlesWidget` at every state position regardless of factor count.
class ChartLayout {
  const ChartLayout._();

  /// Distance in chart x-units between a factor's first and second state.
  static const double segmentSpan = 1.0;

  /// Empty gap between adjacent factor groups.
  static const double groupGap = 2.0;

  /// Leading/trailing padding so data dots are not clipped at the edges.
  static const double edgePad = 0.5;

  /// X coordinate of the *first* state for the factor at [index].
  static double firstXFor(int index) => index * (segmentSpan + groupGap);

  /// X coordinate of the *second* state for the factor at [index].
  static double secondXFor(int index) => firstXFor(index) + segmentSpan;
}

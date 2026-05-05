/// Border-width tokens for the app.
///
/// Used by input fields, outlined cards, dividers, and chart axes. Keep the
/// scale tight — adding a value here should be a deliberate design call.
class AppBorders {
  const AppBorders._();

  /// PDF table grid lines and other extra-fine separators.
  static const double hairline = 0.5;

  /// Default outlined-card / list-tile border thickness.
  static const double thin = 1.0;

  /// Slightly emphasized borders (default text-field, grouped panels).
  static const double regular = 1.5;

  /// Focus / active-state borders (e.g. focused text field).
  static const double focus = 2.0;
}

/// Stable string keys for feature flags (suitable for JSON / remote config).
enum FeatureFlag {
  imputeMissingData('impute_missing_data'),
  themeModeToggle('theme_mode_toggle');

  /// Associates a feature with its public configuration key.
  const FeatureFlag(this.key);

  final String key;
}

/// Typed feature-flag registry with compile-time defaults.
///
/// Follows the common pattern of named flags, explicit defaults, and a single
/// lookup API so overrides (environment, remote config, etc.) can be added
/// later without changing call sites.
class FeatureFlags {
  /// Creates immutable feature settings from a copy of [values].
  FeatureFlags({required Map<FeatureFlag, bool> values})
    : _values = Map.unmodifiable(values);

  const FeatureFlags._(this._values);

  static const FeatureFlags defaults = FeatureFlags._({
    FeatureFlag.imputeMissingData: false,
    FeatureFlag.themeModeToggle: false,
  });

  final Map<FeatureFlag, bool> _values;

  /// Whether [flag] is explicitly enabled. Omitted flags are disabled.
  bool isEnabled(FeatureFlag flag) => _values[flag] ?? false;
}

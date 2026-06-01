// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// Stable string keys for feature flags (suitable for JSON / remote config).
enum FeatureFlag {
  imputeMissingData('impute_missing_data');

  const FeatureFlag(this.key);

  final String key;
}

/// Typed feature-flag registry with compile-time defaults.
///
/// Follows the common pattern of named flags, explicit defaults, and a single
/// lookup API so overrides (environment, remote config, etc.) can be added
/// later without changing call sites.
class FeatureFlags {
  const FeatureFlags({required Map<FeatureFlag, bool> values})
    : _values = values;

  static const FeatureFlags defaults = FeatureFlags(
    values: {FeatureFlag.imputeMissingData: false},
  );

  final Map<FeatureFlag, bool> _values;

  bool isEnabled(FeatureFlag flag) => _values[flag] ?? false;

  factory FeatureFlags.fromJson(Map<String, dynamic>? json) {
    if (json == null) return defaults;

    return FeatureFlags(
      values: {
        for (final flag in FeatureFlag.values)
          flag: json[flag.key] as bool? ?? defaults.isEnabled(flag),
      },
    );
  }

  Map<String, bool> toJson() {
    return {for (final flag in FeatureFlag.values) flag.key: isEnabled(flag)};
  }
}

/// Application-wide configuration for project behavior.
class ProjectConfiguration {
  const ProjectConfiguration({required this.featureFlags});

  /// Active configuration for the running app.
  static const ProjectConfiguration current = ProjectConfiguration(
    featureFlags: FeatureFlags.defaults,
  );

  final FeatureFlags featureFlags;
}

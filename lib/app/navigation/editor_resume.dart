/// The selected project and last workspace page in the current browser tab.
typedef EditorLocation = ({String projectId, String route});

/// Stores only navigation metadata for a single account and browser tab.
abstract interface class EditorResume {
  /// Consumes the previous project location on a browser reload, if available.
  EditorLocation? takeReloadLocation();

  /// Remembers [location], or clears it when there is no editing target.
  void remember(EditorLocation? location);
}

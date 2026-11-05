/// Storage for the name of the user's chosen display theme.
abstract interface class ThemePreferenceStorage {
  /// Reads the stored theme name, or returns null if no value is saved.
  Future<String?> read();

  /// Stores [name] as the new theme preference.
  Future<void> write(String name);
}

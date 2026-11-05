abstract interface class ThemePreferenceStorage {
  Future<String?> read();
  Future<void> write(String name);
}

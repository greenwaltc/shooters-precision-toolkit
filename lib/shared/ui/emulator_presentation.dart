/// Narrow UI projection of build policy. It cannot change deployment identity.
final class EmulatorPresentation {
  /// Describes whether the interface should show that it uses local Firebase
  /// emulators.
  const EmulatorPresentation({required this.enabled});
  final bool enabled;
}

/// Only user-initiated events are read. The consumer owns the returned cleanup.
abstract interface class ClipboardEvents {
  /// Registers copy and paste callbacks and returns a function that unregisters
  /// them.
  ///
  /// The owner calls the returned function when the target is disposed.
  /// [acceptsPaste] can reject events when the target is inactive.
  void Function() register({
    required bool Function() acceptsPaste,
    required String? Function() copyText,
    required void Function(String) pasteText,
  });
}

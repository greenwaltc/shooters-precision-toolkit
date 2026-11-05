/// Only user-initiated events are read. The consumer owns the returned cleanup.
abstract interface class ClipboardEvents {
  void Function() register({
    required bool Function() acceptsPaste,
    required String? Function() copyText,
    required void Function(String) pasteText,
  });
}

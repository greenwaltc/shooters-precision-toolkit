String formatProjectTimestamp(DateTime dateTime) {
  final localTime = dateTime.toLocal();

  return '${localTime.year}-${_twoDigits(localTime.month)}-'
      '${_twoDigits(localTime.day)} '
      '${_twoDigits(localTime.hour)}:${_twoDigits(localTime.minute)}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

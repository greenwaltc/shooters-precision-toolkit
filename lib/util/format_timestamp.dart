// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

String formatProjectTimestamp(DateTime dateTime) {
  final localTime = dateTime.toLocal();

  return '${localTime.year}-${_twoDigits(localTime.month)}-'
      '${_twoDigits(localTime.day)} '
      '${_twoDigits(localTime.hour)}:${_twoDigits(localTime.minute)}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

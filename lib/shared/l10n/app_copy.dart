import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'generated/app_localizations.dart';
import 'generated/app_localizations_en.dart';

export 'generated/app_localizations.dart';

/// English is the sole supported product language. Non-widget export/validation
/// adapters use this explicit resource, never duplicated inline English prose.
abstract final class AppCopy {
  static final AppLocalizations english = AppLocalizationsEn();
}

extension LocalizedPresentation on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String decimal(num value, {int places = 4}) =>
      NumberFormat.decimalPatternDigits(
        locale: Localizations.localeOf(this).toLanguageTag(),
        decimalDigits: places,
      ).format(value);
}

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'generated/app_localizations.dart';
import 'generated/app_localizations_en.dart';
import 'result_number.dart';

export 'generated/app_localizations.dart';

/// English is the sole supported product language. Non-widget export/validation
/// adapters use this explicit resource, never duplicated inline English prose.
abstract final class AppCopy {
  static final AppLocalizations english = AppLocalizationsEn();
}

/// Translations and number formatting for the active widget locale.
extension LocalizedPresentation on BuildContext {
  /// The translations available to this widget.
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Formats a result with at most [places] decimals and no trailing zeros.
  String resultNumber(num value, {int places = 4}) => formatResultNumber(
    value,
    locale: Localizations.localeOf(this).toLanguageTag(),
    places: places,
  );

  /// Formats [value] using the active locale and the requested number of
  /// decimal places.
  String decimal(num value, {int places = 4}) =>
      NumberFormat.decimalPatternDigits(
        locale: Localizations.localeOf(this).toLanguageTag(),
        decimalDigits: places,
      ).format(value);
}

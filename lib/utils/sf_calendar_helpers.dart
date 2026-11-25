import 'package:flutter/widgets.dart';
import 'package:heliumapp/l10n/app_localizations.dart';
import 'package:heliumapp/utils/forwarding_localizations.dart';
import 'package:syncfusion_flutter_core/localizations.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';

class HeliumSfLocalizationsDelegate
    extends LocalizationsDelegate<SfLocalizations> {
  const HeliumSfLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.delegate.isSupported(locale) &&
      SfGlobalLocalizations.delegate.isSupported(locale);

  @override
  Future<SfLocalizations> load(Locale locale) =>
      SfGlobalLocalizations.delegate.load(locale).then(
            (base) => _HeliumSfLocalizations(base, lookupAppLocalizations(locale)),
          );

  @override
  bool shouldReload(covariant LocalizationsDelegate<SfLocalizations> old) =>
      false;
}

class _HeliumSfLocalizations extends ForwardingSfLocalizations {
  final AppLocalizations _app;

  const _HeliumSfLocalizations(super.base, this._app);

  @override
  String get noEventsCalendarLabel => _app.calendarNoEventsLabel;

  @override
  String get noSelectedDateCalendarLabel => _app.calendarNoSelectedDateLabel;
}

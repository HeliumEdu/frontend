import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:syncfusion_flutter_core/localizations.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';

class HeliumSfLocalizationsDelegate
    extends LocalizationsDelegate<SfLocalizations> {
  const HeliumSfLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<SfLocalizations> load(Locale locale) =>
      SynchronousFuture(const _HeliumSfLocalizations());

  @override
  bool shouldReload(covariant LocalizationsDelegate<SfLocalizations> old) =>
      false;
}

class _HeliumSfLocalizations extends SfLocalizationsEn {
  const _HeliumSfLocalizations();

  @override
  String get noEventsCalendarLabel => 'Nothing to see here';

  @override
  String get noSelectedDateCalendarLabel => 'Select a date to get started';
}

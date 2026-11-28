import 'package:flutter/foundation.dart';
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

/// Loads synchronously, so the subtree it overrides never builds without it.
class WeekNumberLabelSfLocalizationsDelegate
    extends LocalizationsDelegate<SfLocalizations> {
  final SfLocalizations base;
  final String label;

  const WeekNumberLabelSfLocalizationsDelegate({
    required this.base,
    required this.label,
  });

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<SfLocalizations> load(Locale locale) =>
      SynchronousFuture(_WeekNumberLabelSfLocalizations(base, label));

  @override
  bool shouldReload(covariant WeekNumberLabelSfLocalizationsDelegate old) =>
      old.base != base || old.label != label;
}

class _WeekNumberLabelSfLocalizations extends ForwardingSfLocalizations {
  final String _label;

  const _WeekNumberLabelSfLocalizations(super.base, this._label);

  @override
  String get weeknumberLabel => _label;
}

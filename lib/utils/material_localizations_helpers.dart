import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:intl/intl.dart';

/// Applies the user's regional settings to every Material widget that reads
/// them, such as the first weekday column in date pickers.
class HeliumMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  final int firstDayOfWeekIndex;
  final int dateFormat;

  const HeliumMaterialLocalizationsDelegate({
    required this.firstDayOfWeekIndex,
    required this.dateFormat,
  });

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture(HeliumMaterialLocalizations(
        firstDayOfWeekIndex: firstDayOfWeekIndex,
        dateFormat: dateFormat,
      ));

  @override
  bool shouldReload(covariant HeliumMaterialLocalizationsDelegate old) =>
      old.firstDayOfWeekIndex != firstDayOfWeekIndex || old.dateFormat != dateFormat;
}

/// Applies regional settings that Material reads from the media query, such
/// as the clock time pickers and [TimeOfDay.format] use.
class RegionalFormatScope extends StatelessWidget {
  final bool alwaysUse24HourFormat;
  final Widget child;

  const RegionalFormatScope({
    super.key,
    required this.alwaysUse24HourFormat,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: alwaysUse24HourFormat),
      child: child,
    );
  }
}

/// Material's defaults are US-only; word-month dates and typed numeric dates
/// follow the regional day/month order.
class HeliumMaterialLocalizations extends DefaultMaterialLocalizations {
  @override
  final int firstDayOfWeekIndex;
  final int dateFormat;

  const HeliumMaterialLocalizations({
    required this.firstDayOfWeekIndex,
    required this.dateFormat,
  });

  bool get _monthFirst => dateFormat == RegionalFormatConstants.dateFormatMonthDayYear;

  String _ordered(String monthFirst, String dayFirst) => _monthFirst ? monthFirst : dayFirst;

  String get _compactPattern => _ordered('MM/dd/yyyy', 'dd/MM/yyyy');

  @override
  String formatShortDate(DateTime date) => DateFormat(_ordered('MMM d, yyyy', 'd MMM yyyy')).format(date);

  @override
  String formatMediumDate(DateTime date) => DateFormat(_ordered('EEE, MMM d', 'EEE, d MMM')).format(date);

  @override
  String formatFullDate(DateTime date) =>
      DateFormat(_ordered('EEEE, MMMM d, yyyy', 'EEEE, d MMMM yyyy')).format(date);

  @override
  String formatShortMonthDay(DateTime date) => DateFormat(_ordered('MMM d', 'd MMM')).format(date);

  @override
  String formatCompactDate(DateTime date) => DateFormat(_compactPattern).format(date);

  @override
  DateTime? parseCompactDate(String? inputString) {
    if (inputString == null) return null;
    final parts = inputString.split(dateSeparator);
    if (parts.length != 3) return null;
    final numbers = parts.map((part) => int.tryParse(part, radix: 10)).toList();
    if (numbers.any((number) => number == null)) return null;
    final year = numbers[2]!;
    final (month, day) = _monthFirst ? (numbers[0]!, numbers[1]!) : (numbers[1]!, numbers[0]!);
    if (year < 1 || month < 1 || month > 12 || day < 1) return null;
    final parsed = DateTime(year, month, day);
    return parsed.month == month && parsed.day == day ? parsed : null;
  }

  @override
  String get dateHelpText => _compactPattern.toLowerCase();
}

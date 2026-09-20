import 'dart:ui';

import 'package:heliumapp/config/regional_settings_notifier.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/presentation/features/planner/constants/reminder_constants.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:intl/intl.dart';

extension PluralExtension on num {
  String plural(String singularWord, [String? pluralWord]) {
    return this != 1
        ? (pluralWord ?? '${singularWord}s')
        : singularWord;
  }
}

extension BytesFormatting on int {
  int get inMegabytes => this ~/ (1024 * 1024);
}

String reminderOffset(ReminderModel reminder) {
  final plural = ReminderConstants.offsetTypes[reminder.offsetType].toLowerCase();
  final singular = plural.substring(0, plural.length - 1);
  return '${reminder.offset} ${reminder.offset.plural(singular)}';
}

class HeliumNumber {
  /// Canonicalises a typed or formatted decimal to a point decimal with no
  /// grouping, whichever separators it uses: a lone `,` or `.` is the decimal
  /// point, when both appear the last one is, and a repeated one is grouping.
  static String normalize(String text) {
    final trimmed = text.trim();
    final lastComma = trimmed.lastIndexOf(',');
    final lastPoint = trimmed.lastIndexOf('.');
    final String decimal;
    if (lastComma >= 0 && lastPoint >= 0) {
      decimal = lastComma > lastPoint ? ',' : '.';
    } else if (lastComma >= 0) {
      decimal = trimmed.indexOf(',') == lastComma ? ',' : '';
    } else {
      decimal = trimmed.indexOf('.') == lastPoint ? '.' : '';
    }
    final grouping = decimal == ',' ? '.' : (decimal == '.' ? ',' : '.,');
    var digits = trimmed;
    for (final separator in grouping.split('')) {
      digits = digits.replaceAll(separator, '');
    }
    return decimal.isEmpty ? digits : digits.replaceAll(decimal, '.');
  }

  static double? parse(String text) {
    return double.tryParse(normalize(text));
  }

  /// A locale whose decimal and grouping separators match the number format
  /// setting, so every number renders through the same intl rules.
  static String get _formatLocale =>
      RegionalSettingsNotifier().numberFormat == RegionalFormatConstants.numberFormatComma ? 'de_DE' : 'en_US';

  /// Renders [value] with the regional decimal and thousands separators.
  /// [fractionDigits] fixes the precision (up to 10 fraction digits when
  /// omitted), and [trimZeros] drops a trailing fraction of zeros so 85.00
  /// reads as 85. [parse] reads the result back in either format.
  static String format(double value, {int? fractionDigits, bool trimZeros = false}) {
    final numberFormat = NumberFormat.decimalPattern(_formatLocale)
      ..minimumFractionDigits = trimZeros ? 0 : (fractionDigits ?? 0)
      ..maximumFractionDigits = fractionDigits ?? 10;
    return numberFormat.format(value);
  }

  /// The decimal separator the device locale writes, falling back to a point
  /// when the locale is unknown.
  static int detectNumberFormat(Locale locale) {
    final String separator;
    try {
      separator = NumberFormat.decimalPattern(locale.toString()).symbols.DECIMAL_SEP;
    } on ArgumentError {
      return FallbackConstants.defaultNumberFormat;
    }
    return separator == ','
        ? RegionalFormatConstants.numberFormatComma
        : RegionalFormatConstants.numberFormatPoint;
  }

  /// A recognisable sample for the settings control; the app itself never
  /// groups thousands, so the grouping shown here is only the familiar cue.
  static String numberFormatExample(int numberFormat) {
    return numberFormat == RegionalFormatConstants.numberFormatComma ? '1.234,5' : '1,234.5';
  }
}

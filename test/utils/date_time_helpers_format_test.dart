import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/regional_settings_notifier.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/standalone.dart' as tz;

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('DateTimeHelpers', () {
    group('formatName', () {
      test('returns abbreviated day name', () {
        final monday = DateTime(2025, 1, 20); // Monday
        expect(HeliumDateTime.formatDayNameShort(monday), equals('Mon'));
      });

      test('returns 3-character day abbreviation', () {
        final sunday = DateTime(2025, 1, 19); // Sunday
        final result = HeliumDateTime.formatDayNameShort(sunday);
        expect(result.length, equals(3));
      });
    });

    group('time formatting follows the regional clock', () {
      final afternoon = DateTime(2026, 9, 20, 15, 0);
      final afternoonWithMinutes = DateTime(2026, 9, 20, 15, 5);

      Future<void> useClock(int timeFormat) => RegionalSettingsNotifier().update(
            weekStartsOn: 0,
            dateFormat: 0,
            timeFormat: timeFormat,
            numberFormat: 0,
          );

      tearDown(() => useClock(RegionalFormatConstants.timeFormatTwelveHour));

      test('12-hour keeps the short form on the hour', () async {
        await useClock(RegionalFormatConstants.timeFormatTwelveHour);
        expect(HeliumTime.format(const TimeOfDay(hour: 15, minute: 0)), '3:00 PM');
        expect(HeliumDateTime.formatTime(afternoon), '3 PM');
        expect(HeliumDateTime.formatTime(afternoonWithMinutes), '3:05 PM');
        expect(HeliumDateTime.formatDateAndTimeForTodos(afternoon), 'Sun, Sep 20 • 3 PM');
        expect(HeliumTime.timeRulerPattern, 'h a');
      });

      test('24-hour never drops the minutes', () async {
        await useClock(RegionalFormatConstants.timeFormatTwentyFourHour);
        expect(HeliumTime.format(const TimeOfDay(hour: 15, minute: 0)), '15:00');
        expect(HeliumDateTime.formatTime(afternoon), '15:00');
        expect(HeliumDateTime.formatTime(afternoonWithMinutes), '15:05');
        expect(HeliumDateTime.formatTime(DateTime(2026, 9, 20, 0, 5)), '00:05');
        expect(HeliumDateTime.formatDateAndTimeForTodos(afternoon), 'Sun, Sep 20 • 15:00');
        expect(HeliumTime.timeRulerPattern, 'HH:mm');
      });
    });

    group('date formatting follows the regional order', () {
      final date = DateTime(2026, 9, 4, 15, 0);

      Future<void> useOrder(int dateFormat) => RegionalSettingsNotifier().update(
            weekStartsOn: 0,
            dateFormat: dateFormat,
            timeFormat: 0,
            numberFormat: 0,
          );

      tearDown(() => useOrder(RegionalFormatConstants.dateFormatMonthDayYear));

      test('month/day/year reads month-first', () async {
        await useOrder(RegionalFormatConstants.dateFormatMonthDayYear);
        expect(HeliumDateTime.formatDate(date), 'Sep 4, 2026');
        expect(HeliumDateTime.formatDate(date, abbreviateMonth: false, showYear: false), 'September 4');
        expect(HeliumDateTime.formatDateForTodos(date), 'Fri, Sep 4');
        expect(HeliumDateTime.formatDateAndTimeForTodos(date), 'Fri, Sep 4 • 3 PM');
        expect(HeliumDateTime.formatDateWithDay(date), 'Friday, September 4');
        expect(HeliumDateTime.dateFormatForChartAxis.format(date), 'Sep 4');
      });

      test('day/month/year reads day-first', () async {
        await useOrder(RegionalFormatConstants.dateFormatDayMonthYear);
        expect(HeliumDateTime.formatDate(date), '4 Sep 2026');
        expect(HeliumDateTime.formatDate(date, abbreviateMonth: false, showYear: false), '4 September');
        expect(HeliumDateTime.formatDateForTodos(date), 'Fri, 4 Sep');
        expect(HeliumDateTime.formatDateAndTimeForTodos(date), 'Fri, 4 Sep • 3 PM');
        expect(HeliumDateTime.formatDateWithDay(date), 'Friday, 4 September');
        expect(HeliumDateTime.dateFormatForChartAxis.format(date), '4 Sep');
      });

      test('month and year are order-independent', () async {
        await useOrder(RegionalFormatConstants.dateFormatDayMonthYear);
        expect(HeliumDateTime.formatMonthAndYear(date), 'Sep 2026');
      });
    });

    group('detectDateFormat', () {
      test('detects month-first for the US', () async {
        expect(await HeliumDateTime.detectDateFormat(const Locale('en', 'US')),
            RegionalFormatConstants.dateFormatMonthDayYear);
      });

      test('detects day-first for the UK, Germany, and India', () async {
        for (final locale in [const Locale('en', 'GB'), const Locale('de', 'DE'), const Locale('en', 'IN')]) {
          expect(await HeliumDateTime.detectDateFormat(locale), RegionalFormatConstants.dateFormatDayMonthYear,
              reason: locale.toString());
        }
      });

      test('treats year-first locales such as Japan, Hungary, and Canada as day-first', () async {
        for (final locale in [const Locale('ja', 'JP'), const Locale('hu', 'HU'), const Locale('en', 'CA')]) {
          expect(await HeliumDateTime.detectDateFormat(locale), RegionalFormatConstants.dateFormatDayMonthYear,
              reason: locale.toString());
        }
      });

      test('falls back to month-first for an unknown locale', () async {
        expect(await HeliumDateTime.detectDateFormat(const Locale('xx', 'XX')), RegionalFormatConstants.dateFormatMonthDayYear);
      });
    });

    group('detectWeekStartsOn', () {
      test('detects Sunday for the US, Canada, and Japan', () async {
        for (final locale in [const Locale('en', 'US'), const Locale('en', 'CA'), const Locale('ja', 'JP')]) {
          expect(await HeliumDateTime.detectWeekStartsOn(locale), 0, reason: locale.toString());
        }
      });

      test('detects Monday for the UK, Germany, and the Netherlands', () async {
        for (final locale in [const Locale('en', 'GB'), const Locale('de', 'DE'), const Locale('nl', 'NL')]) {
          expect(await HeliumDateTime.detectWeekStartsOn(locale), 1, reason: locale.toString());
        }
      });

      test('detects Saturday for Saudi Arabia', () async {
        expect(await HeliumDateTime.detectWeekStartsOn(const Locale('ar', 'SA')), 6);
      });

      test('falls back to Sunday for an unknown locale', () async {
        expect(await HeliumDateTime.detectWeekStartsOn(const Locale('xx', 'XX')), RegionalFormatConstants.weekStartsOnSunday);
      });
    });

    group('detectTimeFormat', () {
      test('prefers the OS 24-hour toggle when reported', () async {
        expect(await HeliumDateTime.detectTimeFormat(const Locale('en', 'US'), alwaysUse24HourFormat: true),
            RegionalFormatConstants.timeFormatTwentyFourHour);
        expect(await HeliumDateTime.detectTimeFormat(const Locale('de', 'DE'), alwaysUse24HourFormat: false),
            RegionalFormatConstants.timeFormatTwelveHour);
      });

      test('infers from the locale when the OS reports nothing', () async {
        expect(await HeliumDateTime.detectTimeFormat(const Locale('en', 'US')),
            RegionalFormatConstants.timeFormatTwelveHour);
        expect(await HeliumDateTime.detectTimeFormat(const Locale('de', 'DE')),
            RegionalFormatConstants.timeFormatTwentyFourHour);
        expect(await HeliumDateTime.detectTimeFormat(const Locale('en', 'GB')),
            RegionalFormatConstants.timeFormatTwentyFourHour);
      });

      test('falls back to 12-hour for an unknown locale', () async {
        expect(await HeliumDateTime.detectTimeFormat(const Locale('xx', 'XX')), RegionalFormatConstants.timeFormatTwelveHour);
      });
    });

    group('formatExamples', () {
      test('render each date and time format', () {
        final date = DateTime(2026, 9, 20, 13, 5);
        expect(HeliumDateTime.dateFormatExample(RegionalFormatConstants.dateFormatMonthDayYear, date), 'Sep 20, 2026');
        expect(HeliumDateTime.dateFormatExample(RegionalFormatConstants.dateFormatDayMonthYear, date), '20 Sep 2026');
        expect(HeliumDateTime.timeFormatExample(RegionalFormatConstants.timeFormatTwelveHour, date), '1:05 PM');
        expect(HeliumDateTime.timeFormatExample(RegionalFormatConstants.timeFormatTwentyFourHour, date), '13:05');
      });
    });

    group('dateFormatForChartAxis', () {
      test('formats without a zero-padded day', () {
        final date = DateTime(2025, 8, 4);
        expect(HeliumDateTime.dateFormatForChartAxis.format(date), equals('Aug 4'));
      });
    });

    group('formatForDisplay', () {
      test('formats date in MMM dd, yyyy format', () {
        final date = DateTime(2025, 8, 15);
        expect(HeliumDateTime.formatDate(date), equals('Aug 15, 2025'));
      });

      test('formats January date correctly', () {
        final date = DateTime(2025, 1, 1);
        expect(HeliumDateTime.formatDate(date), equals('Jan 1, 2025'));
      });

      test('formats December date correctly', () {
        final date = DateTime(2025, 12, 31);
        expect(HeliumDateTime.formatDate(date), equals('Dec 31, 2025'));
      });
    });

    group('formatForApi', () {
      test('formats date as ISO date string (YYYY-MM-DD)', () {
        final date = DateTime(2025, 8, 15, 10, 30, 0);
        expect(HeliumDateTime.formatDateForApi(date), equals('2025-08-15'));
      });

      test('pads single digit month', () {
        final date = DateTime(2025, 5, 15);
        expect(HeliumDateTime.formatDateForApi(date), equals('2025-05-15'));
      });

      test('pads single digit day', () {
        final date = DateTime(2025, 10, 5);
        expect(HeliumDateTime.formatDateForApi(date), equals('2025-10-05'));
      });
    });

    group('formatDateAndTimeForApi', () {
      test('returns valid ISO 8601 string with time component', () {
        final location = tz.getLocation('America/New_York');
        final date = DateTime(2025, 8, 15);
        const time = TimeOfDay(hour: 14, minute: 30);

        final result = HeliumDateTime.formatDateAndTimeForApi(
          date,
          time,
          location,
        );

        expect(
          result,
          matches(RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+')),
        );
      });

      test('returns ISO string for date only when time is null', () {
        final location = tz.getLocation('America/New_York');
        final date = DateTime(2025, 8, 15);

        final result = HeliumDateTime.formatDateAndTimeForApi(
          date,
          null,
          location,
        );

        expect(result, contains('2025-08-15'));
      });
    });
  });
}

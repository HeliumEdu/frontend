import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/locale_notifier.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/standalone.dart' as tz;

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('HeliumRecurrence', () {
    late tz.Location amsterdam;
    late tz.Location losAngeles;
    late tz.TZDateTime mondayStart;

    setUp(() {
      amsterdam = tz.getLocation('Europe/Amsterdam');
      losAngeles = tz.getLocation('America/Los_Angeles');
      mondayStart = tz.TZDateTime(amsterdam, 2026, 9, 7, 9);
    });

    group('compose', () {
      test('returns null for a draft that does not repeat', () {
        // WHEN
        final rule = HeliumRecurrence.compose(const RecurrenceDraft(), mondayStart, amsterdam);

        // THEN
        expect(rule, isNull);
      });

      test('emits frequency alone, adding INTERVAL only when it is above 1', () {
        // WHEN
        final daily = HeliumRecurrence.compose(
            const RecurrenceDraft(frequency: RecurrenceFrequency.daily), mondayStart, amsterdam);
        final everyOtherDay = HeliumRecurrence.compose(
            const RecurrenceDraft(frequency: RecurrenceFrequency.daily, interval: 2), mondayStart, amsterdam);

        // THEN
        expect(daily, 'FREQ=DAILY');
        expect(everyOtherDay, 'FREQ=DAILY;INTERVAL=2');
      });

      test('weekly emits weekdays sorted Sunday-first as iCal codes', () {
        // WHEN
        final rule = HeliumRecurrence.compose(
          const RecurrenceDraft(frequency: RecurrenceFrequency.weekly, weekdays: {6, 3, 0, 1}),
          mondayStart,
          amsterdam,
        );

        // THEN
        expect(rule, 'FREQ=WEEKLY;BYDAY=SU,MO,WE,SA');
      });

      test('weekly with no weekdays repeats on the start weekday', () {
        // WHEN
        final rule = HeliumRecurrence.compose(
            const RecurrenceDraft(frequency: RecurrenceFrequency.weekly), mondayStart, amsterdam);

        // THEN
        expect(rule, 'FREQ=WEEKLY;BYDAY=MO');
      });

      test('monthly anchors on the start day, ignoring last day of month before the 29th', () {
        // WHEN
        final rule = HeliumRecurrence.compose(
          const RecurrenceDraft(frequency: RecurrenceFrequency.monthly, lastDayOfMonth: true),
          mondayStart,
          amsterdam,
        );

        // THEN
        expect(rule, 'FREQ=MONTHLY;BYMONTHDAY=7');
      });

      test('monthly on the 31st emits -1 only when last day of month is checked', () {
        // GIVEN
        final start = tz.TZDateTime(amsterdam, 2026, 10, 31, 9);

        // WHEN
        final lastDay = HeliumRecurrence.compose(
            const RecurrenceDraft(frequency: RecurrenceFrequency.monthly, lastDayOfMonth: true), start, amsterdam);
        final thirtyFirst = HeliumRecurrence.compose(
            const RecurrenceDraft(frequency: RecurrenceFrequency.monthly), start, amsterdam);

        // THEN
        expect(lastDay, 'FREQ=MONTHLY;BYMONTHDAY=-1');
        expect(thirtyFirst, 'FREQ=MONTHLY;BYMONTHDAY=31');
      });

      test('yearly anchors on the start month and day', () {
        // WHEN
        final rule = HeliumRecurrence.compose(
            const RecurrenceDraft(frequency: RecurrenceFrequency.yearly), mondayStart, amsterdam);

        // THEN
        expect(rule, 'FREQ=YEARLY;BYMONTH=9;BYMONTHDAY=7');
      });

      test('ending after a count emits COUNT', () {
        // WHEN
        final rule = HeliumRecurrence.compose(
          const RecurrenceDraft(frequency: RecurrenceFrequency.weekly, weekdays: {1}, end: RecurrenceEnd.afterCount, count: 10),
          mondayStart,
          amsterdam,
        );

        // THEN
        expect(rule, 'FREQ=WEEKLY;BYDAY=MO;COUNT=10');
      });

      test('ending on a date emits the end of that local day in UTC, per time zone', () {
        // GIVEN
        final draft = RecurrenceDraft(
          frequency: RecurrenceFrequency.daily,
          end: RecurrenceEnd.onDate,
          until: DateTime(2026, 12, 18),
        );

        // WHEN
        final inAmsterdam = HeliumRecurrence.compose(draft, mondayStart, amsterdam);
        final inLosAngeles = HeliumRecurrence.compose(
            draft, tz.TZDateTime(losAngeles, 2026, 9, 7, 9), losAngeles);

        // THEN
        expect(inAmsterdam, 'FREQ=DAILY;UNTIL=20261218T225959Z');
        expect(inLosAngeles, 'FREQ=DAILY;UNTIL=20261219T075959Z');
      });
    });

    group('parse', () {
      test('round-trips every draft the picker composes', () {
        // GIVEN
        final drafts = [
          const RecurrenceDraft(frequency: RecurrenceFrequency.daily),
          const RecurrenceDraft(frequency: RecurrenceFrequency.daily, interval: 3),
          const RecurrenceDraft(frequency: RecurrenceFrequency.weekly, weekdays: {1, 3, 5}),
          const RecurrenceDraft(frequency: RecurrenceFrequency.weekly, interval: 2, weekdays: {1}),
          const RecurrenceDraft(frequency: RecurrenceFrequency.monthly),
          const RecurrenceDraft(frequency: RecurrenceFrequency.yearly),
          const RecurrenceDraft(
              frequency: RecurrenceFrequency.weekly, weekdays: {1}, end: RecurrenceEnd.afterCount, count: 12),
          RecurrenceDraft(
              frequency: RecurrenceFrequency.weekly,
              weekdays: const {1},
              end: RecurrenceEnd.onDate,
              until: DateTime(2026, 12, 18)),
        ];

        for (final location in [amsterdam, losAngeles]) {
          final start = tz.TZDateTime(location, 2026, 9, 7, 9);
          for (final draft in drafts) {
            // WHEN
            final rule = HeliumRecurrence.compose(draft, start, location);
            final parsed = HeliumRecurrence.parse(rule, start, location);

            // THEN
            expect(parsed, draft, reason: '$rule in ${location.name}');
          }
        }
      });

      test('round-trips last day of month from a start on the 31st', () {
        // GIVEN
        final start = tz.TZDateTime(losAngeles, 2026, 10, 31, 9);
        const draft = RecurrenceDraft(frequency: RecurrenceFrequency.monthly, lastDayOfMonth: true);

        // WHEN
        final parsed = HeliumRecurrence.parse(HeliumRecurrence.compose(draft, start, losAngeles), start, losAngeles);

        // THEN
        expect(parsed, draft);
      });

      test('returns a non-repeating draft for no rule', () {
        // WHEN
        final fromNull = HeliumRecurrence.parse(null, mondayStart, amsterdam);
        final fromEmpty = HeliumRecurrence.parse('', mondayStart, amsterdam);

        // THEN
        expect(fromNull, const RecurrenceDraft());
        expect(fromEmpty, const RecurrenceDraft());
      });

      test('accepts the forms the API normalizes rules into', () {
        // WHEN
        final weekly = HeliumRecurrence.parse('FREQ=WEEKLY', mondayStart, amsterdam);
        final prefixed = HeliumRecurrence.parse('RRULE:FREQ=MONTHLY;BYMONTHDAY=7', mondayStart, amsterdam);
        final monthlyBare = HeliumRecurrence.parse('FREQ=MONTHLY', mondayStart, amsterdam);
        final lowercase = HeliumRecurrence.parse('freq=yearly;bymonth=9;bymonthday=7', mondayStart, amsterdam);

        // THEN
        expect(weekly, const RecurrenceDraft(frequency: RecurrenceFrequency.weekly, weekdays: {1}),
            reason: 'a weekly rule without BYDAY repeats on the start weekday');
        expect(prefixed, const RecurrenceDraft(frequency: RecurrenceFrequency.monthly));
        expect(monthlyBare, const RecurrenceDraft(frequency: RecurrenceFrequency.monthly));
        expect(lowercase, const RecurrenceDraft(frequency: RecurrenceFrequency.yearly));
      });

      test('returns null for rules the picker cannot represent', () {
        // GIVEN
        const unrepresentable = [
          'FREQ=MONTHLY;BYDAY=TU;BYSETPOS=2',
          'FREQ=WEEKLY;BYDAY=2TU',
          'FREQ=MONTHLY;BYMONTHDAY=1,15',
          'FREQ=MONTHLY;BYMONTHDAY=8',
          'FREQ=YEARLY;BYMONTH=10;BYMONTHDAY=7',
          'FREQ=DAILY;BYDAY=MO',
          'FREQ=WEEKLY;COUNT=3;UNTIL=20261218',
          'FREQ=HOURLY',
          'FREQ=WEEKLY;UNTIL=tomorrow',
          'FREQ=WEEKLY;INTERVAL=0',
          'FREQ=WEEKLY;WKST=MO',
        ];

        for (final rule in unrepresentable) {
          // WHEN
          final parsed = HeliumRecurrence.parse(rule, mondayStart, amsterdam);

          // THEN
          expect(parsed, isNull, reason: rule);
        }
      });

      test('reads a UTC UNTIL as the local date it falls on in each time zone', () {
        // GIVEN
        const rule = 'FREQ=DAILY;UNTIL=20261219T065959Z';

        // WHEN
        final inLosAngeles = HeliumRecurrence.parse(rule, tz.TZDateTime(losAngeles, 2026, 9, 7, 9), losAngeles);
        final inAmsterdam = HeliumRecurrence.parse(rule, mondayStart, amsterdam);

        // THEN
        expect(inLosAngeles?.until, DateTime(2026, 12, 18));
        expect(inAmsterdam?.until, DateTime(2026, 12, 19));
        expect(inAmsterdam?.end, RecurrenceEnd.onDate);
      });

      test('reads a naive or date-only UNTIL as that date', () {
        // WHEN
        final naive = HeliumRecurrence.parse('FREQ=DAILY;UNTIL=20261218T235959', mondayStart, amsterdam);
        final dateOnly = HeliumRecurrence.parse('FREQ=DAILY;UNTIL=20261218', mondayStart, losAngeles);

        // THEN
        expect(naive?.until, DateTime(2026, 12, 18));
        expect(dateOnly?.until, DateTime(2026, 12, 18));
      });

      test('reads an UNTIL at the end of the class end date in each time zone as the default end', () {
        // GIVEN
        final classEndDate = DateTime(2026, 12, 18);

        // WHEN
        final inLosAngeles = HeliumRecurrence.parse(
          'FREQ=WEEKLY;BYDAY=MO;UNTIL=20261219T075959Z',
          tz.TZDateTime(losAngeles, 2026, 9, 7, 9),
          losAngeles,
          classEndDate: classEndDate,
        );
        final inAmsterdam = HeliumRecurrence.parse(
          'FREQ=WEEKLY;BYDAY=MO;UNTIL=20261218T225959Z',
          mondayStart,
          amsterdam,
          classEndDate: classEndDate,
        );

        // THEN
        expect(inLosAngeles?.end, RecurrenceEnd.defaultEnd);
        expect(inLosAngeles?.until, isNull);
        expect(inAmsterdam?.end, RecurrenceEnd.defaultEnd);
        expect(inAmsterdam?.until, isNull);
      });

      test('reads an UNTIL other than the end of the class end date as an end date', () {
        // GIVEN
        final classEndDate = DateTime(2026, 12, 18);

        // WHEN
        final otherZonesClassEnd = HeliumRecurrence.parse(
          'FREQ=WEEKLY;BYDAY=MO;UNTIL=20261219T075959Z',
          mondayStart,
          amsterdam,
          classEndDate: classEndDate,
        );
        final dayBeforeClassEnd = HeliumRecurrence.parse(
          'FREQ=WEEKLY;BYDAY=MO;UNTIL=20261218T075959Z',
          tz.TZDateTime(losAngeles, 2026, 9, 7, 9),
          losAngeles,
          classEndDate: classEndDate,
        );

        // THEN
        expect(otherZonesClassEnd?.end, RecurrenceEnd.onDate);
        expect(otherZonesClassEnd?.until, DateTime(2026, 12, 19));
        expect(dayBeforeClassEnd?.end, RecurrenceEnd.onDate);
        expect(dayBeforeClassEnd?.until, DateTime(2026, 12, 17));
      });

      test('round-trips a default-end assignment repeat bounded to its class end date', () {
        // GIVEN
        final classEndDate = DateTime(2026, 12, 18);
        final draft = HeliumRecurrence.defaultFor(RecurrenceFrequency.weekly, mondayStart);
        final rule = HeliumRecurrence.compose(
          draft.copyWith(end: RecurrenceEnd.onDate, until: classEndDate),
          mondayStart,
          amsterdam,
        );

        // WHEN
        final parsed = HeliumRecurrence.parse(rule, mondayStart, amsterdam, classEndDate: classEndDate);

        // THEN
        expect(parsed, draft);
      });
    });

    group('describe', () {
      Future<void> useOrder(int dateFormat) => LocaleNotifier().update(
            weekStartsOn: 0,
            dateFormat: dateFormat,
            timeFormat: 0,
            numberFormat: 0,
            language: 'en',
            timeZone: 'UTC',
          );

      tearDown(() => useOrder(RegionalFormatConstants.dateFormatMonthDayYear));

      String describe(String rule) => HeliumRecurrence.describe(rule, mondayStart, amsterdam);

      test('describes a monthly weekday position in its ordinal and BYSETPOS forms alike', () {
        // WHEN
        final ordinal = describe('FREQ=MONTHLY;BYDAY=2TU;COUNT=6');
        final setPos = describe('FREQ=MONTHLY;BYDAY=TU;COUNT=6;BYSETPOS=2');

        // THEN
        expect(ordinal, 'Repeats monthly on the 2nd Tuesday, 6 times');
        expect(setPos, ordinal);
      });

      test('describes every supported weekday position', () {
        // WHEN/THEN
        expect(describe('FREQ=MONTHLY;BYDAY=1MO'), 'Repeats monthly on the 1st Monday');
        expect(describe('FREQ=MONTHLY;BYDAY=+3WE'), 'Repeats monthly on the 3rd Wednesday');
        expect(describe('FREQ=MONTHLY;BYDAY=4TH'), 'Repeats monthly on the 4th Thursday');
        expect(describe('FREQ=MONTHLY;BYDAY=-1FR'), 'Repeats monthly on the last Friday');
        expect(describe('FREQ=MONTHLY;BYDAY=SA;BYSETPOS=-2'), 'Repeats monthly on the second-to-last Saturday');
      });

      test('describes an interval and an end date in the user\'s zone', () {
        // WHEN
        final description = describe('FREQ=MONTHLY;INTERVAL=2;BYDAY=-1FR;UNTIL=20270528T215959Z');

        // THEN
        expect(description, 'Repeats every 2 months on the last Friday, until May 28, 2027');
      });

      test('reads a UTC end date on the user\'s calendar day', () {
        // WHEN
        final amsterdamEnd = HeliumRecurrence.describe(
            'FREQ=MONTHLY;BYDAY=2TU;UNTIL=20270101T030000Z', mondayStart, amsterdam);
        final losAngelesEnd = HeliumRecurrence.describe(
            'FREQ=MONTHLY;BYDAY=2TU;UNTIL=20270101T030000Z', mondayStart, losAngeles);

        // THEN
        expect(amsterdamEnd, 'Repeats monthly on the 2nd Tuesday, until Jan 1, 2027');
        expect(losAngelesEnd, 'Repeats monthly on the 2nd Tuesday, until Dec 31, 2026');
      });

      test('describes a yearly repeat on a weekday position of a month', () {
        // WHEN
        final description = describe('FREQ=YEARLY;BYMONTH=11;BYDAY=4TH');

        // THEN
        expect(description, 'Repeats yearly on the 4th Thursday of November');
      });

      test('describes a yearly repeat in another month, on the start\'s day unless one is given', () {
        // WHEN/THEN
        expect(describe('FREQ=YEARLY;BYMONTH=3'), 'Repeats yearly on March 7');
        expect(describe('FREQ=YEARLY;INTERVAL=3;BYMONTH=3;BYMONTHDAY=15'), 'Repeats every 3 years on March 15');
        expect(describe('FREQ=YEARLY;BYMONTH=2;BYMONTHDAY=29'), 'Repeats yearly on February 29');
        expect(describe('FREQ=YEARLY;BYMONTH=2;BYMONTHDAY=-1'), 'Repeats yearly on the last day of February');
      });

      test('describes a monthly day other than the start\'s, and the last day', () {
        // WHEN/THEN
        expect(describe('FREQ=MONTHLY;BYMONTHDAY=15'), 'Repeats monthly on day 15');
        expect(describe('FREQ=MONTHLY;BYMONTHDAY=-1;COUNT=3;UNTIL=20261231T225959Z'),
            'Repeats monthly on the last day, up to 3 times until Dec 31, 2026');
      });

      test('describes a weekday list from the user\'s week start, without repeats', () {
        // WHEN
        final sundayFirst = describe('FREQ=WEEKLY;INTERVAL=2;BYDAY=SA,SU,SA;COUNT=1');
        final mondayFirst = HeliumRecurrence.describe(
            'FREQ=WEEKLY;INTERVAL=2;BYDAY=SA,SU,SA;COUNT=1', mondayStart, amsterdam, weekStartsOn: 1);
        final saturdayFirst = HeliumRecurrence.describe(
            'FREQ=DAILY;BYDAY=FR,MO,WE,SA', mondayStart, amsterdam, weekStartsOn: 6);

        // THEN
        expect(sundayFirst, 'Repeats every 2 weeks on Sun, Sat, once');
        expect(mondayFirst, 'Repeats every 2 weeks on Sat, Sun, once');
        expect(saturdayFirst, 'Repeats daily on Sat, Mon, Wed, Fri');
      });

      test('describes a repeat with both a count and an end date', () {
        // WHEN
        final description = describe('FREQ=WEEKLY;COUNT=5;UNTIL=20261231T225959Z');

        // THEN
        expect(description, 'Repeats weekly, up to 5 times until Dec 31, 2026');
      });

      test('reads an RRULE prefix and any letter case', () {
        // WHEN
        final description = describe('rrule:freq=monthly;byday=2tu');

        // THEN
        expect(description, 'Repeats monthly on the 2nd Tuesday');
      });

      test('follows the regional date order', () async {
        // GIVEN
        await useOrder(RegionalFormatConstants.dateFormatDayMonthYear);

        // WHEN
        final description = describe('FREQ=YEARLY;BYMONTH=3;BYMONTHDAY=15;UNTIL=20290315T225959Z');

        // THEN
        expect(description, 'Repeats yearly on 15 March, until 15 Mar 2029');
      });

      test('falls back to a custom schedule for any part it cannot put into words', () {
        // GIVEN
        const rules = [
          '',
          'BYDAY=2TU',
          'FREQ=HOURLY',
          'FREQ=MONTHLY;INTERVAL=0;BYDAY=2TU',
          'FREQ=MONTHLY;INTERVAL=x;BYDAY=2TU',
          'FREQ=MONTHLY;BYDAY=2TU;BYWEEKNO=20',
          'FREQ=MONTHLY;BYDAY=2TU;BYMONTHDAY=15',
          'FREQ=MONTHLY;BYSETPOS=2',
          'FREQ=MONTHLY;BYDAY=TU',
          'FREQ=MONTHLY;BYDAY=5TU',
          'FREQ=MONTHLY;BYDAY=2TU;BYSETPOS=2',
          'FREQ=MONTHLY;BYDAY=2XX',
          'FREQ=MONTHLY;BYDAY=TU,TH;BYSETPOS=2',
          'FREQ=MONTHLY;BYMONTH=3',
          'FREQ=MONTHLY;BYMONTH=3;BYDAY=2TU',
          'FREQ=MONTHLY;BYMONTHDAY=32',
          'FREQ=MONTHLY;BYMONTHDAY=0',
          'FREQ=WEEKLY;BYDAY=2TU',
          'FREQ=WEEKLY;BYDAY=TU;BYSETPOS=2',
          'FREQ=WEEKLY;BYDAY=TU,XX',
          'FREQ=WEEKLY;BYDAY=TU;BYMONTH=3',
          'FREQ=YEARLY;BYDAY=4TH',
          'FREQ=YEARLY;BYMONTH=13',
          'FREQ=YEARLY;BYMONTH=13;BYDAY=4TH',
          'FREQ=YEARLY;BYMONTH=2;BYMONTHDAY=30',
          'FREQ=YEARLY;BYMONTH=4;BYMONTHDAY=0',
          'FREQ=MONTHLY;BYDAY=2TU;COUNT=0',
          'FREQ=MONTHLY;BYDAY=2TU;COUNT=many',
          'FREQ=MONTHLY;BYDAY=2TU;UNTIL=soon',
        ];

        // WHEN
        final descriptions = {for (final rule in rules) rule: describe(rule)};

        // THEN
        for (final entry in descriptions.entries) {
          expect(entry.value, 'Repeats on a custom schedule', reason: entry.key);
        }
      });
    });

    test('offers last day of month only for a start on the 29th or later', () {
      // WHEN/THEN
      expect(HeliumRecurrence.offersLastDayOfMonth(DateTime(2026, 1, 28)), isFalse);
      expect(HeliumRecurrence.offersLastDayOfMonth(DateTime(2026, 1, 29)), isTrue);
      expect(HeliumRecurrence.offersLastDayOfMonth(DateTime(2026, 1, 31)), isTrue);
    });

    test('defaultFor repeats once per period on the start weekday with no end', () {
      // WHEN
      final draft = HeliumRecurrence.defaultFor(RecurrenceFrequency.weekly, mondayStart);

      // THEN
      expect(draft, const RecurrenceDraft(frequency: RecurrenceFrequency.weekly, weekdays: {1}));
    });
  });

  group('RecurrenceDraft', () {
    test('is equal regardless of weekday order, with a matching hashCode', () {
      // GIVEN
      const first = RecurrenceDraft(frequency: RecurrenceFrequency.weekly, weekdays: {1, 3});
      const second = RecurrenceDraft(frequency: RecurrenceFrequency.weekly, weekdays: {3, 1});

      // THEN
      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('differs when any field differs', () {
      // GIVEN
      const base = RecurrenceDraft(frequency: RecurrenceFrequency.weekly, weekdays: {1});

      // THEN
      expect(base, isNot(base.copyWith(interval: 2)));
      expect(base, isNot(base.copyWith(weekdays: {1, 2})));
      expect(base, isNot(base.copyWith(end: RecurrenceEnd.afterCount, count: 3)));
      expect(base, isNot(base.copyWith(frequency: RecurrenceFrequency.daily)));
    });
  });
}

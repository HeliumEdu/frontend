import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/standalone.dart' as tz;

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('DateTimeHelpers', () {
    group('dayRangeIn', () {
      for (final zoneName in ['Europe/Amsterdam', 'America/Los_Angeles']) {
        test('reads only the dates of month-cell times ($zoneName)', () {
          // GIVEN
          final zone = tz.getLocation(zoneName);
          final monthCellStart = DateTime(2026, 11, 10, 0, 2);
          final monthCellEnd = DateTime(2026, 11, 12, 23, 59, 59);

          // WHEN
          final (start, end) = HeliumDateTime.dayRangeIn(monthCellStart, monthCellEnd, zone);

          // THEN
          expect(start, tz.TZDateTime(zone, 2026, 11, 10));
          expect(end, tz.TZDateTime(zone, 2026, 11, 13));
        });
      }

      test('spans whole days across a fall-back day', () {
        // GIVEN
        final amsterdam = tz.getLocation('Europe/Amsterdam');

        // WHEN
        final (start, endExclusive) = HeliumDateTime.dayRangeIn(
          DateTime(2026, 10, 24),
          DateTime(2026, 10, 25),
          amsterdam,
        );

        // THEN
        expect(start, tz.TZDateTime(amsterdam, 2026, 10, 24));
        expect(endExclusive, tz.TZDateTime(amsterdam, 2026, 10, 26));
        expect(endExclusive.difference(start).inHours, 49);
      });

      test('spans whole days on days without a transition', () {
        // GIVEN
        final la = tz.getLocation('America/Los_Angeles');

        // WHEN
        final (start, endExclusive) = HeliumDateTime.dayRangeIn(
          DateTime(2026, 6, 10),
          DateTime(2026, 6, 10),
          la,
        );

        // THEN
        expect(start, tz.TZDateTime(la, 2026, 6, 10));
        expect(endExclusive, tz.TZDateTime(la, 2026, 6, 11));
      });
    });

    group('toLocal - timezone conversion', () {
      test('converts UTC to America/New_York (UTC-5 standard, UTC-4 DST)', () {
        final nyTz = tz.getLocation('America/New_York');
        final utcWinter = DateTime.utc(2025, 1, 15, 12, 0, 0);
        final localWinter = HeliumDateTime.toLocal(utcWinter, nyTz);
        expect(localWinter.hour, equals(7)); // 12:00 UTC = 7:00 EST

        final utcSummer = DateTime.utc(2025, 7, 15, 12, 0, 0);
        final localSummer = HeliumDateTime.toLocal(utcSummer, nyTz);
        expect(localSummer.hour, equals(8)); // 12:00 UTC = 8:00 EDT
      });

      test('converts UTC to Europe/London (UTC+0 standard, UTC+1 DST)', () {
        final londonTz = tz.getLocation('Europe/London');
        final utcWinter = DateTime.utc(2025, 1, 15, 12, 0, 0);
        final localWinter = HeliumDateTime.toLocal(utcWinter, londonTz);
        expect(localWinter.hour, equals(12)); // 12:00 UTC = 12:00 GMT

        final utcSummer = DateTime.utc(2025, 7, 15, 12, 0, 0);
        final localSummer = HeliumDateTime.toLocal(utcSummer, londonTz);
        expect(localSummer.hour, equals(13)); // 12:00 UTC = 13:00 BST
      });

      test('converts UTC to Asia/Tokyo (UTC+9, no DST)', () {
        final tokyoTz = tz.getLocation('Asia/Tokyo');
        final utc = DateTime.utc(2025, 6, 15, 12, 0, 0);
        final local = HeliumDateTime.toLocal(utc, tokyoTz);
        expect(local.hour, equals(21)); // 12:00 UTC = 21:00 JST
      });

      test('handles UTC midnight boundary - date changes in positive offset', () {
        final tokyoTz = tz.getLocation('Asia/Tokyo');
        final utcMidnight = DateTime.utc(2025, 6, 15, 0, 0, 0);
        final local = HeliumDateTime.toLocal(utcMidnight, tokyoTz);

        expect(local.day, equals(15)); // Still June 15
        expect(local.hour, equals(9)); // 00:00 UTC = 09:00 JST
      });

      test('handles UTC midnight boundary - date changes in negative offset', () {
        final laTz = tz.getLocation('America/Los_Angeles');
        final utcEarlyMorning = DateTime.utc(2025, 1, 15, 3, 0, 0);
        final local = HeliumDateTime.toLocal(utcEarlyMorning, laTz);

        expect(local.day, equals(14)); // Should be January 14
        expect(local.hour, equals(19)); // 03:00 UTC = 19:00 PST previous day
      });

      test('handles extreme positive timezone (Pacific/Kiritimati UTC+14)', () {
        final kiritimatiTz = tz.getLocation('Pacific/Kiritimati');
        final utc = DateTime.utc(2025, 6, 15, 10, 0, 0);
        final local = HeliumDateTime.toLocal(utc, kiritimatiTz);

        expect(local.day, equals(16)); // Should be next day
        expect(local.hour, equals(0)); // 10:00 UTC = 00:00+14 next day
      });

      test('handles extreme negative timezone (Pacific/Midway UTC-11)', () {
        final midwayTz = tz.getLocation('Pacific/Midway');
        final utc = DateTime.utc(2025, 6, 15, 5, 0, 0);
        final local = HeliumDateTime.toLocal(utc, midwayTz);

        expect(local.day, equals(14)); // Should be previous day
        expect(local.hour, equals(18)); // 05:00 UTC = 18:00-11 previous day
      });

      test('handles DST spring forward transition (America/New_York)', () {
        final nyTz = tz.getLocation('America/New_York');

        final beforeDst = DateTime.utc(2025, 3, 9, 6, 0, 0);
        final localBefore = HeliumDateTime.toLocal(beforeDst, nyTz);
        expect(localBefore.hour, equals(1)); // 1:00 AM EST

        final afterDst = DateTime.utc(2025, 3, 9, 8, 0, 0);
        final localAfter = HeliumDateTime.toLocal(afterDst, nyTz);
        expect(localAfter.hour, equals(4)); // 4:00 AM EDT
      });

      test('handles DST fall back transition (America/New_York)', () {
        final nyTz = tz.getLocation('America/New_York');

        final beforeEnd = DateTime.utc(2025, 11, 2, 5, 0, 0);
        final localBefore = HeliumDateTime.toLocal(beforeEnd, nyTz);
        expect(localBefore.hour, equals(1)); // 1:00 AM EDT

        final afterEnd = DateTime.utc(2025, 11, 2, 7, 0, 0);
        final localAfter = HeliumDateTime.toLocal(afterEnd, nyTz);
        expect(localAfter.hour, equals(2)); // 2:00 AM EST
      });

      test('handles fractional hour timezone (Asia/Kolkata UTC+5:30)', () {
        final kolkataTz = tz.getLocation('Asia/Kolkata');
        final utc = DateTime.utc(2025, 6, 15, 12, 0, 0);
        final local = HeliumDateTime.toLocal(utc, kolkataTz);

        expect(local.hour, equals(17)); // 12:00 UTC + 5:30 = 17:30 IST
        expect(local.minute, equals(30));
      });

      test('handles quarter-hour timezone (Asia/Kathmandu UTC+5:45)', () {
        final kathmanduTz = tz.getLocation('Asia/Kathmandu');
        final utc = DateTime.utc(2025, 6, 15, 12, 0, 0);
        final local = HeliumDateTime.toLocal(utc, kathmanduTz);

        expect(local.hour, equals(17)); // 12:00 UTC + 5:45 = 17:45 NPT
        expect(local.minute, equals(45));
      });

      test('preserves microseconds through conversion', () {
        final nyTz = tz.getLocation('America/New_York');
        final utc = DateTime.utc(2025, 6, 15, 12, 30, 45, 123, 456);
        final local = HeliumDateTime.toLocal(utc, nyTz);

        expect(local.second, equals(45));
        expect(local.millisecond, equals(123));
        expect(local.microsecond, equals(456));
      });

      test('year boundary - UTC midnight Dec 31 in positive offset', () {
        final tokyoTz = tz.getLocation('Asia/Tokyo');
        final utcNewYearsEve = DateTime.utc(2025, 12, 31, 0, 0, 0);
        final local = HeliumDateTime.toLocal(utcNewYearsEve, tokyoTz);

        expect(local.year, equals(2025)); // Still Dec 31 in Tokyo
        expect(local.month, equals(12));
        expect(local.day, equals(31));
        expect(local.hour, equals(9)); // 9:00 AM Dec 31 in Tokyo
      });

      test('year boundary - UTC 23:00 Dec 31 in positive offset crosses to new year', () {
        final tokyoTz = tz.getLocation('Asia/Tokyo');
        final utcLateNewYearsEve = DateTime.utc(2025, 12, 31, 23, 0, 0);
        final local = HeliumDateTime.toLocal(utcLateNewYearsEve, tokyoTz);

        expect(local.year, equals(2026)); // New Year in Tokyo
        expect(local.month, equals(1));
        expect(local.day, equals(1));
        expect(local.hour, equals(8)); // 8:00 AM Jan 1 in Tokyo
      });
    });
  });

  group('unresolved UTC instants', () {
    final storedInstant = DateTime.parse('2025-09-03T22:00:00Z');

    test('midnightIn resolves before truncating', () {
      final amsterdam = tz.getLocation('Europe/Amsterdam');
      final losAngeles = tz.getLocation('America/Los_Angeles');
      expect(HeliumDateTime.midnightIn(storedInstant, amsterdam),
          tz.TZDateTime(amsterdam, 2025, 9, 4));
      expect(
        HeliumDateTime.midnightIn(
            DateTime.parse('2025-01-15T08:00:00Z'), losAngeles),
        tz.TZDateTime(losAngeles, 2025, 1, 15),
      );
    });

    test('wallClockIn reads a naive value as already in the zone', () {
      final amsterdam = tz.getLocation('Europe/Amsterdam');
      expect(
        HeliumDateTime.wallClockIn(DateTime(2025, 9, 18, 9, 0), amsterdam),
        tz.TZDateTime(amsterdam, 2025, 9, 18, 9, 0),
      );
      expect(
        HeliumDateTime.wallClockIn(storedInstant, amsterdam),
        tz.TZDateTime(amsterdam, 2025, 9, 4),
      );
    });

  });
}

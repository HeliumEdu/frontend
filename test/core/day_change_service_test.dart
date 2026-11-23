import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/day_change_service.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('DayChangeService.nextDayStart', () {
    test(
      'without an account time zone, the next day starts at device midnight',
      () {
        // GIVEN
        final now = DateTime(2026, 11, 22, 21, 30);

        // WHEN
        final next = DayChangeService.nextDayStart(now, null);

        // THEN
        expect(next, DateTime(2026, 11, 23));
      },
    );

    test('the next day starts at account midnight when it comes first', () {
      // GIVEN
      final kiritimati = tz.getLocation('Pacific/Kiritimati');
      final now = _deviceTime(tz.TZDateTime(kiritimati, 2026, 11, 22, 23, 30));

      // WHEN
      final next = DayChangeService.nextDayStart(now, kiritimati);

      // THEN
      expect(
        next.isAtSameMomentAs(DateTime.utc(2026, 11, 22, 10)),
        isTrue,
        reason: 'No device zone is past 23:30 when UTC+14 is',
      );
    });

    test('on a 25-hour day, the next day starts at the wall-clock midnight', () {
      // GIVEN
      final amsterdam = tz.getLocation('Europe/Amsterdam');
      final losAngeles = tz.getLocation('America/Los_Angeles');
      final amsterdamNow = _deviceTime(
        tz.TZDateTime(amsterdam, 2026, 10, 25, 23, 30),
      );
      final losAngelesNow = _deviceTime(
        tz.TZDateTime(losAngeles, 2026, 11, 1, 23, 30),
      );

      // WHEN
      final amsterdamNext = DayChangeService.nextDayStart(
        amsterdamNow,
        amsterdam,
      );
      final losAngelesNext = DayChangeService.nextDayStart(
        losAngelesNow,
        losAngeles,
      );

      // THEN
      expect(
        amsterdamNext.isAtSameMomentAs(DateTime.utc(2026, 10, 25, 23)),
        isTrue,
        reason:
            'A 24-hour step from 25 Oct midnight would land on 23:00 the same day',
      );
      expect(
        losAngelesNext.isAtSameMomentAs(DateTime.utc(2026, 11, 2, 8)),
        isTrue,
      );
    });
  });
}

DateTime _deviceTime(DateTime instant) =>
    DateTime.fromMillisecondsSinceEpoch(instant.millisecondsSinceEpoch);

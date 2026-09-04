import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/utils/time_zone_aliases.dart';
import 'package:heliumapp/utils/time_zone_constants.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/standalone.dart' as tz;

void main() {
  tz_data.initializeTimeZones();

  group('HeliumDateTime.resolveTimeZone', () {
    test('canonical identifiers pass through untouched', () {
      expect(HeliumDateTime.resolveTimeZone('Europe/Amsterdam'), 'Europe/Amsterdam');
      expect(HeliumDateTime.resolveTimeZone('America/Los_Angeles'), 'America/Los_Angeles');
      expect(HeliumDateTime.resolveTimeZone('UTC'), 'UTC');
    });

    test('legacy aliases resolve to their canonical zone, not UTC', () {
      expect(HeliumDateTime.resolveTimeZone('Asia/Calcutta'), 'Asia/Kolkata');
      expect(HeliumDateTime.resolveTimeZone('Asia/Saigon'), 'Asia/Ho_Chi_Minh');
      expect(HeliumDateTime.resolveTimeZone('Asia/Rangoon'), 'Asia/Yangon');
      expect(HeliumDateTime.resolveTimeZone('Europe/Kiev'), 'Europe/Kyiv');
      expect(
        HeliumDateTime.resolveTimeZone('America/Buenos_Aires'),
        'America/Argentina/Buenos_Aires',
      );
    });

    test('an unmappable identifier still falls back to UTC', () {
      expect(HeliumDateTime.resolveTimeZone('Not/AZone'), 'UTC');
      expect(HeliumDateTime.resolveTimeZone(''), 'UTC');
    });

    test('every resolved value is one the API will accept', () {
      for (final alias in TimeZoneAliases.all.keys) {
        expect(
          TimeZoneConstants.all.contains(HeliumDateTime.resolveTimeZone(alias)),
          isTrue,
          reason: '$alias resolved outside the allow-list',
        );
      }
    });

    test('every alias preserves the real UTC offset', () {
      for (final entry in TimeZoneAliases.all.entries) {
        final probe = DateTime.utc(2025, 7, 15);
        expect(
          tz.TZDateTime.from(probe, tz.getLocation(entry.value)).timeZoneOffset,
          tz.TZDateTime.from(probe, tz.getLocation(entry.key)).timeZoneOffset,
          reason: '${entry.key} -> ${entry.value} changes the offset',
        );
      }
    });
  });
}

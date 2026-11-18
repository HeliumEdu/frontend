import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/standalone.dart' as tz;

import '../mocks/mock_models.dart';

void main() {
  tz_data.initializeTimeZones();

  group('PlannerHelper', () {
    group('droppedTimeRange', () {
      test(
        'a timed item dropped in week view starts at the rounded drop time and keeps its length',
        () {
          // GIVEN
          final la = tz.getLocation('America/Los_Angeles');
          final homework = MockModels.createHomework();
          final currentStart = tz.TZDateTime(la, 2025, 3, 3, 9);
          final currentEnd = tz.TZDateTime(la, 2025, 3, 3, 10, 30);

          // WHEN
          final (start, end) = PlannerHelper.droppedTimeRange(
            plannerItem: homework,
            currentStart: currentStart,
            currentEnd: currentEnd,
            dropDetails: AppointmentDragEndDetails(
              homework,
              null,
              null,
              DateTime(2025, 3, 5, 14, 20),
            ),
            userSettings: MockModels.createUserSettings(
              timeZone: 'America/Los_Angeles',
            ),
            currentView: PlannerView.week,
          );

          // THEN
          expect(
            start,
            tz.TZDateTime(la, 2025, 3, 5, 14, 30),
            reason: '14:20 rounds to the nearest half hour',
          );
          expect(end.difference(start), const Duration(minutes: 90));
        },
      );

      test(
        'a timed item dropped in month view keeps its wall-clock time across a DST change',
        () {
          // GIVEN
          final amsterdam = tz.getLocation('Europe/Amsterdam');
          final homework = MockModels.createHomework();
          final currentStart = tz.TZDateTime(amsterdam, 2025, 3, 28, 9);
          final currentEnd = tz.TZDateTime(amsterdam, 2025, 3, 28, 10);

          // WHEN
          final (start, end) = PlannerHelper.droppedTimeRange(
            plannerItem: homework,
            currentStart: currentStart,
            currentEnd: currentEnd,
            dropDetails: AppointmentDragEndDetails(
              homework,
              null,
              null,
              DateTime(2025, 3, 31),
            ),
            userSettings: MockModels.createUserSettings(
              timeZone: 'Europe/Amsterdam',
            ),
            currentView: PlannerView.month,
          );

          // THEN
          expect(
            start,
            tz.TZDateTime(amsterdam, 2025, 3, 31, 9),
            reason:
                'month view moves the date only; 9:00 stays 9:00 after the switch to summer time',
          );
          expect(start.toUtc(), DateTime.utc(2025, 3, 31, 7));
          expect(end.difference(start), const Duration(hours: 1));
        },
      );
    });

    group('resizedTimeRange', () {
      test(
        'a timed resize rounds each end to the half hour, rolling minute 60 into the next hour',
        () {
          // GIVEN
          final la = tz.getLocation('America/Los_Angeles');
          final homework = MockModels.createHomework();

          // WHEN
          final (start, end) = PlannerHelper.resizedTimeRange(
            plannerItem: homework,
            resizeDetails: AppointmentResizeEndDetails(
              homework,
              null,
              DateTime(2025, 3, 5, 9, 10),
              DateTime(2025, 3, 5, 10, 50),
            ),
            userSettings: MockModels.createUserSettings(
              timeZone: 'America/Los_Angeles',
            ),
          );

          // THEN
          expect(start, tz.TZDateTime(la, 2025, 3, 5, 9));
          expect(end, tz.TZDateTime(la, 2025, 3, 5, 11));
        },
      );
    });

    group('occurrenceWhenLabel', () {
      final amsterdamSettings = MockModels.createUserSettings(
        timeZone: 'Europe/Amsterdam',
      );

      test('a timed occurrence shows its date and time', () {
        // GIVEN
        final amsterdam = tz.getLocation('Europe/Amsterdam');
        final occurrence = MockModels.createHomework(
          start: DateTime.utc(2025, 9, 10, 12),
        );

        // WHEN
        final label = PlannerHelper.occurrenceWhenLabel(
          occurrence: occurrence,
          occurrenceDate: DateTime(2025, 9, 10),
          userSettings: amsterdamSettings,
        );

        // THEN
        expect(
          label,
          HeliumDateTime.formatDateAndTimeForTodos(
            tz.TZDateTime(amsterdam, 2025, 9, 10, 14),
          ),
        );
      });

      test('an all-day occurrence shows only its date', () {
        // GIVEN
        final amsterdam = tz.getLocation('Europe/Amsterdam');
        final occurrence = MockModels.createHomework(
          allDay: true,
          start: DateTime.utc(2025, 9, 10, 12),
        );

        // WHEN
        final label = PlannerHelper.occurrenceWhenLabel(
          occurrence: occurrence,
          occurrenceDate: DateTime(2025, 9, 10),
          userSettings: amsterdamSettings,
        );

        // THEN
        expect(
          label,
          HeliumDateTime.formatDateForTodos(
            tz.TZDateTime(amsterdam, 2025, 9, 10, 14),
          ),
        );
      });

      test(
        'an occurrence starting on another local day shows the tapped date',
        () {
          // GIVEN
          final occurrence = MockModels.createHomework(
            start: DateTime.utc(2025, 9, 10, 22, 30),
          );
          final tappedDate = DateTime(2025, 9, 10);

          // WHEN
          final label = PlannerHelper.occurrenceWhenLabel(
            occurrence: occurrence,
            occurrenceDate: tappedDate,
            userSettings: amsterdamSettings,
          );

          // THEN
          expect(
            label,
            HeliumDateTime.formatDateForTodos(tappedDate),
            reason:
                '22:30 UTC is 00:30 on Sep 11 in Amsterdam, so the label falls back to the tapped date',
          );
        },
      );
    });
  });
}

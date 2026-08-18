import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/utils/schedule_week_resolver.dart';

void main() {
  // 2026-08-26 is a Wednesday; the resolver snaps to the Monday (2026-08-24) of
  // its week, so a mid-week anchor and its Monday must resolve identically.
  final anchor = DateTime(2026, 8, 26);

  group('ScheduleWeekResolver.weekIndex', () {
    test('test_anchor_week_is_index_zero_week_a', () {
      // GIVEN a fortnightly rotation anchored 2026-08-26
      // WHEN resolving a date in the anchor's own week
      // THEN the index is 0 (Week A)
      expect(
        ScheduleWeekResolver.weekIndex(
          anchor: anchor,
          interval: 2,
          date: DateTime(2026, 8, 26),
        ),
        0,
      );
    });

    test('test_anchor_monday_matches_midweek_anchor', () {
      // GIVEN a mid-week (Wed) anchor
      // WHEN resolving the Monday of that same calendar week
      // THEN it still falls in the anchor week (index 0)
      expect(
        ScheduleWeekResolver.weekIndex(
          anchor: anchor,
          interval: 2,
          date: DateTime(2026, 8, 24),
        ),
        0,
      );
    });

    test('test_following_week_is_index_one_week_b', () {
      // GIVEN a fortnightly rotation
      // WHEN resolving a date one calendar week after the anchor
      // THEN the index is 1 (Week B)
      expect(
        ScheduleWeekResolver.weekIndex(
          anchor: anchor,
          interval: 2,
          date: DateTime(2026, 9, 2),
        ),
        1,
      );
    });

    test('test_two_weeks_out_wraps_back_to_week_a', () {
      // GIVEN a fortnightly rotation
      // WHEN resolving a date two calendar weeks after the anchor
      // THEN the index wraps back to 0 (Week A)
      expect(
        ScheduleWeekResolver.weekIndex(
          anchor: anchor,
          interval: 2,
          date: DateTime(2026, 9, 9),
        ),
        0,
      );
    });

    test('test_three_week_interval_cycles_zero_one_two', () {
      // GIVEN a three-week rotation
      // WHEN resolving successive calendar weeks
      // THEN the indices cycle 0, 1, 2, 0
      for (final (weeksOut, expected) in [(0, 0), (1, 1), (2, 2), (3, 0)]) {
        expect(
          ScheduleWeekResolver.weekIndex(
            anchor: anchor,
            interval: 3,
            date: DateTime(2026, 8, 26).add(Duration(days: 7 * weeksOut)),
          ),
          expected,
          reason: '$weeksOut week(s) out',
        );
      }
    });
  });

  group('ScheduleWeekResolver.upcomingMeetingWeeks', () {
    test('test_week_a_meeting_weeks_start_at_anchor_week', () {
      // GIVEN a fortnightly Week A schedule
      // WHEN listing upcoming meeting weeks from the anchor
      // THEN they are the anchor Monday and every second Monday after
      expect(
        ScheduleWeekResolver.upcomingMeetingWeeks(
          anchor: anchor,
          interval: 2,
          offset: 0,
          from: anchor,
        ),
        [DateTime.utc(2026, 8, 24), DateTime.utc(2026, 9, 7), DateTime.utc(2026, 9, 21)],
      );
    });

    test('test_week_b_meeting_weeks_skip_to_offset_week', () {
      // GIVEN a fortnightly Week B schedule
      // WHEN listing upcoming meeting weeks from the anchor
      // THEN they start one week after the anchor Monday
      expect(
        ScheduleWeekResolver.upcomingMeetingWeeks(
          anchor: anchor,
          interval: 2,
          offset: 1,
          from: anchor,
        ),
        [DateTime.utc(2026, 8, 31), DateTime.utc(2026, 9, 14), DateTime.utc(2026, 9, 28)],
      );
    });

    test('test_from_before_anchor_clamps_to_anchor', () {
      // GIVEN a start date earlier than the anchor
      // WHEN listing meeting weeks
      // THEN the walk clamps to the anchor rather than emitting pre-anchor weeks
      expect(
        ScheduleWeekResolver.upcomingMeetingWeeks(
          anchor: anchor,
          interval: 2,
          offset: 0,
          from: DateTime(2026, 8, 1),
        ).first,
        DateTime.utc(2026, 8, 24),
      );
    });

    test('test_from_after_anchor_starts_at_that_window', () {
      // GIVEN a start date well after the anchor
      // WHEN listing Week A meeting weeks
      // THEN the first is the matching week on or after that start
      expect(
        ScheduleWeekResolver.upcomingMeetingWeeks(
          anchor: anchor,
          interval: 2,
          offset: 0,
          from: DateTime(2026, 9, 10),
        ),
        [DateTime.utc(2026, 9, 7), DateTime.utc(2026, 9, 21), DateTime.utc(2026, 10, 5)],
      );
    });
  });
}

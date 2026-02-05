// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/calendar_item_base_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';

class Sort {
  static void byTitle(List<BaseModel> list) {
    list.sort((a, b) => a.title.compareTo(b.title));
  }

  static void byStartDate(List<CourseGroupModel> list) {
    list.sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  static void byStartOfRange(List<ReminderModel> list, timeZone) {
    list.sort((a, b) {
      final aDate = HeliumDateTime.parse(a.startOfRange, timeZone);
      final bDate = HeliumDateTime.parse(b.startOfRange, timeZone);
      return bDate.compareTo(aDate);
    });
  }

  /// Sorts calendar items to match SfCalendar's ordering:
  /// 1. Start date
  /// 2. If end dates on same day: all-day first, then start time
  /// 3. If end dates on different days: shorter duration first
  /// 4. Type priority as final tiebreaker (Homework → ClassSchedule → Event → External)
  ///
  /// Applies the same fake duration adjustments as getEndTime() to ensure our
  /// sort matches SfCalendar's internal sort exactly.
  static const _typeSortPriority = {
    CalendarItemType.homework: 0,
    CalendarItemType.courseSchedule: 1,
    CalendarItemType.event: 2,
    CalendarItemType.external: 3,
  };

  static void byStartThenTitle(List<CalendarItemBaseModel> list) {
    list.sort((a, b) {
      final aPriority = _typeSortPriority[a.calendarItemType] ?? 0;
      final bPriority = _typeSortPriority[b.calendarItemType] ?? 0;

      // Apply same fake time adjustments as getStartTime()/getEndTime()
      // Don't adjust all-day events - they start at midnight
      final aSecondsToSubtract = a.allDay ? 0 : 3 - aPriority;
      final bSecondsToSubtract = b.allDay ? 0 : 3 - bPriority;
      final aStart = DateTime.parse(a.start).subtract(
        Duration(seconds: aSecondsToSubtract),
      );
      final bStart = DateTime.parse(b.start).subtract(
        Duration(seconds: bSecondsToSubtract),
      );
      final aEnd = DateTime.parse(a.end).subtract(
        Duration(minutes: a.allDay ? 0 : 3 - aPriority),
      );
      final bEnd = DateTime.parse(b.end).subtract(
        Duration(minutes: b.allDay ? 0 : 3 - bPriority),
      );

      // Compare start dates first (date only, ignoring time)
      final startDateCompare = _compareDatesOnly(aStart, bStart);
      if (startDateCompare != 0) return startDateCompare;

      // Same start date - check if end dates are on the same day
      final sameEndDate = _isSameDate(aEnd, bEnd);

      if (sameEndDate) {
        // All-day appointments first
        if (a.allDay != b.allDay) {
          return a.allDay ? -1 : 1;
        }
        // Then by adjusted start time (includes priority offset)
        final startTimeCompare = aStart.compareTo(bStart);
        if (startTimeCompare != 0) return startTimeCompare;
      } else {
        // Different end dates - shorter duration first
        final aDuration = aEnd.difference(aStart).inMinutes;
        final bDuration = bEnd.difference(bStart).inMinutes;
        final durationCompare = aDuration.compareTo(bDuration);
        if (durationCompare != 0) return durationCompare;
      }

      // Type priority as final tiebreaker
      return aPriority.compareTo(bPriority);
    });
  }

  static int _compareDatesOnly(DateTime a, DateTime b) {
    final aDate = DateTime(a.year, a.month, a.day);
    final bDate = DateTime(b.year, b.month, b.day);
    return aDate.compareTo(bDate);
  }

  static bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

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

class Sort {
  static void byTitle(List<BaseTitledModel> list) {
    list.sort((a, b) => a.title.compareTo(b.title));
  }

  static void byStartDate(List<CourseGroupModel> list) {
    list.sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  static void byStartOfRange(List<ReminderModel> list, timeZone) {
    list.sort((a, b) => b.startOfRange.compareTo(a.startOfRange));
  }

  /// When multiple items at the same time, opt for this priority
  static const _typeSortPriority = {
    CalendarItemType.homework: 0,
    CalendarItemType.courseSchedule: 1,
    CalendarItemType.event: 2,
    CalendarItemType.external: 3,
  };

  // TODO: let's also sort by course, that way items of the same course are grouped when time is the same
  static void byStartThenTitle(List<CalendarItemBaseModel> list) {
    list.sort((a, b) {
      final aPriority = _typeSortPriority[a.calendarItemType] ?? 0;
      final bPriority = _typeSortPriority[b.calendarItemType] ?? 0;

      // To ensure SfCalendar sorts as we expected, we add a "fake" second to
      // start/end times based on priority; SfCalendar's internal sort logic
      // also dates duration in to account, so we "fake" the end-time to ensure
      // our desired sort order overrides
      final aSecondsToSubtract = a.allDay ? 0 : 3 - aPriority;
      final bSecondsToSubtract = b.allDay ? 0 : 3 - bPriority;
      final aStart = a.start.subtract(
        Duration(seconds: aSecondsToSubtract),
      );
      final bStart = b.start.subtract(
        Duration(seconds: bSecondsToSubtract),
      );
      final aEnd = a.end.subtract(
        Duration(minutes: a.allDay ? 0 : 3 - aPriority),
      );
      final bEnd = b.end.subtract(
        Duration(minutes: b.allDay ? 0 : 3 - bPriority),
      );

      final startDateCompare = _compareDatesOnly(aStart, bStart);
      if (startDateCompare != 0) return startDateCompare;

      final sameEndDate = _isSameDate(aEnd, bEnd);

      // Before consider type-based priorities, all-day events always shown first
      if (sameEndDate) {
        if (a.allDay != b.allDay) {
          return a.allDay ? -1 : 1;
        }
        final startTimeCompare = aStart.compareTo(bStart);
        if (startTimeCompare != 0) return startTimeCompare;
      } else {
        final aDuration = aEnd.difference(aStart).inMinutes;
        final bDuration = bEnd.difference(bStart).inMinutes;
        final durationCompare = aDuration.compareTo(bDuration);
        if (durationCompare != 0) return durationCompare;
      }

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

// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/calendar_item_base_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/utils/app_globals.dart';

/// Priority order for calendar item types when times are equal.
/// Lower values appear first: Homework → ClassSchedule → Event → External
const typeSortPriority = {
  CalendarItemType.homework: 0,
  CalendarItemType.courseSchedule: 1,
  CalendarItemType.event: 2,
  CalendarItemType.external: 3,
};

/// Compares dates only (ignoring time components).
int compareDatesOnly(DateTime a, DateTime b) {
  final aDate = DateTime(a.year, a.month, a.day);
  final bDate = DateTime(b.year, b.month, b.day);
  return aDate.compareTo(bDate);
}

/// Checks if two dates are the same (ignoring time components).
bool isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Top-level comparison function for calendar items.
/// Shared by both Sort.byStartThenTitle() and background isolate filtering.
///
/// To ensure SfCalendar sorts as expected, we add "fake" adjustments to
/// start/end times based on priority. SfCalendar's internal sort logic
/// takes duration into account, so we adjust both start and end times.
int compareCalendarItems({
  required CalendarItemType aType,
  required CalendarItemType bType,
  required bool aAllDay,
  required bool bAllDay,
  required DateTime aStart,
  required DateTime bStart,
  required DateTime aEnd,
  required DateTime bEnd,
  required String aTitle,
  required String bTitle,
  int? aCourseId,
  int? bCourseId,
}) {
  final aPriority = typeSortPriority[aType] ?? 0;
  final bPriority = typeSortPriority[bType] ?? 0;

  // Apply priority-based time adjustments for sorting
  final aSecondsToSubtract = aAllDay ? 0 : 3 - aPriority;
  final bSecondsToSubtract = bAllDay ? 0 : 3 - bPriority;
  final aStartAdjusted = aStart.subtract(Duration(seconds: aSecondsToSubtract));
  final bStartAdjusted = bStart.subtract(Duration(seconds: bSecondsToSubtract));
  final aEndAdjusted = aEnd.subtract(Duration(minutes: aAllDay ? 0 : 3 - aPriority));
  final bEndAdjusted = bEnd.subtract(Duration(minutes: bAllDay ? 0 : 3 - bPriority));

  final startDateCompare = compareDatesOnly(aStartAdjusted, bStartAdjusted);
  if (startDateCompare != 0) return startDateCompare;

  final sameEndDate = isSameDate(aEndAdjusted, bEndAdjusted);

  // Before considering type-based priorities, all-day events always shown first
  if (sameEndDate) {
    if (aAllDay != bAllDay) {
      return aAllDay ? -1 : 1;
    }
    final startTimeCompare = aStartAdjusted.compareTo(bStartAdjusted);
    if (startTimeCompare != 0) return startTimeCompare;
  } else {
    final aDuration = aEndAdjusted.difference(aStartAdjusted).inMinutes;
    final bDuration = bEndAdjusted.difference(bStartAdjusted).inMinutes;
    final durationCompare = aDuration.compareTo(bDuration);
    if (durationCompare != 0) return durationCompare;
  }

  final priorityCompare = aPriority.compareTo(bPriority);
  if (priorityCompare != 0) return priorityCompare;

  // For homework items with same priority, group by course
  if (aType == CalendarItemType.homework && bType == CalendarItemType.homework) {
    if (aCourseId != null && bCourseId != null) {
      final courseCompare = aCourseId.compareTo(bCourseId);
      if (courseCompare != 0) return courseCompare;
    }
  }

  // Final stable tiebreaker: sort by title
  return aTitle.compareTo(bTitle);
}

class Sort {
  /// Priority order for calendar item types when times are equal.
  /// Lower values appear first: Homework -> ClassSchedule -> Event -> External
  @Deprecated('Use top-level typeSortPriority constant instead')
  static const typeSortPriority = {
    CalendarItemType.homework: 0,
    CalendarItemType.courseSchedule: 1,
    CalendarItemType.event: 2,
    CalendarItemType.external: 3,
  };

  static void byTitle(List<BaseTitledModel> list) {
    list.sort((a, b) => a.title.compareTo(b.title));
  }

  static void byStartDate(List<CourseGroupModel> list) {
    list.sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  static void byStartOfRange(List<ReminderModel> list, timeZone) {
    list.sort((a, b) => b.startOfRange.compareTo(a.startOfRange));
  }

  static void byStartThenTitle(List<CalendarItemBaseModel> list) {
    list.sort((a, b) {
      return compareCalendarItems(
        aType: a.calendarItemType,
        bType: b.calendarItemType,
        aAllDay: a.allDay,
        bAllDay: b.allDay,
        aStart: a.start,
        bStart: b.start,
        aEnd: a.end,
        bEnd: b.end,
        aTitle: a.title,
        bTitle: b.title,
        aCourseId: a is HomeworkModel ? a.course.id : null,
        bCourseId: b is HomeworkModel ? b.course.id : null,
      );
    });
  }
}

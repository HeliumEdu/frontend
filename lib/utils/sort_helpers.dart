// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/planner_item_base_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/utils/planner_helper.dart';

class Sort {
  /// Priority order for calendar item types when times are equal.
  /// Lower values appear first: Homework --> ClassSchedule --> Event --> External
  static const typeSortPriority = {
    PlannerItemType.homework: 0,
    PlannerItemType.courseSchedule: 1,
    PlannerItemType.event: 2,
    PlannerItemType.external: 3,
  };

  /// Calculates seconds to subtract from start time to encode sort order for timed events.
  /// SfCalendar truncates sub-second precision, so we use seconds-based adjustments.
  /// Higher priority items (lower priority value) get more seconds subtracted,
  /// making them appear earlier.
  static int getTimedEventStartTimeAdjustmentSeconds(
    int priority,
    int position,
  ) {
    // Type priority: Use thousands of seconds (3000, 2000, 1000, 0)
    // This ensures homework < course schedule < event < external
    final baseSeconds = (3 - priority) * 1000;

    // Position: Add seconds with reverse order (position 0 gets most)
    // This allows up to 100 items at same time to maintain alphabetical order
    final positionSeconds = 100 - position;

    return baseSeconds + positionSeconds;
  }

  /// Calculates the Duration to subtract from end time for timed events.
  /// Uses minutes to avoid visibly shortening events too much.
  static Duration getTimedEventEndTimeAdjustment(int priority, int position) {
    // Type priority: Use minutes (3, 2, 1, 0)
    final baseMinutes = 3 - priority;

    // Position: Add seconds for fine-grained ordering within same type/time
    final positionMinutes = (100 - position) / 60.0;

    final totalMinutes = baseMinutes + positionMinutes;
    return Duration(
      minutes: totalMinutes.floor(),
      seconds: ((totalMinutes % 1) * 60).round(),
    );
  }

  /// Compares dates only (ignoring time components).
  static int compareDatesOnly(DateTime a, DateTime b) {
    final aDate = DateTime(a.year, a.month, a.day);
    final bDate = DateTime(b.year, b.month, b.day);
    return aDate.compareTo(bDate);
  }

  /// Checks if two dates are the same (ignoring time components).
  static bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Shared comparison function for calendar items.
  /// Used by both byStartThenTitle() and background isolate filtering.
  static int comparePlannerItems({
    required PlannerItemType aType,
    required PlannerItemType bType,
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

    // Apply priority-based time adjustments for sorting (timed events only)
    final aSecondsToSubtract = aAllDay ? 0 : 3 - aPriority;
    final bSecondsToSubtract = bAllDay ? 0 : 3 - bPriority;
    final aStartAdjusted = aStart.subtract(
      Duration(seconds: aSecondsToSubtract),
    );
    final bStartAdjusted = bStart.subtract(
      Duration(seconds: bSecondsToSubtract),
    );
    final aEndAdjusted = aEnd.subtract(
      Duration(minutes: aAllDay ? 0 : 3 - aPriority),
    );
    final bEndAdjusted = bEnd.subtract(
      Duration(minutes: bAllDay ? 0 : 3 - bPriority),
    );

    // 1. Sort by start date
    final startDateCompare = compareDatesOnly(aStartAdjusted, bStartAdjusted);
    if (startDateCompare != 0) return startDateCompare;

    // 2. All-day events always shown before timed events
    if (aAllDay != bAllDay) {
      return aAllDay ? -1 : 1;
    }

    // 3. For timed events with different end dates: sort by duration ascending (shorter first)
    if (!aAllDay && !bAllDay) {
      final sameEndDate = isSameDate(aEndAdjusted, bEndAdjusted);
      if (!sameEndDate) {
        final aDuration = aEndAdjusted.difference(aStartAdjusted).inMinutes;
        final bDuration = bEndAdjusted.difference(bStartAdjusted).inMinutes;
        final durationCompare = aDuration.compareTo(bDuration); // Ascending
        if (durationCompare != 0) return durationCompare;
      }
      // Sort by start time
      final startTimeCompare = aStartAdjusted.compareTo(bStartAdjusted);
      if (startTimeCompare != 0) return startTimeCompare;
    }

    // 4. Type priority
    final priorityCompare = aPriority.compareTo(bPriority);
    if (priorityCompare != 0) return priorityCompare;

    // 5. For homework items with same priority, group by course
    if (aType == PlannerItemType.homework &&
        bType == PlannerItemType.homework) {
      if (aCourseId != null && bCourseId != null) {
        final courseCompare = aCourseId.compareTo(bCourseId);
        if (courseCompare != 0) return courseCompare;
      }
    }

    // 6. Final tiebreaker: sort by title alphabetically
    return aTitle.compareTo(bTitle);
  }

  static void byTitle(List<BaseTitledModel> list) {
    list.sort((a, b) => a.title.compareTo(b.title));
  }

  static void byStartDate(List<CourseGroupModel> list) {
    list.sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  static void byStartOfRange(List<ReminderModel> list, timeZone) {
    list.sort((a, b) => b.startOfRange.compareTo(a.startOfRange));
  }

  static void byStartThenTitle(List<PlannerItemBaseModel> list) {
    list.sort((a, b) {
      return comparePlannerItems(
        aType: a.plannerItemType,
        bType: b.plannerItemType,
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

// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_event_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/rrule_builder.dart';
import 'package:logging/logging.dart';

final _log = Logger('data.sources');

/// Builds course schedule events for the given courses within the date range.
///
/// Events are generated as recurring appointments using RRULE format. Days with
/// different times are grouped into separate recurring events.
///
/// If [search] is provided, only events whose title contains the search string
/// (case-insensitive) are returned.
class CourseScheduleBuilderSource {
  List<CourseScheduleEventModel> buildCourseScheduleEvents({
    required List<CourseModel> courses,
    required DateTime from,
    required DateTime to,
    String? search,
    bool? shownOnCalendar,
  }) {
    _log.info('Building CourseScheduleEvents for ${courses.length} course(s)');

    final List<CourseScheduleEventModel> events = [];

    for (final course in courses) {
      for (final schedule in course.schedules) {
        final scheduleEvents = _buildEventsForSchedule(
          course: course,
          schedule: schedule,
          from: from,
          to: to,
        );
        events.addAll(scheduleEvents);
      }
    }

    // Apply search filter if provided
    List<CourseScheduleEventModel> filteredEvents = events;
    if (search != null && search.isNotEmpty) {
      final searchLower = search.toLowerCase();
      filteredEvents = events
          .where((event) => event.title.toLowerCase().contains(searchLower))
          .toList();
    }

    // Sort by start time
    filteredEvents.sort((a, b) => a.start.compareTo(b.start));

    _log.info('... built ${filteredEvents.length} CourseScheduleEvent(s)');
    return filteredEvents;
  }

  /// Builds recurring events for a single schedule.
  ///
  /// Groups days by their time slot and creates one recurring event per unique
  /// time combination. This handles the case where different days have different
  /// class times (e.g., Mon 9am, Wed 2pm).
  ///
  /// The [from] and [to] parameters are used only to check if the course overlaps
  /// with the requested range. The actual recurring event spans the full course
  /// duration so SfCalendar can expand it across all visible months.
  List<CourseScheduleEventModel> _buildEventsForSchedule({
    required CourseModel course,
    required CourseScheduleModel schedule,
    required DateTime from,
    required DateTime to,
  }) {
    final List<CourseScheduleEventModel> events = [];

    if (from.isAfter(course.endDate) || to.isBefore(course.startDate)) {
      return events;
    }

    final timeSlotGroups = _groupDaysByTimeSlot(schedule);

    int slotIndex = 0;
    for (final entry in timeSlotGroups.entries) {
      final timeSlot = entry.key;
      final dayIndices = entry.value;

      final firstOccurrence = _findFirstOccurrence(
        course.startDate,
        dayIndices,
      );

      if (firstOccurrence == null || firstOccurrence.isAfter(course.endDate)) {
        slotIndex++;
        continue;
      }

      final rrule = RRuleBuilder.buildWeeklyRecurrence(
        dayIndices: dayIndices,
        until: course.endDate,
      );

      final start = DateTime(
        firstOccurrence.year,
        firstOccurrence.month,
        firstOccurrence.day,
        timeSlot.start.hour,
        timeSlot.start.minute,
      );
      final end = DateTime(
        firstOccurrence.year,
        firstOccurrence.month,
        firstOccurrence.day,
        timeSlot.end.hour,
        timeSlot.end.minute,
      );

      final eventId = _generateEventId(schedule.id, slotIndex);

      events.add(
        CourseScheduleEventModel(
          id: eventId,
          title: course.title,
          allDay: false,
          showEndTime: true,
          start: start,
          end: end,
          priority: 50,
          url: null,
          comments: '',
          attachments: [],
          reminders: [],
          color: course.color,
          ownerId: '${course.id}',
          recurrenceRule: rrule,
        ),
      );

      slotIndex++;
    }

    return events;
  }

  /// Groups active days in a schedule by their time slot.
  ///
  /// Returns a map from time slot to list of day indices that share that time.
  /// For example, a MWF 9-10:30 schedule would return {(9:00, 10:30): [1, 3, 5]}.
  /// A schedule with Mon 9am and Wed 2pm would return two entries.
  Map<_TimeSlot, List<int>> _groupDaysByTimeSlot(CourseScheduleModel schedule) {
    final Map<_TimeSlot, List<int>> groups = {};

    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      if (!schedule.isDayActive(dayIndex)) {
        continue;
      }

      final startTime = schedule.getStartTimeForDayIndex(dayIndex);
      final endTime = schedule.getEndTimeForDayIndex(dayIndex);
      final timeSlot = _TimeSlot(startTime, endTime);

      groups.putIfAbsent(timeSlot, () => []).add(dayIndex);
    }

    return groups;
  }

  /// Finds the first occurrence date on or after [startDate] that falls on one
  /// of the specified [dayIndices].
  DateTime? _findFirstOccurrence(DateTime startDate, List<int> dayIndices) {
    if (dayIndices.isEmpty) return null;

    DateTime current = HeliumDateTime.dateOnly(startDate);

    for (int i = 0; i < 7; i++) {
      final dayIndex = HeliumDateTime.getDayIndex(current);
      if (dayIndices.contains(dayIndex)) {
        return current;
      }
      current = current.add(const Duration(days: 1));
    }

    return null;
  }

  int _generateEventId(int scheduleId, int slotIndex) {
    return scheduleId * 100 + slotIndex;
  }
}

class _TimeSlot {
  final TimeOfDay start;
  final TimeOfDay end;

  const _TimeSlot(this.start, this.end);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _TimeSlot &&
        other.start.hour == start.hour &&
        other.start.minute == start.minute &&
        other.end.hour == end.hour &&
        other.end.minute == end.minute;
  }

  @override
  int get hashCode =>
      Object.hash(start.hour, start.minute, end.hour, end.minute);
}

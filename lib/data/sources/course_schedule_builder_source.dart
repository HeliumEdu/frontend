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
import 'package:heliumapp/utils/rrule_builder.dart';
import 'package:logging/logging.dart';

final _log = Logger('data.sources');

/// Represents a time slot with start and end times.
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
  int get hashCode => Object.hash(
        start.hour,
        start.minute,
        end.hour,
        end.minute,
      );
}

/// Builds course schedule events from local course data without hitting the API.
///
/// This source generates [CourseScheduleEventModel] instances with recurrence rules,
/// letting SfCalendar handle the expansion during rendering. Instead of creating
/// one event per occurrence, it creates 1-3 recurring appointments per schedule
/// based on unique time slots.
class CourseScheduleBuilderSource {
  /// Builds course schedule events for the given courses within the date range.
  ///
  /// Events are generated as recurring appointments using RRULE format. Days with
  /// different times are grouped into separate recurring events.
  ///
  /// If [search] is provided, only events whose title contains the search string
  /// (case-insensitive) are returned.
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

    // Check if course overlaps with requested range at all
    if (from.isAfter(course.endDate) || to.isBefore(course.startDate)) {
      return events;
    }

    // Group active days by their time slot
    final timeSlotGroups = _groupDaysByTimeSlot(schedule);

    // Create one recurring event per time slot group
    int slotIndex = 0;
    for (final entry in timeSlotGroups.entries) {
      final timeSlot = entry.key;
      final dayIndices = entry.value;

      // Find the TRUE first occurrence based on course start date (not query range)
      final firstOccurrence = _findFirstOccurrence(
        course.startDate,
        dayIndices,
      );

      if (firstOccurrence == null || firstOccurrence.isAfter(course.endDate)) {
        slotIndex++;
        continue;
      }

      // Build the RRULE with course end date (not query end date)
      final rrule = RRuleBuilder.buildWeeklyRecurrence(
        dayIndices: dayIndices,
        until: course.endDate,
      );

      // Create the recurring event starting on the first occurrence
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

      // Generate a deterministic ID based on schedule ID and slot index
      final eventId = _generateEventId(schedule.id, slotIndex);

      events.add(CourseScheduleEventModel(
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
      ));

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
      if (!_isDayActive(schedule.daysOfWeek, dayIndex)) {
        continue;
      }

      final startTime = _getStartTimeForDayIndex(schedule, dayIndex);
      final endTime = _getEndTimeForDayIndex(schedule, dayIndex);
      final timeSlot = _TimeSlot(startTime, endTime);

      groups.putIfAbsent(timeSlot, () => []).add(dayIndex);
    }

    return groups;
  }

  /// Finds the first occurrence date on or after [startDate] that falls on one
  /// of the specified [dayIndices].
  DateTime? _findFirstOccurrence(DateTime startDate, List<int> dayIndices) {
    if (dayIndices.isEmpty) return null;

    DateTime current = _dateOnly(startDate);

    // Search up to 7 days to find the first matching day
    for (int i = 0; i < 7; i++) {
      final dayIndex = _getDayIndex(current);
      if (dayIndices.contains(dayIndex)) {
        return current;
      }
      current = current.add(const Duration(days: 1));
    }

    return null;
  }

  /// Generates a deterministic event ID from schedule ID and slot index.
  int _generateEventId(int scheduleId, int slotIndex) {
    // Use a formula that ensures unique IDs across schedules and slots
    return scheduleId * 100 + slotIndex;
  }

  /// Converts Dart's DateTime.weekday (1=Monday, 7=Sunday) to our index (0=Sunday, 6=Saturday).
  int _getDayIndex(DateTime date) {
    // DateTime.weekday: 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun
    // Our index: 0=Sun, 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat
    return date.weekday == 7 ? 0 : date.weekday;
  }

  /// Checks if the given day index is active in the daysOfWeek string.
  bool _isDayActive(String daysOfWeek, int dayIndex) {
    if (dayIndex < 0 || dayIndex >= daysOfWeek.length) {
      return false;
    }
    return daysOfWeek[dayIndex] == '1';
  }

  /// Gets the start time for a specific day index.
  TimeOfDay _getStartTimeForDayIndex(
    CourseScheduleModel schedule,
    int dayIndex,
  ) {
    switch (dayIndex) {
      case 0:
        return schedule.sunStartTime;
      case 1:
        return schedule.monStartTime;
      case 2:
        return schedule.tueStartTime;
      case 3:
        return schedule.wedStartTime;
      case 4:
        return schedule.thuStartTime;
      case 5:
        return schedule.friStartTime;
      case 6:
        return schedule.satStartTime;
      default:
        return schedule.sunStartTime;
    }
  }

  /// Gets the end time for a specific day index.
  TimeOfDay _getEndTimeForDayIndex(CourseScheduleModel schedule, int dayIndex) {
    switch (dayIndex) {
      case 0:
        return schedule.sunEndTime;
      case 1:
        return schedule.monEndTime;
      case 2:
        return schedule.tueEndTime;
      case 3:
        return schedule.wedEndTime;
      case 4:
        return schedule.thuEndTime;
      case 5:
        return schedule.friEndTime;
      case 6:
        return schedule.satEndTime;
      default:
        return schedule.sunEndTime;
    }
  }

  /// Returns the later of two dates.
  DateTime _maxDate(DateTime a, DateTime b) {
    return a.isAfter(b) ? a : b;
  }

  /// Returns the earlier of two dates.
  DateTime _minDate(DateTime a, DateTime b) {
    return a.isBefore(b) ? a : b;
  }

  /// Returns a DateTime with only the date part (no time).
  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

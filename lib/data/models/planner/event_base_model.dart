// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/planner_item_base_model.dart';

/// Base for planner items that carry RRULE-driven recurrence sourced from the
/// backend API (iCal RRULE + EXDATE). [EventModel] and
/// [ExternalCalendarEventModel] both extend this — the data source treats them
/// uniformly via `is EventBaseModel`.
///
/// [CourseScheduleEventModel] is intentionally **not** an [EventBaseModel]: its
/// recurrenceRule is built client-side from `Course.days_of_week` /
/// `start_date` / `end_date` via `RRuleBuilder`, not sourced from the API.
abstract class EventBaseModel extends PlannerItemBaseModel {
  /// iCal RRULE string (e.g. `FREQ=WEEKLY;BYDAY=MO,WE,FR`) that marks this
  /// event as a recurring series anchored on [start].
  final String? recurrenceRule;

  /// Datetimes to skip when expanding [recurrenceRule] (iCal EXDATE).
  final List<DateTime> exceptionDates;

  EventBaseModel({
    required super.id,
    required super.title,
    required super.allDay,
    required super.showEndTime,
    required super.start,
    required super.end,
    required super.priority,
    required super.url,
    required super.comments,
    required super.attachments,
    required super.reminders,
    required super.color,
    required super.plannerItemType,
    this.recurrenceRule,
    this.exceptionDates = const [],
  });

  /// Parses an API JSON `exception_dates` list (ISO-8601 strings) to a
  /// `List<DateTime>`. Returns const empty when the field is absent or not a list.
  static List<DateTime> parseExceptionDatesJson(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<String>().map(DateTime.parse).toList();
  }

  /// Returns a copy with `start` and `end` overridden — every other field
  /// (including [recurrenceRule] and [exceptionDates]) carries through.
  /// Used by the planner data source to render each expanded RRULE occurrence
  /// as its own per-day item.
  EventBaseModel copyAtOccurrence(DateTime start, DateTime end);

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    if (recurrenceRule != null) {
      data['recurrence_rule'] = recurrenceRule;
    }
    if (exceptionDates.isNotEmpty) {
      data['exception_dates'] = exceptionDates
          .map((d) => d.toIso8601String())
          .toList();
    }
    return data;
  }
}

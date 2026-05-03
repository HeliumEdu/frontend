// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/external_calendar_event_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/sources/planner_item_filter_compute.dart';
import 'package:heliumapp/utils/grade_helpers.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'package:logging/logging.dart';

import 'api_helper.dart';

final _log = Logger('planner_count_helper');

/// A consistent view of the test user's full planner state, fetched once and
/// reused across many [PlannerCountHelper.expectedCount] calls.
class PlannerSnapshot {
  final List<CourseModel> courses;
  final Map<int, CategoryModel> categoriesById;
  final List<HomeworkModel> homework;
  final List<EventModel> events;
  final List<CourseScheduleModel> schedules;

  /// Empty until the external-calendar test scaffolds an iCal feed and re-snaps.
  final List<ExternalCalendarEventModel> external;

  PlannerSnapshot({
    required this.courses,
    required this.categoriesById,
    required this.homework,
    required this.events,
    required this.schedules,
    this.external = const [],
  });
}

/// Computes deterministic UI counts for the planner by replaying the
/// production filter logic ([computeFilteredItems]) against a snapshot of the
/// user's real backend state.
///
/// Tests assert that the rendered count equals what the helper computes for
/// the same filter combination, so counts stay correct as upstream data
/// changes without hard-coding brittle numbers.
class PlannerCountHelper {
  PlannerCountHelper(this._api);

  final ApiHelper _api;

  /// Fetches the full planner snapshot in parallel.
  Future<PlannerSnapshot> snapshot() async {
    final results = await Future.wait([
      _api.getCourses(),
      _api.getCategories(),
      _api.getHomeworkItems(),
      _api.getEvents(),
      _api.getCourseSchedules(),
    ]);

    final courses = (results[0] as List<CourseModel>?) ?? const [];
    final categories = (results[1] as List<CategoryModel>?) ?? const [];
    final homework = (results[2] as List<HomeworkModel>?) ?? const [];
    final events = (results[3] as List<EventModel>?) ?? const [];
    final schedules = (results[4] as List<CourseScheduleModel>?) ?? const [];

    _log.info(
      'Snapshot: ${courses.length} courses, ${categories.length} categories, '
      '${homework.length} homework, ${events.length} events, '
      '${schedules.length} schedules',
    );

    return PlannerSnapshot(
      courses: courses,
      categoriesById: {for (final c in categories) c.id: c},
      homework: homework,
      events: events,
      schedules: schedules,
    );
  }

  /// Returns the number of items the UI should render for the given view +
  /// filter combination, mirroring [computeFilteredItems] exactly.
  ///
  /// For window-bounded views (month/week/day/agenda), [windowStart] and
  /// [windowEnd] must be provided. The window is half-open: an item is
  /// included when `start < windowEnd && end > windowStart`.
  ///
  /// Todos view ignores `windowStart`/`windowEnd` and `filterTypes` — the UI
  /// hides the type selector and only shows homework.
  ///
  /// `filterStatuses` containing [PlannerFilterStatus.overdue] reads the real
  /// `DateTime.now()` (matching production); add a clock injection here if a
  /// future test needs deterministic overdue counts.
  int expectedCount({
    required PlannerSnapshot snapshot,
    required PlannerView view,
    DateTime? windowStart,
    DateTime? windowEnd,
    Set<int> selectedCourseIds = const {},
    List<String> filterCategories = const [],
    List<String> filterTypes = const [],
    Set<String> filterStatuses = const {},
    String searchQuery = '',
  }) {
    final pool = _materializePool(
      snapshot: snapshot,
      view: view,
      windowStart: windowStart,
      windowEnd: windowEnd,
    );

    final inWindow = (windowStart != null && windowEnd != null)
        ? pool
              .where(
                (it) =>
                    it.start.isBefore(windowEnd) && it.end.isAfter(windowStart),
              )
              .toList()
        : pool;

    final params = FilterParams(
      filterTypes: filterTypes,
      filterCategories: filterCategories,
      selectedCourseIds: selectedCourseIds,
      filterStatuses: filterStatuses,
      searchQuery: searchQuery,
      categoryIdToTitle: {
        for (final c in snapshot.categoriesById.values) c.id: c.title,
      },
      completedOverrides: const {},
    );

    return computeFilteredItems(
      FilterComputeInput(items: inWindow, params: params),
    ).length;
  }

  /// Standalone class-meeting count for [start, end) across [selectedCourseIds]
  /// (or all courses when empty), without needing a full filter sweep.
  int expectedClassMeetingsInRange({
    required PlannerSnapshot snapshot,
    required DateTime start,
    required DateTime end,
    Set<int> selectedCourseIds = const {},
  }) {
    return _expandClassMeetings(
      snapshot: snapshot,
      windowStart: start,
      windowEnd: end,
      selectedCourseIds: selectedCourseIds,
    ).length;
  }

  // ---- internals ----

  List<FilterableItem> _materializePool({
    required PlannerSnapshot snapshot,
    required PlannerView view,
    DateTime? windowStart,
    DateTime? windowEnd,
  }) {
    final pool = <FilterableItem>[];
    var idx = 0;

    for (final hw in snapshot.homework) {
      pool.add(
        FilterableItem(
          id: hw.id,
          index: idx++,
          type: PlannerItemType.homework,
          title: hw.title,
          start: hw.start,
          end: hw.end,
          allDay: hw.allDay,
          completed: hw.completed,
          graded: GradeHelper.parseGrade(hw.currentGrade) != null,
          courseId: hw.course.id,
          categoryId: hw.category.id,
        ),
      );
    }

    if (view == PlannerView.todos) {
      return pool;
    }

    for (final ev in snapshot.events) {
      pool.add(
        FilterableItem(
          id: ev.id,
          index: idx++,
          type: PlannerItemType.event,
          title: ev.title,
          start: ev.start,
          end: ev.end,
          allDay: ev.allDay,
        ),
      );
    }

    for (final ec in snapshot.external) {
      pool.add(
        FilterableItem(
          id: ec.id,
          index: idx++,
          type: PlannerItemType.external,
          title: ec.title,
          start: ec.start,
          end: ec.end,
          allDay: ec.allDay,
          ownerId: ec.ownerId,
        ),
      );
    }

    if (windowStart != null && windowEnd != null) {
      for (final occ in _expandClassMeetings(
        snapshot: snapshot,
        windowStart: windowStart,
        windowEnd: windowEnd,
      )) {
        pool.add(
          FilterableItem(
            id: idx,
            index: idx++,
            type: PlannerItemType.courseSchedule,
            title: occ.courseTitle,
            start: occ.start,
            end: occ.end,
            allDay: false,
            ownerId: occ.courseId.toString(),
          ),
        );
      }
    }

    return pool;
  }

  /// Walks the day-of-week mask of each [CourseScheduleModel] within
  /// `[course.startDate, course.endDate)` clipped to `[windowStart, windowEnd)`,
  /// emitting one occurrence per matching day. Mirrors what production builds
  /// via SfCalendar recurrence expansion, but without the syncfusion dep.
  Iterable<_ScheduleOccurrence> _expandClassMeetings({
    required PlannerSnapshot snapshot,
    required DateTime windowStart,
    required DateTime windowEnd,
    Set<int> selectedCourseIds = const {},
  }) sync* {
    final coursesById = {for (final c in snapshot.courses) c.id: c};

    for (final sched in snapshot.schedules) {
      final course = coursesById[sched.course];
      if (course == null) continue;
      if (selectedCourseIds.isNotEmpty &&
          !selectedCourseIds.contains(course.id)) {
        continue;
      }

      final activeDays = sched.getActiveDayIndices();
      if (activeDays.isEmpty) continue;

      final lo = course.startDate.isAfter(windowStart)
          ? course.startDate
          : windowStart;
      final hiCourse = course.endDate.add(const Duration(days: 1));
      final hi = hiCourse.isBefore(windowEnd) ? hiCourse : windowEnd;

      var d = DateTime(lo.year, lo.month, lo.day);
      final last = DateTime(hi.year, hi.month, hi.day);
      while (d.isBefore(last)) {
        // Dart weekday is 1=Mon..7=Sun; CourseScheduleModel uses 0=Sun..6=Sat.
        final dayIdx = d.weekday % 7;
        if (activeDays.contains(dayIdx)) {
          final startTime = sched.getStartTimeForDayIndex(dayIdx);
          final endTime = sched.getEndTimeForDayIndex(dayIdx);
          final start = DateTime(
            d.year,
            d.month,
            d.day,
            startTime.hour,
            startTime.minute,
          );
          final end = DateTime(
            d.year,
            d.month,
            d.day,
            endTime.hour,
            endTime.minute,
          );
          yield _ScheduleOccurrence(
            courseId: course.id,
            courseTitle: course.title,
            start: start,
            end: end,
          );
        }
        d = d.add(const Duration(days: 1));
      }
    }
  }
}

class _ScheduleOccurrence {
  final int courseId;
  final String courseTitle;
  final DateTime start;
  final DateTime end;

  _ScheduleOccurrence({
    required this.courseId,
    required this.courseTitle,
    required this.start,
    required this.end,
  });
}

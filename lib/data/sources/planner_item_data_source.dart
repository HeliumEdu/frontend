// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/data/models/planner/planner_item_base_model.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/resource_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_event_model.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/external_calendar_event_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/sources/planner_item_filter_compute.dart';
import 'package:heliumapp/domain/repositories/course_schedule_event_repository.dart';
import 'package:heliumapp/domain/repositories/event_repository.dart';
import 'package:heliumapp/domain/repositories/external_calendar_repository.dart';
import 'package:heliumapp/domain/repositories/homework_repository.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/grade_helpers.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'package:timezone/standalone.dart' as tz;
import 'package:heliumapp/utils/sort_helpers.dart';
import 'package:logging/logging.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

final _log = Logger('data.sources');

/// Optimistic override for planner item start/end times during drag-drop/resize
class PlannerItemTimeOverride {
  final String start;
  final String end;

  const PlannerItemTimeOverride({required this.start, required this.end});
}

class PlannerItemDataSource extends CalendarDataSource<PlannerItemBaseModel> {
  final EventRepository eventRepository;
  final HomeworkRepository homeworkRepository;
  final CourseScheduleRepository courseScheduleRepository;
  final ExternalCalendarRepository externalCalendarRepository;
  UserSettingsModel userSettings;

  List<CourseModel>? courses;
  Map<int, CourseGroupModel>? courseGroupsById;
  Map<int, CategoryModel>? categoriesMap;
  Map<int, ResourceModel>? resourcesMap;

  final Map<String, List<PlannerItemBaseModel>> _dateRangeCache = {};

  bool _hasLoadedInitialData = false;
  Map<int, bool> _filteredCourses = {};
  List<String> _filterCategories = [];
  List<String> _filterTypes = [];
  Set<String> _filterStatuses = {};
  String _searchQuery = '';
  int _todosItemsPerPage = 10;
  final Map<int, bool> _completedOverrides = {};
  final Map<int, PlannerItemTimeOverride> _timeOverrides = {};
  bool _isMonthView = false;
  Timer? _filterDebounceTimer;
  bool _isFilteringInProgress = false;
  Completer<void>? _filterCompleter;
  bool _isRefreshing = false;

  /// Duration for filter debouncing. Set to Duration.zero in tests for
  /// synchronous behavior.
  @visibleForTesting
  static Duration filterDebounceDuration = const Duration(milliseconds: 16);

  PlannerItemDataSource({
    required this.eventRepository,
    required this.homeworkRepository,
    required this.courseScheduleRepository,
    required this.externalCalendarRepository,
    required this.userSettings,
  }) {
    appointments = [];
  }

  final ChangeNotifier _changeNotifier = ChangeNotifier();
  bool _isDisposed = false;

  Listenable get changeNotifier => _changeNotifier;

  /// Indicates when the data source is refreshing (loading data or applying
  /// filters). UI can check this when changeNotifier fires to show a loading
  /// overlay.
  bool get isRefreshing => _isRefreshing;

  /// Tell the data source which calendar view is active.
  /// In month view, all-day items are reported as timed (isAllDay = false) so
  /// SfCalendar uses getStartTime for ordering. SfCalendar's internal sort for
  /// isAllDay == true items ignores list order and uses only start time — when
  /// start times are identical it falls back to an internal tiebreaker we can't
  /// control. Reporting as timed forces it to use our getStartTime values, which
  /// encode type priority as a minute offset to guarantee stable ordering.
  set isMonthView(bool value) {
    if (_isMonthView == value) return;
    _isMonthView = value;
    if (appointments != null && appointments!.isNotEmpty && !_isDisposed) {
      notifyListeners(CalendarDataSourceAction.reset, appointments!);
    }
  }

  void _notifyChangeListeners() {
    if (_isDisposed) return;
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    _changeNotifier.notifyListeners();
  }

  /// Clears all cached calendar data and triggers a refresh.
  /// Call this when calendar sources (courses, events, external calendars, etc.)
  /// have been modified and the calendar view needs to refetch data.
  ///
  /// Pass [visibleStart] and [visibleEnd] to immediately reload data for the
  /// currently visible date range.
  Future<void> refreshCalendarSources({
    DateTime? visibleStart,
    DateTime? visibleEnd,
  }) async {
    _isRefreshing = true;
    _notifyChangeListeners();

    try {
      _log.info('Refreshing planner sources - clearing cache');
      _dateRangeCache.clear();
      _hasLoadedInitialData = false;

      if (visibleStart != null && visibleEnd != null) {
        await handleLoadMore(visibleStart, visibleEnd, forceRefresh: true);
      }
    } finally {
      _isRefreshing = false;
      _notifyChangeListeners();
    }
  }

  /// Refreshes only external calendar events without clearing other cached data.
  /// Use this when external calendar settings change (enable/disable) to avoid
  /// losing homework/event data needed by the Todos table.
  Future<void> refreshExternalCalendarEvents({
    DateTime? visibleStart,
    DateTime? visibleEnd,
  }) async {
    _isRefreshing = true;
    _notifyChangeListeners();

    try {
      _log.info('Refreshing external calendar events only');

      if (visibleStart != null && visibleEnd != null) {
        final newEvents = await externalCalendarRepository.getExternalCalendarEvents(
          from: visibleStart,
          to: visibleEnd,
          shownOnCalendar: true,
          forceRefresh: true,
        );

        for (final entry in _dateRangeCache.entries) {
          final items = entry.value;
          items.removeWhere((item) => item is ExternalCalendarEventModel);

          final parts = entry.key.split('_');
          final rangeStart = DateTime.parse(parts[0]);
          final rangeEnd = DateTime.parse(parts[1]);

          for (final event in newEvents) {
            if (event.start.isBefore(rangeEnd) && event.end.isAfter(rangeStart)) {
              items.add(event);
            }
          }
        }
      }

      if (PlannerItemDataSource.filterDebounceDuration == Duration.zero) {
        _applyFiltersSynchronously();
      } else {
        await _applyFiltersAsync();
      }
    } finally {
      _isRefreshing = false;
      _notifyChangeListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _filterDebounceTimer?.cancel();
    _changeNotifier.dispose();
    super.dispose();
  }

  bool get hasLoadedInitialData => _hasLoadedInitialData;

  Map<int, bool> get filteredCourses => _filteredCourses;

  List<String> get filterCategories => _filterCategories;

  List<String> get filterTypes => _filterTypes;

  Set<String> get filterStatuses => _filterStatuses;

  String get searchQuery => _searchQuery;

  int get todosItemsPerPage => _todosItemsPerPage;

  set todosItemsPerPage(int value) {
    if (_todosItemsPerPage != value) {
      _todosItemsPerPage = value;
      _saveFiltersIfEnabled();
    }
  }

  Map<int, bool> get completedOverrides =>
      Map.unmodifiable(_completedOverrides);

  /// Returns all planner items from all cached date ranges, deduplicated by type and id.
  ///
  /// [ExternalCalendarEventModel] uses a content-based key (ownerId + start + title)
  /// instead of the platform-assigned id because the backend synthesizes sequential
  /// ids per-request, making them unstable across different date-range queries. Once
  /// the backend is updated to derive stable ids from the ICS event UID, this special
  /// case can be removed and all types can use the standard type:id key.
  List<PlannerItemBaseModel> get allPlannerItems {
    final seen = <String>{};
    final items = <PlannerItemBaseModel>[];
    for (final rangeItems in _dateRangeCache.values) {
      for (final item in rangeItems) {
        final String key;
        if (item is ExternalCalendarEventModel) {
          key = 'ExternalCalendarEventModel:${item.ownerId}:${item.start.millisecondsSinceEpoch}:${item.title}';
        } else {
          key = '${item.runtimeType}:${item.id}';
        }
        if (seen.add(key)) {
          items.add(item);
        }
      }
    }
    return items;
  }

  /// Returns items that occur on [day] from the current filtered appointments.
  /// Recurring schedule items are expanded into day-specific occurrences.
  List<PlannerItemBaseModel> getItemsForDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final itemsForDay = <PlannerItemBaseModel>[];

    for (final appointment in appointments ?? const <Object>[]) {
      if (appointment is! PlannerItemBaseModel) {
        continue;
      }

      if (appointment is CourseScheduleEventModel &&
          (appointment.recurrenceRule?.isNotEmpty ?? false)) {
        final occurrences = SfCalendar.getRecurrenceDateTimeCollection(
          appointment.recurrenceRule!,
          appointment.start,
          specificStartDate: dayStart,
          specificEndDate: dayEnd,
        );

        for (final occurrenceStart in occurrences) {
          final isSameDay =
              occurrenceStart.year == dayStart.year &&
              occurrenceStart.month == dayStart.month &&
              occurrenceStart.day == dayStart.day;
          if (!isSameDay) {
            continue;
          }

          final isException = appointment.exceptionDates.any(
            (e) =>
                e.year == occurrenceStart.year &&
                e.month == occurrenceStart.month &&
                e.day == occurrenceStart.day,
          );
          if (isException) {
            continue;
          }

          final duration = appointment.end.difference(appointment.start);
          itemsForDay.add(
            CourseScheduleEventModel(
              id: appointment.id,
              title: appointment.title,
              allDay: appointment.allDay,
              showEndTime: appointment.showEndTime,
              start: occurrenceStart,
              end: occurrenceStart.add(duration),
              priority: appointment.priority,
              url: appointment.url,
              comments: appointment.comments,
              attachments: appointment.attachments,
              reminders: appointment.reminders,
              color: appointment.color,
              ownerId: appointment.ownerId,
              recurrenceRule: appointment.recurrenceRule,
              exceptionDates: appointment.exceptionDates,
            ),
          );
        }
        continue;
      }

      // Include any item that overlaps with the target day, not just items that
      // start on the day. Multi-day events (allDay or timed) span multiple cells
      // in month view and must be counted for each day they cover.
      if (appointment.start.isBefore(dayEnd) &&
          appointment.end.isAfter(dayStart)) {
        itemsForDay.add(appointment);
      }
    }

    Sort.byStartThenTitleForDay(itemsForDay, dayStart);
    return itemsForDay;
  }

  @override
  PlannerItemBaseModel? convertAppointmentToObject(
    PlannerItemBaseModel? customData,
    Appointment appointment,
  ) {
    return customData;
  }

  @override
  Object? getId(int index) {
    return _getData(index).id;
  }

  DateTime _effectiveStart(PlannerItemBaseModel item) {
    final override = _timeOverrides[item.id];
    return override != null ? DateTime.parse(override.start) : item.start;
  }

  DateTime _effectiveEnd(PlannerItemBaseModel item) {
    final override = _timeOverrides[item.id];
    return override != null ? DateTime.parse(override.end) : item.end;
  }

  /// Returns the position of a timed item at [index] within its minute-level
  /// group — how many preceding timed items share the same date + hour + minute.
  /// Used to assign distinct seconds offsets so SfCalendar preserves our sort
  /// order for timed items with identical start times.
  int _timedPositionInGroup(int index, PlannerItemBaseModel item) {
    final baseMinute = DateTime(
      item.start.year, item.start.month, item.start.day,
      item.start.hour, item.start.minute,
    );
    int position = 0;
    for (int i = 0; i < index; i++) {
      final other = _getData(i);
      if (!other.allDay) {
        final otherMinute = DateTime(
          other.start.year, other.start.month, other.start.day,
          other.start.hour, other.start.minute,
        );
        if (otherMinute == baseMinute) position++;
      }
    }
    return position;
  }

  /// Returns the position of an all-day item at [index] within its day group —
  /// how many preceding all-day items share the same date. Used to assign
  /// distinct seconds offsets in month view (where all-day items are reported
  /// as timed) so SfCalendar preserves our sort order for same-type all-day
  /// items that would otherwise have identical start times.
  int _allDayPositionInGroup(int index, PlannerItemBaseModel item) {
    final baseDate = DateTime(
      item.start.year, item.start.month, item.start.day,
    );
    int position = 0;
    for (int i = 0; i < index; i++) {
      final other = _getData(i);
      if (other.allDay) {
        final otherDate = DateTime(
          other.start.year, other.start.month, other.start.day,
        );
        if (otherDate == baseDate) position++;
      }
    }
    return position;
  }

  @override
  DateTime getStartTime(int index) {
    final item = _getData(index);
    final override = _timeOverrides[item.id];
    final baseTime = tz.TZDateTime.from(
      override != null ? DateTime.parse(override.start) : item.start,
      userSettings.timeZone,
    );
    final priority = Sort.typeSortPriority[item.plannerItemType] ?? 0;
    if (item.allDay) {
      // In month view, all-day items are reported as timed (see isAllDay).
      // Encode type priority as minutes and intra-type position as seconds so
      // SfCalendar has fully distinct start times to sort by within a day.
      final position = _allDayPositionInGroup(index, item);
      return baseTime.add(Duration(minutes: priority, seconds: position));
    }
    final adjustment = Sort.getTimedEventStartTimeAdjustmentSeconds(
      priority,
      _timedPositionInGroup(index, item),
    );
    return baseTime.subtract(Duration(seconds: adjustment));
  }

  @override
  DateTime getEndTime(int index) {
    final plannerItem = _getData(index);
    final override = _timeOverrides[plannerItem.id];
    final startTime = tz.TZDateTime.from(
      override != null ? DateTime.parse(override.start) : plannerItem.start,
      userSettings.timeZone,
    );
    final endTime = tz.TZDateTime.from(
      override != null ? DateTime.parse(override.end) : plannerItem.end,
      userSettings.timeZone,
    );
    if (plannerItem.allDay) {
      final priority = Sort.typeSortPriority[plannerItem.plannerItemType] ?? 0;
      final position = _allDayPositionInGroup(index, plannerItem);
      final offset = Duration(minutes: priority, seconds: position);
      if (_isMonthView) {
        // Month view: isAllDay returns false so SfCalendar treats these as timed.
        // Subtract 1 second to convert exclusive end (next day 00:00) to
        // inclusive end (23:59:59) so the event stays within the correct day cell.
        final adjustedStart = startTime.add(offset);
        final adjustedEnd = endTime.subtract(const Duration(seconds: 1));
        return adjustedEnd.isBefore(adjustedStart) ? adjustedStart : adjustedEnd;
      }
      // Week/day view: isAllDay returns true; subtract 1 day for SfCalendar's
      // exclusive end convention for all-day items.
      final adjustedStart = startTime.add(offset);
      final adjustedEnd = endTime.subtract(const Duration(days: 1)).add(offset);
      return adjustedEnd.isBefore(adjustedStart) ? adjustedStart : adjustedEnd;
    }
    // Timed: apply same adjustment as getStartTime so visual duration is preserved.
    final priority = Sort.typeSortPriority[plannerItem.plannerItemType] ?? 0;
    final adjustment = Sort.getTimedEventEndTimeAdjustment(
      priority,
      _timedPositionInGroup(index, plannerItem),
    );
    return endTime.subtract(adjustment);
  }

  @override
  bool isAllDay(int index) {
    // In month view, report all-day items as timed so SfCalendar uses
    // getStartTime for ordering (see isMonthView setter for full explanation).
    final item = _getData(index);
    if (_isMonthView && item.allDay) return false;
    return item.allDay;
  }

  @override
  String getSubject(int index) {
    return _getData(index).title;
  }

  @override
  Color getColor(int index) {
    return getColorForItem(_getData(index));
  }

  @override
  String? getRecurrenceRule(int index) {
    final item = _getData(index);
    if (item is CourseScheduleEventModel) {
      return item.recurrenceRule;
    }
    return null;
  }

  @override
  List<DateTime>? getRecurrenceExceptionDates(int index) {
    final item = _getData(index);
    if (item is CourseScheduleEventModel && item.exceptionDates.isNotEmpty) {
      return item.exceptionDates;
    }
    return null;
  }

  Color getColorForItem(PlannerItemBaseModel plannerItem) {
    if (plannerItem is EventModel) {
      return userSettings.eventsColor;
    } else if (plannerItem is HomeworkModel) {
      if (userSettings.colorByCategory) {
        final category = categoriesMap?[plannerItem.category.id];
        if (category != null) {
          return category.color;
        }
      }

      // Get course color, or fallback
      final course = courses?.firstWhereOrNull(
        (c) => c.id == plannerItem.course.id,
      );
      return course?.color ?? FallbackConstants.fallbackColor;
    } else {
      return plannerItem.color ?? FallbackConstants.fallbackColor;
    }
  }

  String _cacheKey(DateTime from, DateTime to) {
    // API query parameters are date-only, so cache keys can be the same
    final fromKey = DateTime(from.year, from.month, from.day);
    final toKey = DateTime(to.year, to.month, to.day);
    return '${fromKey.toIso8601String()}_${toKey.toIso8601String()}';
  }

  String? getLocationForItem(PlannerItemBaseModel plannerItem) {
    if (plannerItem is HomeworkModel) {
      final course = courses?.firstWhereOrNull(
        (c) => c.id == plannerItem.course.id,
      );
      return course?.room;
    } else if (plannerItem is CourseScheduleEventModel) {
      final courseId = int.tryParse(plannerItem.ownerId);
      final course = courses?.firstWhereOrNull((c) => c.id == courseId);
      return course?.room;
    } else {
      return plannerItem.location;
    }
  }

  @override
  Future<void> handleLoadMore(
    DateTime startDate,
    DateTime endDate, {
    bool forceRefresh = false,
  }) async {
    final key = _cacheKey(startDate, endDate);

    if (forceRefresh || !_dateRangeCache.containsKey(key)) {
      // Convert dates to TZDateTime in user's timezone at midnight.
      // This ensures date boundaries are interpreted consistently on the backend.
      final tzStartDate = tz.TZDateTime(
        userSettings.timeZone,
        startDate.year,
        startDate.month,
        startDate.day,
      );
      final tzEndDate = tz.TZDateTime(
        userSettings.timeZone,
        endDate.year,
        endDate.month,
        endDate.day,
      );

      final results = await Future.wait([
        homeworkRepository.getHomeworks(
          from: tzStartDate,
          to: tzEndDate,
          shownOnCalendar: true,
          forceRefresh: forceRefresh,
        ),
        eventRepository.getEvents(
          from: startDate,
          to: endDate,
          forceRefresh: forceRefresh,
        ),
        courseScheduleRepository.getCourseScheduleEvents(
          courses: courses ?? [],
          from: startDate,
          to: endDate,
          courseGroupsById: courseGroupsById,
          shownOnCalendar: true,
          forceRefresh: forceRefresh,
        ),
        externalCalendarRepository.getExternalCalendarEvents(
          from: startDate,
          to: endDate,
          shownOnCalendar: true,
          forceRefresh: forceRefresh,
        ),
      ]);
      final homeworks = results[0] as List<HomeworkModel>;
      final events = results[1] as List<EventModel>;
      final courseScheduleEvents = results[2] as List<CourseScheduleEventModel>;
      final externalCalendarEvents =
          results[3] as List<ExternalCalendarEventModel>;

      final plannerItems = [
        ...events,
        ...homeworks,
        ...courseScheduleEvents,
        ...externalCalendarEvents,
      ];
      _log.fine(
        'Fetched ${homeworks.length} homeworks, ${events.length} events, '
        '${courseScheduleEvents.length} schedule events, '
        '${externalCalendarEvents.length} external events',
      );

      _dateRangeCache[key] = plannerItems;
    } else {
      _log.fine('Items for date range already cached: $startDate to $endDate');
    }

    if (filterDebounceDuration == Duration.zero) {
      _applyFiltersSynchronously();
    } else {
      await _applyFiltersAsync();
    }

    if (!_hasLoadedInitialData) {
      _hasLoadedInitialData = true;
      try {
        // Defer initial notifyListeners to avoid calling it while SfCalendar
        // is still performing its first layout; falls back to sync if binding
        // is unavailable (e.g., during tests)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _notifyChangeListeners();
        });
      } catch (_) {
        _notifyChangeListeners();
      }
    }
  }

  PlannerItemBaseModel _getData(int index) {
    return appointments![index] as PlannerItemBaseModel;
  }

  List<HomeworkModel> get allHomeworks =>
      allPlannerItems.whereType<HomeworkModel>().toList();

  List<EventModel> get allEvents =>
      allPlannerItems.whereType<EventModel>().toList();

  List<CourseScheduleEventModel> get allCourseScheduleEvents =>
      allPlannerItems.whereType<CourseScheduleEventModel>().toList();

  List<ExternalCalendarEventModel> get allExternalCalendarEvents =>
      allPlannerItems.whereType<ExternalCalendarEventModel>().toList();

  List<HomeworkModel> get filteredHomeworks {
    var homeworks = allHomeworks;

    homeworks = _applyCourseFilter(homeworks);
    homeworks = _applyCategoryFilter(homeworks);
    homeworks = _applyStatusFilter(homeworks);
    homeworks = _applySearchFilter(homeworks);

    return homeworks;
  }

  List<PlannerItemBaseModel> get _filteredPlannerItems {
    final items = <PlannerItemBaseModel>[];
    final includeAllTypes = _filterTypes.isEmpty;

    if (includeAllTypes ||
        _filterTypes.contains(PlannerFilterType.assignments.value)) {
      items.addAll(filteredHomeworks);
    }

    if (includeAllTypes ||
        _filterTypes.contains(PlannerFilterType.events.value)) {
      items.addAll(_applySearchFilterToItems(allEvents));
    }

    if (includeAllTypes ||
        _filterTypes.contains(PlannerFilterType.classSchedules.value)) {
      final courseScheduleEvents = allCourseScheduleEvents
          .where(_applyCourseFilterToCourseScheduleEvent)
          .toList();
      items.addAll(_applySearchFilterToItems(courseScheduleEvents));
    }

    // ExternalCalendar events - apply search filter only
    if (includeAllTypes ||
        _filterTypes.contains(PlannerFilterType.externalCalendars.value)) {
      items.addAll(_applySearchFilterToItems(allExternalCalendarEvents));
    }

    // Sort using effective (override-aware) times so drag-drop optimistic
    // positioning matches the list order SfCalendar reads from getStartTime.
    items.sort((a, b) => Sort.comparePlannerItems(
      aType: a.plannerItemType,
      bType: b.plannerItemType,
      aAllDay: a.allDay,
      bAllDay: b.allDay,
      aStart: _effectiveStart(a),
      bStart: _effectiveStart(b),
      aEnd: _effectiveEnd(a),
      bEnd: _effectiveEnd(b),
      aTitle: a.title,
      bTitle: b.title,
      aCourseId: a is HomeworkModel ? a.course.id : null,
      bCourseId: b is HomeworkModel ? b.course.id : null,
    ));
    return items;
  }

  List<T> _applySearchFilterToItems<T extends PlannerItemBaseModel>(
    List<T> items,
  ) {
    if (_searchQuery.isEmpty) return items;

    final query = _searchQuery.toLowerCase();
    return items.where((item) => _matchesSearch(item, query)).toList();
  }

  void setFilteredCourses(Map<int, bool> courses) {
    final selectedCourses = courses.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    _log.info(
      'Course filter changed: ${selectedCourses.isEmpty ? "all" : selectedCourses.join(", ")}',
    );
    _filteredCourses = courses;
    _saveFiltersIfEnabled();
    _applyFiltersAndNotify();
  }

  void setFilterCategories(List<String> categories) {
    _log.info(
      'Category filter changed: ${categories.isEmpty ? "all" : categories.join(", ")}',
    );
    _filterCategories = categories;
    _saveFiltersIfEnabled();
    _applyFiltersAndNotify();
  }

  void setFilterTypes(List<String> types) {
    _log.info(
      'Type filter changed: ${types.isEmpty ? "all" : types.join(", ")}',
    );
    _filterTypes = types;
    _saveFiltersIfEnabled();
    _applyFiltersAndNotify();
  }

  void setFilterStatuses(Set<String> statuses) {
    _log.info(
      'Status filter changed: ${statuses.isEmpty ? "all" : statuses.join(", ")}',
    );
    _filterStatuses = statuses;
    _saveFiltersIfEnabled();
    _applyFiltersAndNotify();
  }

  void setSearchQuery(String query) {
    _log.info('Search query changed: "${query.isEmpty ? "(empty)" : query}"');
    _searchQuery = query;
    _applyFiltersAndNotify();
  }

  void clearFilters() {
    _log.info('All filters cleared');
    _filteredCourses = {};
    _filterCategories = [];
    _filterTypes = [];
    _filterStatuses = {};
    _saveFiltersIfEnabled();
    _applyFiltersAndNotify();
  }

  void _saveFiltersIfEnabled() {
    if (!userSettings.rememberFilterState) return;

    final filterState = {
      'filteredCourses': _filteredCourses.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'filterCategories': _filterCategories,
      'filterTypes': _filterTypes,
      'filterStatuses': _filterStatuses.toList(),
    };

    PrefService().setString('saved_filter_state', jsonEncode(filterState));
    PrefService().setInt('saved_rows_per_page', _todosItemsPerPage);
    _log.fine('Filter state saved');
  }

  void restoreFiltersIfEnabled() {
    if (!userSettings.rememberFilterState) return;

    final savedItemsPerPage = PrefService().getInt('saved_rows_per_page');
    if (savedItemsPerPage != null) {
      _todosItemsPerPage = savedItemsPerPage;
    }

    final savedState = PrefService().getString('saved_filter_state');
    if (savedState == null) return;

    try {
      final filterState = jsonDecode(savedState) as Map<String, dynamic>;

      final savedCourses =
          filterState['filteredCourses'] as Map<String, dynamic>?;
      if (savedCourses != null) {
        _filteredCourses = savedCourses.map(
          (key, value) => MapEntry(int.parse(key), value as bool),
        );
      }

      final savedCategories = filterState['filterCategories'] as List<dynamic>?;
      if (savedCategories != null) {
        _filterCategories = savedCategories.cast<String>();
      }

      final savedTypes = filterState['filterTypes'] as List<dynamic>?;
      if (savedTypes != null) {
        _filterTypes = savedTypes.cast<String>();
      }

      final savedStatuses = filterState['filterStatuses'] as List<dynamic>?;
      if (savedStatuses != null) {
        _filterStatuses = savedStatuses.cast<String>().toSet();
      }

      _log.info('Filter state restored');
    } catch (e) {
      _log.warning('Failed to restore filter state', e);
    }
  }

  void addPlannerItem(PlannerItemBaseModel plannerItem) {
    for (final items in _dateRangeCache.values) {
      if (items.any((existing) => existing.id == plannerItem.id)) {
        return;
      }
    }

    _log.info(
      'Calendar item added: ${plannerItem.runtimeType} ${plannerItem.id} "${plannerItem.title}"',
    );

    final itemStart = plannerItem.start;
    final itemEnd = plannerItem.end;

    for (final entry in _dateRangeCache.entries) {
      final parts = entry.key.split('_');
      final rangeStart = DateTime.parse(parts[0]);
      final rangeEnd = DateTime.parse(parts[1]);

      if (itemStart.isBefore(rangeEnd) && itemEnd.isAfter(rangeStart)) {
        entry.value.add(plannerItem);
      }
    }

    if (!appointments!.any(
      (item) => (item as PlannerItemBaseModel).id == plannerItem.id,
    )) {
      appointments!.add(plannerItem);
      Sort.byStartThenTitle(appointments!.cast<PlannerItemBaseModel>());
      if (!_isDisposed) {
        notifyListeners(CalendarDataSourceAction.reset, appointments!);
      }
    }

    _applyFiltersAndNotify();
  }

  void updatePlannerItem(PlannerItemBaseModel plannerItem) {
    bool updated = false;

    for (final items in _dateRangeCache.values) {
      final index = items.indexWhere(
        (existing) => existing.id == plannerItem.id,
      );
      if (index != -1) {
        items[index] = plannerItem;
        updated = true;
      }
    }

    if (updated) {
      _log.info(
        'Calendar item updated: ${plannerItem.runtimeType} ${plannerItem.id} "${plannerItem.title}"',
      );
    }

    if (plannerItem is HomeworkModel) {
      _completedOverrides.remove(plannerItem.id);
    }
    _timeOverrides.remove(plannerItem.id);

    final oldIndex = appointments!.indexWhere(
      (item) => (item as PlannerItemBaseModel).id == plannerItem.id,
    );

    if (oldIndex != -1) {
      appointments![oldIndex] = plannerItem;
      Sort.byStartThenTitle(appointments!.cast<PlannerItemBaseModel>());
      if (!_isDisposed) {
        notifyListeners(CalendarDataSourceAction.reset, appointments!);
      }
    } else {
      _applyFiltersAndNotify();
    }

    _notifyChangeListeners();
  }

  void removePlannerItem(int plannerItemId) {
    PlannerItemBaseModel? removedItem;

    for (final items in _dateRangeCache.values) {
      final index = items.indexWhere(
        (existing) => existing.id == plannerItemId,
      );
      if (index != -1) {
        removedItem ??= items[index];
        items.removeAt(index);
      }
    }

    if (removedItem != null) {
      _log.info(
        'Calendar item removed: ${removedItem.runtimeType} $plannerItemId "${removedItem.title}"',
      );
      appointments!.remove(removedItem);
      _completedOverrides.remove(plannerItemId);
      if (!_isDisposed) {
        notifyListeners(CalendarDataSourceAction.remove, [removedItem]);
      }
      _notifyChangeListeners();
    }
  }

  // Optimistic UI methods
  void setCompletedOverride(int homeworkId, bool completed) {
    _completedOverrides[homeworkId] = completed;
    _notifyChangeListeners();
    _applyFiltersAndNotify();
  }

  void clearCompletedOverride(int homeworkId) {
    _completedOverrides.remove(homeworkId);
    _notifyChangeListeners();
  }

  /// Optimistic override for drag-drop/resize. Updates getStartTime/getEndTime
  /// immediately so the item visually snaps to the new position before the API
  /// responds. Rebuilds appointments! synchronously from source-of-truth so the
  /// current frame renders at the new position. Safe to call synchronously
  /// because it is only ever called from event callbacks (onDragEnd,
  /// onAppointmentResizeEnd), not during build or paint.
  void setTimeOverride(int itemId, String start, String end) {
    _timeOverrides[itemId] = PlannerItemTimeOverride(start: start, end: end);
    if (_isDisposed || appointments == null) return;
    appointments!.clear();
    appointments!.addAll(_filteredPlannerItems);
    notifyListeners(CalendarDataSourceAction.reset, appointments!);
    // SfCalendar caches the formatted time label on its internal appointment
    // object and doesn't refresh it from getStartTime on a reset notification.
    // A post-frame remove+add forces it to fully reconstruct the appointment,
    // including the displayed time label.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed || appointments == null) return;
      final item = appointments!.firstWhereOrNull(
        (a) => (a as PlannerItemBaseModel).id == itemId,
      );
      if (item == null) return;
      // remove+add refreshes SfCalendar's cached time label for this item.
      // The follow-up reset restores correct list order — add always appends
      // to the end of SfCalendar's internal list, causing a one-frame flash
      // where the item appears last before the reset re-sorts it.
      notifyListeners(CalendarDataSourceAction.remove, [item]);
      notifyListeners(CalendarDataSourceAction.add, [item]);
      notifyListeners(CalendarDataSourceAction.reset, appointments!);
    });
    _notifyChangeListeners();
  }

  /// Discards any rogue copies SfCalendar appended to appointments! during a
  /// drag-drop gesture on a locked item (e.g., a recurring CourseScheduleEvent).
  ///
  /// Both the list cleanup and notifyListeners(reset) are synchronous. SfCalendar
  /// sets _visibleAppointments synchronously when it fires its own add
  /// notifications (before calling onDragEnd), so we must also reset it
  /// synchronously — before the current frame renders — or a one-frame duplicate
  /// flicker appears. This is safe because resetAppointments() is only ever
  /// called from event callbacks (onDragEnd, onAppointmentResizeEnd), not during
  /// build or paint.
  void resetAppointments() {
    if (_isDisposed || appointments == null) return;
    appointments!.clear();
    appointments!.addAll(_filteredPlannerItems);
    notifyListeners(CalendarDataSourceAction.reset, appointments!);
    // SfCalendar may fire a remove notification after onDragEnd returns (e.g.,
    // same-day RRULE drop in month view treats the occurrence as an exception
    // and removes the master from its internal list). The post-frame reset
    // catches that and restores the full series.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed || appointments == null) return;
      appointments!.clear();
      appointments!.addAll(_filteredPlannerItems);
      notifyListeners(CalendarDataSourceAction.reset, appointments!);
    });
  }

  bool isHomeworkCompleted(HomeworkModel homework) {
    // Check override first
    if (_completedOverrides.containsKey(homework.id)) {
      return _completedOverrides[homework.id]!;
    }

    // Look up from cache to get freshest value, avoiding stale data that
    // SfCalendar might pass during drag-drop rebuilds
    final cachedHomework = allHomeworks.firstWhereOrNull(
      (h) => h.id == homework.id,
    );

    return cachedHomework?.completed ?? homework.completed;
  }

  bool _isHomeworkGraded(HomeworkModel homework) {
    return GradeHelper.parseGrade(homework.currentGrade) != null;
  }

  /// Schedules filter application with debouncing to prevent the UI from
  /// hanging. Use compute() to run filtering on a background isolate.
  void _applyFiltersAndNotify() {
    _filterDebounceTimer?.cancel();

    if (filterDebounceDuration == Duration.zero) {
      // Synchronous mode (for testing) - skip compute() overhead
      _applyFiltersSynchronously();
    } else {
      _filterCompleter ??= Completer<void>();
      _filterDebounceTimer = Timer(filterDebounceDuration, () {
        _applyFiltersAsync();
      });
    }
  }

  /// Synchronous filtering for tests. Uses the same logic as async version
  /// but runs on the main thread without compute().
  void _applyFiltersSynchronously() {
    appointments!.clear();
    appointments!.addAll(_filteredPlannerItems);

    _log.fine(
      'Filters applied (sync): ${appointments!.length} of ${allPlannerItems.length} items visible',
    );
    if (!_isDisposed) {
      notifyListeners(CalendarDataSourceAction.reset, appointments!);
    }
    _notifyChangeListeners();
  }

  /// Waits for any pending filter operations to complete
  Future<void> waitForFilters() async {
    _filterDebounceTimer?.cancel();
    _filterDebounceTimer = null;
    if (_filterCompleter != null && !_filterCompleter!.isCompleted) {
      await _applyFiltersAsync();
    }
  }

  Future<void> _applyFiltersAsync() async {
    if (_isFilteringInProgress) return;
    _isFilteringInProgress = true;
    _isRefreshing = true;
    // Defer notification to avoid triggering rebuild during build phase
    // (handleLoadMore can be called during SfCalendar's layout)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyChangeListeners();
    });

    final completer = _filterCompleter;
    _filterCompleter = null;

    try {
      final items = allPlannerItems;
      final filterableItems = _convertToFilterableItems(items);

      final params = FilterParams(
        filterTypes: _filterTypes,
        filterCategories: _filterCategories,
        selectedCourseIds: _getSelectedCourseIds(),
        filterStatuses: _filterStatuses,
        searchQuery: _searchQuery,
        categoryIdToTitle: _buildCategoryIdToTitleMap(),
        completedOverrides: Map.from(_completedOverrides),
      );

      final input = FilterComputeInput(items: filterableItems, params: params);

      // Run filtering and sorting on background isolate
      final filteredIndices = await compute(computeFilteredItems, input);

      // Map indices back to original items
      final filteredItems = filteredIndices
          .map((index) => items[index])
          .toList();

      appointments!.clear();
      appointments!.addAll(filteredItems);

      _log.fine(
        'Filters applied: ${appointments!.length} of ${items.length} items visible',
      );
      if (!_isDisposed) {
        notifyListeners(CalendarDataSourceAction.reset, appointments!);
      }
      _notifyChangeListeners();
      completer?.complete();
    } catch (e) {
      completer?.completeError(e);
      rethrow;
    } finally {
      _isFilteringInProgress = false;
      _isRefreshing = false;
    }
  }

  List<FilterableItem> _convertToFilterableItems(
    List<PlannerItemBaseModel> items,
  ) {
    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      PlannerItemType type;
      int? courseId;
      int? categoryId;
      String? ownerId;
      bool completed = false;
      bool graded = false;

      if (item is HomeworkModel) {
        type = PlannerItemType.homework;
        courseId = item.course.id;
        categoryId = item.category.id;
        completed = item.completed;
        graded = _isHomeworkGraded(item);
      } else if (item is EventModel) {
        type = PlannerItemType.event;
      } else if (item is CourseScheduleEventModel) {
        type = PlannerItemType.courseSchedule;
        ownerId = item.ownerId;
      } else if (item is ExternalCalendarEventModel) {
        type = PlannerItemType.external;
        ownerId = item.ownerId;
      } else {
        type = PlannerItemType.event;
      }

      return FilterableItem(
        id: item.id,
        index: index,
        type: type,
        title: item.title,
        start: item.start,
        end: item.end,
        allDay: item.allDay,
        completed: completed,
        graded: graded,
        courseId: courseId,
        categoryId: categoryId,
        ownerId: ownerId,
      );
    }).toList();
  }

  Map<int, String> _buildCategoryIdToTitleMap() {
    if (categoriesMap == null) return {};
    return categoriesMap!.map((id, category) => MapEntry(id, category.title));
  }

  bool _hasSelectedCourses() {
    if (_filteredCourses.isEmpty) return false;
    return _filteredCourses.values.any((isSelected) => isSelected);
  }

  Set<int> _getSelectedCourseIds() {
    if (_filteredCourses.isEmpty) return {};
    return _filteredCourses.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toSet();
  }

  List<HomeworkModel> _applyCourseFilter(List<HomeworkModel> homeworks) {
    if (!_hasSelectedCourses()) return homeworks;

    final selectedCourseIds = _getSelectedCourseIds();
    if (selectedCourseIds.isEmpty) return homeworks;

    return homeworks
        .where((homework) => selectedCourseIds.contains(homework.course.id))
        .toList();
  }

  bool _applyCourseFilterToCourseScheduleEvent(CourseScheduleEventModel event) {
    if (!_hasSelectedCourses()) return true;

    final selectedCourseIds = _getSelectedCourseIds();
    if (selectedCourseIds.isEmpty) return true;

    // ownerId is now just the course ID (e.g., "42")
    final courseId = int.tryParse(event.ownerId);
    return courseId == null || selectedCourseIds.contains(courseId);
  }

  List<HomeworkModel> _applyCategoryFilter(List<HomeworkModel> homeworks) {
    if (_filterCategories.isEmpty) return homeworks;

    return homeworks.where((homework) {
      final category = homework.category;
      final String title;
      if (category.entity != null) {
        title = category.entity!.title;
      } else if (categoriesMap != null &&
          categoriesMap!.containsKey(category.id)) {
        title = categoriesMap![category.id]!.title;
      } else {
        return false;
      }
      if (title.trim().isEmpty) {
        return false;
      }
      return _filterCategories.contains(title);
    }).toList();
  }

  List<HomeworkModel> _applyStatusFilter(List<HomeworkModel> homeworks) {
    if (_filterStatuses.isEmpty) return homeworks;

    return homeworks.where((homework) {
      // While the user is actively toggling completion, always keep the item visible
      if (_completedOverrides.containsKey(homework.id)) return true;

      bool matches = false;
      final isCompleted = isHomeworkCompleted(homework);

      if (_filterStatuses.contains(PlannerFilterStatus.complete.value)) {
        matches = matches || isCompleted;
      }
      if (_filterStatuses.contains(PlannerFilterStatus.incomplete.value)) {
        matches = matches || !isCompleted;
      }
      if (_filterStatuses.contains(PlannerFilterStatus.overdue.value)) {
        final bool isOverdue =
            !isCompleted && homework.start.isBefore(DateTime.now());
        matches = matches || isOverdue;
      }
      if (_filterStatuses.contains(PlannerFilterStatus.graded.value)) {
        matches = matches || _isHomeworkGraded(homework);
      }
      if (_filterStatuses.contains(PlannerFilterStatus.ungraded.value)) {
        matches = matches || !_isHomeworkGraded(homework);
      }
      return matches;
    }).toList();
  }

  List<HomeworkModel> _applySearchFilter(List<HomeworkModel> homeworks) {
    if (_searchQuery.isEmpty) return homeworks;

    final query = _searchQuery.toLowerCase();
    return homeworks.where((homework) {
      return _matchesSearch(homework, query);
    }).toList();
  }

  bool _matchesSearch(PlannerItemBaseModel item, String query) {
    return item.title.toLowerCase().contains(query);
  }
}

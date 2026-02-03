// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/data/models/planner/calendar_item_base_model.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_event_model.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/external_calendar_event_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/domain/repositories/course_schedule_event_repository.dart';
import 'package:heliumapp/domain/repositories/event_repository.dart';
import 'package:heliumapp/domain/repositories/external_calendar_repository.dart';
import 'package:heliumapp/domain/repositories/homework_repository.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarItemDataSource extends CalendarDataSource<CalendarItemBaseModel> {
  final EventRepository eventRepository;
  final HomeworkRepository homeworkRepository;
  final CourseScheduleRepository courseScheduleRepository;
  final ExternalCalendarRepository externalCalendarRepository;
  final UserSettingsModel userSettings;

  final List<CalendarItemBaseModel> allCalendarItems = [];

  List<CourseModel>? courses;
  Map<int, CategoryModel>? categoriesMap;
  DateTime? from;
  DateTime? to;

  // State
  bool _hasLoadedInitialData = false;
  Map<String, bool> _filteredCourses = {};
  List<String> _filterCategories = [];
  List<String> _filterTypes = [];
  Set<String> _filterStatuses = {};
  String _searchQuery = '';
  final Map<int, bool> _completedOverrides = {};

  CalendarItemDataSource({
    required this.eventRepository,
    required this.homeworkRepository,
    required this.courseScheduleRepository,
    required this.externalCalendarRepository,
    required this.userSettings,
  }) {
    appointments = [];
  }

  final ChangeNotifier _changeNotifier = ChangeNotifier();

  Listenable get changeNotifier => _changeNotifier;

  void _notifyChangeListeners() {
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    _changeNotifier.notifyListeners();
  }

  bool get hasLoadedInitialData => _hasLoadedInitialData;

  Map<String, bool> get filteredCourses => _filteredCourses;

  List<String> get filterCategories => _filterCategories;

  List<String> get filterTypes => _filterTypes;

  Set<String> get filterStatuses => _filterStatuses;

  String get searchQuery => _searchQuery;

  Map<int, bool> get completedOverrides =>
      Map.unmodifiable(_completedOverrides);

  @override
  CalendarItemBaseModel? convertAppointmentToObject(
    CalendarItemBaseModel? customData,
    Appointment appointment,
  ) {
    return customData;
  }

  @override
  DateTime getStartTime(int index) {
    return DateTime.parse(_getData(index).start);
  }

  @override
  DateTime getEndTime(int index) {
    final calendarItem = _getData(index);
    final startTime = DateTime.parse(calendarItem.start);
    final endTime = DateTime.parse(calendarItem.end);

    if (calendarItem.allDay) {
      final adjustedEnd = endTime.subtract(const Duration(days: 1));
      return adjustedEnd.isBefore(startTime) ? startTime : adjustedEnd;
    }

    return endTime;
  }

  @override
  bool isAllDay(int index) {
    return _getData(index).allDay;
  }

  @override
  String getSubject(int index) {
    return _getData(index).title;
  }

  @override
  Color getColor(int index) {
    return getColorForItem(_getData(index));
  }

  Color getColorForItem(CalendarItemBaseModel calendarItem) {
    if (calendarItem is EventModel) {
      return userSettings.eventsColor;
    } else if (calendarItem is HomeworkModel) {
      return userSettings.colorByCategory
          ? categoriesMap![calendarItem.category.id]!.color
          : courses!.firstWhere((c) => c.id == calendarItem.course.id).color;
    } else {
      return calendarItem.color!;
    }
  }

  String? getLocationForItem(CalendarItemBaseModel calendarItem) {
    final String? location;
    if (calendarItem is HomeworkModel) {
      location = courses!
          .firstWhere((c) => c.id == calendarItem.course.id)
          .room;
    } else if (calendarItem is CourseScheduleEventModel) {
      location = courses!
          .firstWhere((c) => c.id.toString() == calendarItem.ownerId)
          .room;
    } else {
      location = calendarItem.location;
    }

    return location;
  }

  @override
  Future<void> handleLoadMore(DateTime startDate, DateTime endDate) async {
    bool windowPushed = false;
    if (from == null || startDate.isBefore(from!)) {
      windowPushed = true;
      from = startDate;
    }
    if (to == null || endDate.isAfter(to!)) {
      windowPushed = true;
      to = endDate;
    }

    // Fetch new data if the window expanded
    if (windowPushed) {
      final homeworks = await homeworkRepository.getHomeworks(
        from: from!,
        to: to!,
        shownOnCalendar: true,
      );
      final events = await eventRepository.getEvents(from: from, to: to);
      // TODO: remove this, we can obtains course schedule events by using SfCalendar's native repeating events concept, and reduce backend load (and eliminate the need for this data source function and API endpoint)
      final courseScheduleEvents = await courseScheduleRepository
          .getCourseScheduleEvents(from: from!, to: to!);
      final externalCalendarEvents = await externalCalendarRepository
          .getExternalCalendarEvents(from: from!, to: to!);

      final calendarItems = [
        ...events,
        ...homeworks,
        ...courseScheduleEvents,
        ...externalCalendarEvents,
      ];

      // Add only new items
      for (final CalendarItemBaseModel calendarItem in calendarItems) {
        if (!allCalendarItems.any((ca) => ca.id == calendarItem.id)) {
          allCalendarItems.add(calendarItem);
        }
      }
    }

    // Always rebuild appointments from filtered items to ensure consistency
    appointments!.clear();
    appointments!.addAll(_filteredCalendarItems);
    notifyListeners(CalendarDataSourceAction.reset, appointments!);

    if (!_hasLoadedInitialData) {
      _hasLoadedInitialData = true;
      try {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _notifyChangeListeners();
        });
      } catch (_) {
        // Binding not initialized (e.g., in tests), call directly
        _notifyChangeListeners();
      }
    }
  }

  CalendarItemBaseModel _getData(int index) {
    return appointments![index] as CalendarItemBaseModel;
  }

  // Typed getters for all items
  List<HomeworkModel> get allHomeworks =>
      allCalendarItems.whereType<HomeworkModel>().toList();

  List<EventModel> get allEvents =>
      allCalendarItems.whereType<EventModel>().toList();

  List<CourseScheduleEventModel> get allCourseScheduleEvents =>
      allCalendarItems.whereType<CourseScheduleEventModel>().toList();

  List<ExternalCalendarEventModel> get allExternalCalendarEvents =>
      allCalendarItems.whereType<ExternalCalendarEventModel>().toList();

  List<HomeworkModel> get filteredHomeworks {
    var homeworks = allHomeworks;

    homeworks = _applyCourseFilter(homeworks);
    homeworks = _applyCategoryFilter(homeworks);
    homeworks = _applyStatusFilter(homeworks);
    homeworks = _applySearchFilter(homeworks);

    return homeworks;
  }

  List<CalendarItemBaseModel> get _filteredCalendarItems {
    final items = <CalendarItemBaseModel>[];
    final includeAllTypes = _filterTypes.isEmpty;

    // Homeworks - use filteredHomeworks, which already has all filters applied
    if (includeAllTypes || _filterTypes.contains('Assignments')) {
      items.addAll(filteredHomeworks);
    }

    // Events - apply search filter only
    if (includeAllTypes || _filterTypes.contains('Events')) {
      items.addAll(_applySearchFilterToItems(allEvents));
    }

    // CourseSchedule events - apply course and search filters
    if (includeAllTypes || _filterTypes.contains('Class Schedules')) {
      final courseScheduleEvents = allCourseScheduleEvents
          .where(_applyCourseFilterToCourseScheduleEvent)
          .toList();
      items.addAll(_applySearchFilterToItems(courseScheduleEvents));
    }

    // ExternalCalendar events - apply search filter only
    if (includeAllTypes || _filterTypes.contains('External Calendars')) {
      items.addAll(_applySearchFilterToItems(allExternalCalendarEvents));
    }

    return items;
  }

  List<T> _applySearchFilterToItems<T extends CalendarItemBaseModel>(
    List<T> items,
  ) {
    if (_searchQuery.isEmpty) return items;

    final query = _searchQuery.toLowerCase();
    return items.where((item) => _matchesSearch(item, query)).toList();
  }

  void setFilteredCourses(Map<String, bool> courses) {
    _filteredCourses = courses;
    _applyFiltersAndNotify();
  }

  void setFilterCategories(List<String> categories) {
    _filterCategories = categories;
    _applyFiltersAndNotify();
  }

  void setFilterTypes(List<String> types) {
    _filterTypes = types;
    _applyFiltersAndNotify();
  }

  void setFilterStatuses(Set<String> statuses) {
    _filterStatuses = statuses;
    _applyFiltersAndNotify();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFiltersAndNotify();
  }

  void clearFilters() {
    _filterCategories = [];
    _filterTypes = [];
    _filterStatuses = {};
    _applyFiltersAndNotify();
  }

  void addCalendarItem(CalendarItemBaseModel calendarItem) {
    if (allCalendarItems.any((existing) => existing.id == calendarItem.id)) {
      return;
    }
    allCalendarItems.add(calendarItem);
    _applyFiltersAndNotify();
  }

  void updateCalendarItem(CalendarItemBaseModel calendarItem) {
    final index = allCalendarItems.indexWhere(
      (existing) => existing.id == calendarItem.id,
    );
    if (index != -1) {
      allCalendarItems[index] = calendarItem;
    }

    // Clear any completed override since we have the real data now
    if (calendarItem is HomeworkModel) {
      _completedOverrides.remove(calendarItem.id);
    }

    _applyFiltersAndNotify();
  }

  void removeCalendarItem(int calendarItemId) {
    final item = allCalendarItems.cast<CalendarItemBaseModel?>().firstWhere(
      (existing) => existing?.id == calendarItemId,
      orElse: () => null,
    );

    if (item != null) {
      allCalendarItems.remove(item);
      appointments!.remove(item);
      _completedOverrides.remove(calendarItemId);
      notifyListeners(CalendarDataSourceAction.remove, [item]);
      _notifyChangeListeners();
    }
  }

  // Optimistic UI methods
  void setCompletedOverride(int homeworkId, bool completed) {
    _completedOverrides[homeworkId] = completed;
    _notifyChangeListeners();
  }

  void clearCompletedOverride(int homeworkId) {
    _completedOverrides.remove(homeworkId);
    _notifyChangeListeners();
  }

  bool isHomeworkCompleted(HomeworkModel homework) {
    return _completedOverrides.containsKey(homework.id)
        ? _completedOverrides[homework.id]!
        : homework.completed;
  }

  void _applyFiltersAndNotify() {
    appointments!.clear();
    appointments!.addAll(_filteredCalendarItems);
    notifyListeners(CalendarDataSourceAction.reset, appointments!);
    _notifyChangeListeners();
  }

  /// Force SfCalendar to re-read all appointments, sometimes necessary when
  /// switching views.
  void refreshAppointments() {
    appointments!.clear();
    appointments!.addAll(_filteredCalendarItems);
    notifyListeners(CalendarDataSourceAction.reset, appointments!);
  }

  bool _hasSelectedCourses() {
    if (_filteredCourses.isEmpty) return false;
    return _filteredCourses.values.any((isSelected) => isSelected);
  }

  String _normalizeCourseTitle(String title) {
    return title.trim().toLowerCase();
  }

  Set<String> _getSelectedCourseTitleSet() {
    if (_filteredCourses.isEmpty) return {};
    return _filteredCourses.entries
        .where((entry) => entry.value)
        .map((entry) => _normalizeCourseTitle(entry.key))
        .toSet();
  }

  Set<int> _getSelectedCourseIds() {
    if (courses == null) return {};
    final selectedTitles = _getSelectedCourseTitleSet();
    if (selectedTitles.isEmpty) return {};

    final ids = <int>{};
    for (final course in courses!) {
      final normalized = _normalizeCourseTitle(course.title);
      if (selectedTitles.contains(normalized)) {
        ids.add(course.id);
      }
    }
    return ids;
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

    final courseId = int.tryParse(event.ownerId);
    if (courseId == null) return true;

    return selectedCourseIds.contains(courseId);
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

      if (_filterStatuses.contains('Complete')) {
        matches = matches || isCompleted;
      }
      if (_filterStatuses.contains('Incomplete')) {
        matches = matches || !isCompleted;
      }
      if (_filterStatuses.contains('Overdue')) {
        final bool isOverdue =
            !isCompleted &&
            DateTime.parse(homework.start).isBefore(DateTime.now());
        matches = matches || isOverdue;
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

  bool _matchesSearch(CalendarItemBaseModel item, String query) {
    if (item.title.toLowerCase().contains(query)) {
      return true;
    }

    if (item.comments.toLowerCase().contains(query)) {
      return true;
    }

    return false;
  }
}

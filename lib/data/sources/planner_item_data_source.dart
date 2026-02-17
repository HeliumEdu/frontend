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
import 'package:heliumapp/data/models/planner/course_model.dart';
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
import 'package:heliumapp/utils/sort_helpers.dart';
import 'package:logging/logging.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

final _log = Logger('data.sources');

/// Optimistic override for planner item start/end times during drag-drop/resize.
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
  Map<int, CategoryModel>? categoriesMap;

  final Map<String, List<PlannerItemBaseModel>> _dateRangeCache = {};

  // State
  bool _hasLoadedInitialData = false;
  Map<int, bool> _filteredCourses = {};
  List<String> _filterCategories = [];
  List<String> _filterTypes = [];
  Set<String> _filterStatuses = {};
  String _searchQuery = '';
  int _todosItemsPerPage = 10;
  final Map<int, bool> _completedOverrides = {};
  final Map<int, PlannerItemTimeOverride> _timeOverrides = {};

  /// Maps calendar item ID to its position in the sorted list for items at the
  /// same base time. Used to apply seconds-based adjustments that encode the full
  /// sort order (type --> course --> title) into times seen by SfCalendar.
  final Map<int, int> _sortPositions = {};
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

      // Reload data for visible range if provided
      if (visibleStart != null && visibleEnd != null) {
        await handleLoadMore(visibleStart, visibleEnd, forceRefresh: true);
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

  /// Returns all planner items from all cached date ranges, deduplicated by id.
  List<PlannerItemBaseModel> get allPlannerItems {
    final seen = <int>{};
    final items = <PlannerItemBaseModel>[];
    for (final rangeItems in _dateRangeCache.values) {
      for (final item in rangeItems) {
        if (seen.add(item.id)) {
          items.add(item);
        }
      }
    }
    return items;
  }

  @override
  PlannerItemBaseModel? convertAppointmentToObject(
    PlannerItemBaseModel? customData,
    Appointment appointment,
  ) {
    return customData;
  }

  @override
  DateTime getStartTime(int index) {
    final item = _getData(index);

    // Check for optimistic override first (drag-drop/resize - still strings)
    final override = _timeOverrides[item.id];
    final baseTime = override != null
        ? DateTime.parse(override.start)
        : item.start;

    // All-day events: no adjustment (SfCalendar handles its own all-day sorting)
    if (item.allDay) {
      return baseTime;
    }

    // Timed events: subtract seconds to encode sort order
    final priority = typeSortPriority[item.plannerItemType] ?? 0;
    final position = _sortPositions[item.id] ?? 0;
    final adjustment = getTimedEventStartTimeAdjustmentSeconds(
      priority,
      position,
    );
    return baseTime.subtract(Duration(seconds: adjustment));
  }

  @override
  DateTime getEndTime(int index) {
    final plannerItem = _getData(index);

    // Check for optimistic override first (drag-drop/resize - still strings)
    final override = _timeOverrides[plannerItem.id];
    final startTime = override != null
        ? DateTime.parse(override.start)
        : plannerItem.start;
    final endTime = override != null
        ? DateTime.parse(override.end)
        : plannerItem.end;

    // All-day events: sort order is encoded in start time, just adjust end for display
    if (plannerItem.allDay) {
      final adjustedEnd = endTime.subtract(const Duration(days: 1));
      return adjustedEnd.isBefore(startTime) ? startTime : adjustedEnd;
    }

    // Timed events: subtract to encode sort order (uses minutes to avoid visible shortening)
    final priority = typeSortPriority[plannerItem.plannerItemType] ?? 0;
    final position = _sortPositions[plannerItem.id] ?? 0;
    final adjustment = getTimedEventEndTimeAdjustment(priority, position);
    return endTime.subtract(adjustment);
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

  @override
  String? getRecurrenceRule(int index) {
    final item = _getData(index);
    if (item is CourseScheduleEventModel) {
      return item.recurrenceRule;
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
      _log.info(
        'Fetching data for range: $startDate to $endDate${forceRefresh ? ' (force refresh)' : ''}',
      );

      final homeworks = await homeworkRepository.getHomeworks(
        from: startDate,
        to: endDate,
        shownOnCalendar: true,
        forceRefresh: forceRefresh,
      );
      final events = await eventRepository.getEvents(
        from: startDate,
        to: endDate,
        forceRefresh: forceRefresh,
      );
      final courseScheduleEvents = await courseScheduleRepository
          .getCourseScheduleEvents(
            courses: courses ?? [],
            from: startDate,
            to: endDate,
            shownOnCalendar: true,
            forceRefresh: forceRefresh,
          );
      final externalCalendarEvents = await externalCalendarRepository
          .getExternalCalendarEvents(
            from: startDate,
            to: endDate,
            shownOnCalendar: true,
            forceRefresh: forceRefresh,
          );

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

    // Rebuild calendar items from filters
    if (filterDebounceDuration == Duration.zero) {
      _applyFiltersSynchronously();
    } else {
      await _applyFiltersAsync();
    }

    if (!_hasLoadedInitialData) {
      _hasLoadedInitialData = true;
      try {
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

  // Typed getters for all items
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

    // Sort using centralized logic from sort_helpers.dart
    Sort.byStartThenTitle(items);
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
      'todosItemsPerPage': _todosItemsPerPage,
    };

    PrefService().setString('saved_filter_state', jsonEncode(filterState));
    _log.fine('Filter state saved');
  }

  void restoreFiltersIfEnabled() {
    if (!userSettings.rememberFilterState) return;

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

      final savedItemsPerPage = filterState['todosItemsPerPage'] as int?;
      if (savedItemsPerPage != null) {
        _todosItemsPerPage = savedItemsPerPage;
      }

      _log.info('Filter state restored');
    } catch (e) {
      _log.warning('Failed to restore filter state', e);
    }
  }

  void addPlannerItem(PlannerItemBaseModel plannerItem) {
    // Check if already exists in any cache entry
    for (final items in _dateRangeCache.values) {
      if (items.any((existing) => existing.id == plannerItem.id)) {
        return;
      }
    }

    _log.info(
      'Calendar item added: ${plannerItem.runtimeType} ${plannerItem.id} "${plannerItem.title}"',
    );

    // Add to all cache entries whose range overlaps with this item's dates
    final itemStart = plannerItem.start;
    final itemEnd = plannerItem.end;

    for (final entry in _dateRangeCache.entries) {
      final parts = entry.key.split('_');
      final rangeStart = DateTime.parse(parts[0]);
      final rangeEnd = DateTime.parse(parts[1]);

      // Check if item overlaps with this cached range
      if (itemStart.isBefore(rangeEnd) && itemEnd.isAfter(rangeStart)) {
        entry.value.add(plannerItem);
      }
    }

    // Add directly to appointments for immediate visibility, then schedule
    // async refilter for proper sorting. This provides better UX as users
    // see their added items immediately.
    if (!appointments!.any(
      (item) => (item as PlannerItemBaseModel).id == plannerItem.id,
    )) {
      appointments!.add(plannerItem);
      Sort.byStartThenTitle(appointments!.cast<PlannerItemBaseModel>());
      _buildSortPositions(appointments!.cast<PlannerItemBaseModel>());
      notifyListeners(CalendarDataSourceAction.add, [plannerItem]);
    }

    _applyFiltersAndNotify();
  }

  void updatePlannerItem(PlannerItemBaseModel plannerItem) {
    bool updated = false;

    // Update in all cache entries where the item exists
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

    // Clear any overrides since we have real data now
    if (plannerItem is HomeworkModel) {
      _completedOverrides.remove(plannerItem.id);
    }
    _timeOverrides.remove(plannerItem.id);

    // Find and update the item directly, using targeted, to reduce unnecessary
    // rebuilds and reduce the potential for UI flickers
    final oldIndex = appointments!.indexWhere(
      (item) => (item as PlannerItemBaseModel).id == plannerItem.id,
    );

    if (oldIndex != -1) {
      final oldItem = appointments![oldIndex];
      appointments!.removeAt(oldIndex);
      notifyListeners(CalendarDataSourceAction.remove, [oldItem]);

      // Re-add at correct sorted position
      appointments!.add(plannerItem);
      Sort.byStartThenTitle(appointments!.cast<PlannerItemBaseModel>());
      _buildSortPositions(appointments!.cast<PlannerItemBaseModel>());
      notifyListeners(CalendarDataSourceAction.add, [plannerItem]);
    } else {
      // Item not in current view, do full refresh
      _applyFiltersAndNotify();
    }

    _notifyChangeListeners();
  }

  void removePlannerItem(int plannerItemId) {
    PlannerItemBaseModel? removedItem;

    // Remove from all cache entries where the item exists
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
      _sortPositions.remove(plannerItemId);
      _buildSortPositions(appointments!.cast<PlannerItemBaseModel>());
      notifyListeners(CalendarDataSourceAction.remove, [removedItem]);
      _notifyChangeListeners();
    }
  }

  // Optimistic UI methods
  void setCompletedOverride(int homeworkId, bool completed) {
    _completedOverrides[homeworkId] = completed;
    // Notify immediately for instant UI feedback, then async filter for sorting
    _notifyChangeListeners();
    _applyFiltersAndNotify();
  }

  void clearCompletedOverride(int homeworkId) {
    _completedOverrides.remove(homeworkId);
    _notifyChangeListeners();
  }

  // Optimistic UI methods for drag-drop/resize
  void setTimeOverride(int itemId, String start, String end) {
    _timeOverrides[itemId] = PlannerItemTimeOverride(start: start, end: end);

    // Re-sort and rebuild positions to maintain correct order with new time
    Sort.byStartThenTitle(appointments!.cast<PlannerItemBaseModel>());
    _buildSortPositions(appointments!.cast<PlannerItemBaseModel>());

    notifyListeners(CalendarDataSourceAction.reset, appointments!);
    _notifyChangeListeners();
  }

  void clearTimeOverride(int itemId) {
    _timeOverrides.remove(itemId);
  }

  PlannerItemTimeOverride? getTimeOverride(int itemId) =>
      _timeOverrides[itemId];

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

    // Build sort position map to encode full sort order in time adjustments
    _buildSortPositions(_filteredPlannerItems);

    _log.fine(
      'Filters applied (sync): ${appointments!.length} of ${allPlannerItems.length} items visible',
    );
    notifyListeners(CalendarDataSourceAction.reset, appointments!);
    _notifyChangeListeners();
  }

  /// Waits for any pending filter operations to complete.
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

      // Build sort position map to encode full sort order in time adjustments
      _buildSortPositions(filteredItems);

      _log.fine(
        'Filters applied: ${appointments!.length} of ${items.length} items visible',
      );
      notifyListeners(CalendarDataSourceAction.reset, appointments!);
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
        comments: item.comments,
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

  /// Builds a map of item IDs to their position within items at the same time.
  /// This position is used to apply seconds-based adjustments that encode the full
  /// sort order (type --> course --> title) into the times seen by SfCalendar.
  void _buildSortPositions(List<PlannerItemBaseModel> sortedItems) {
    _sortPositions.clear();

    // Group items by their base time (without any adjustments)
    final itemsByBaseTime = <String, List<PlannerItemBaseModel>>{};

    for (final item in sortedItems) {
      // Use only date + hour + minute for grouping (ignore seconds/milliseconds)
      final baseTime = DateTime(
        item.start.year,
        item.start.month,
        item.start.day,
        item.start.hour,
        item.start.minute,
      );
      final key = baseTime.toIso8601String();
      itemsByBaseTime.putIfAbsent(key, () => []).add(item);
    }

    // Assign positions within each time group
    for (final timeGroup in itemsByBaseTime.values) {
      for (int i = 0; i < timeGroup.length; i++) {
        _sortPositions[timeGroup[i].id] = i;
      }
    }
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

      if (_filterStatuses.contains('Complete')) {
        matches = matches || isCompleted;
      }
      if (_filterStatuses.contains('Incomplete')) {
        matches = matches || !isCompleted;
      }
      if (_filterStatuses.contains('Overdue')) {
        final bool isOverdue =
            !isCompleted && homework.start.isBefore(DateTime.now());
        matches = matches || isOverdue;
      }
      if (_filterStatuses.contains('Graded')) {
        matches = matches || _isHomeworkGraded(homework);
      }
      if (_filterStatuses.contains('Ungraded')) {
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
    if (item.title.toLowerCase().contains(query)) {
      return true;
    }

    if (item.comments.toLowerCase().contains(query)) {
      return true;
    }

    return false;
  }
}

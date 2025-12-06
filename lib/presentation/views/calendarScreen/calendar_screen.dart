// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helium_mobile/config/app_routes.dart';
import 'package:helium_mobile/core/dio_client.dart';
import 'package:helium_mobile/data/datasources/category_remote_data_source.dart';
import 'package:helium_mobile/data/datasources/course_remote_data_source.dart';
import 'package:helium_mobile/data/datasources/event_remote_data_source.dart';
import 'package:helium_mobile/data/datasources/external_calendar_remote_data_source.dart';
import 'package:helium_mobile/data/datasources/homework_remote_data_source.dart';
import 'package:helium_mobile/data/models/auth/user_profile_model.dart';
import 'package:helium_mobile/data/models/planner/category_model.dart';
import 'package:helium_mobile/data/models/planner/course_model.dart';
import 'package:helium_mobile/data/models/planner/event_response_model.dart';
import 'package:helium_mobile/data/models/planner/external_calendar_event_model.dart';
import 'package:helium_mobile/data/models/planner/external_calendar_model.dart';
import 'package:helium_mobile/data/models/planner/homework_response_model.dart';
import 'package:helium_mobile/data/repositories/category_repository_impl.dart';
import 'package:helium_mobile/data/repositories/course_repository_impl.dart';
import 'package:helium_mobile/data/repositories/event_repository_impl.dart';
import 'package:helium_mobile/data/repositories/external_calendar_repository_impl.dart';
import 'package:helium_mobile/data/repositories/homework_repository_impl.dart';
import 'package:helium_mobile/presentation/bloc/categoryBloc/category_bloc.dart';
import 'package:helium_mobile/presentation/bloc/categoryBloc/category_event.dart'
    as category_event;
import 'package:helium_mobile/presentation/bloc/categoryBloc/category_state.dart';
import 'package:helium_mobile/presentation/bloc/courseBloc/course_bloc.dart';
import 'package:helium_mobile/presentation/bloc/courseBloc/course_event.dart';
import 'package:helium_mobile/presentation/bloc/courseBloc/course_state.dart';
import 'package:helium_mobile/presentation/bloc/eventBloc/event_bloc.dart';
import 'package:helium_mobile/presentation/bloc/eventBloc/event_event.dart';
import 'package:helium_mobile/presentation/bloc/eventBloc/event_state.dart';
import 'package:helium_mobile/presentation/bloc/externalCalendarBloc/external_calendar_bloc.dart';
import 'package:helium_mobile/presentation/bloc/externalCalendarBloc/external_calendar_event.dart';
import 'package:helium_mobile/presentation/bloc/externalCalendarBloc/external_calendar_state.dart';
import 'package:helium_mobile/presentation/bloc/homeworkBloc/homework_bloc.dart';
import 'package:helium_mobile/presentation/bloc/homeworkBloc/homework_event.dart';
import 'package:helium_mobile/presentation/bloc/homeworkBloc/homework_state.dart';
import 'package:helium_mobile/utils/app_colors.dart';
import 'package:helium_mobile/utils/app_list.dart';
import 'package:helium_mobile/utils/app_size.dart';
import 'package:helium_mobile/utils/app_text_style.dart';
import 'package:helium_mobile/utils/formatting.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

final log = Logger('HeliumLogger');

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();

  static void triggerRefresh() {
    _CalendarScreenState.triggerRefresh();
  }
}

class _CalendarScreenState extends State<CalendarScreen> {
  final DioClient _dioClient = DioClient();
  late UserSettings _userSettings;

  DateTime _selectedDate = DateTime.now();
  DateTime _focusedWeek = DateTime.now();
  DateTime _calendarFocusedMonth = DateTime.now();
  String? selectedReminderPreference;
  Map<String, bool> selectedClasses = {};
  int selectedIndex = 2; // Default to day view
  String _currentViewMode = 'Day';
  int _selectedWeekIndex = 0; // For week view selection
  List<ExternalCalendarModel> _externalCalendars = [];
  Map<int, List<ExternalCalendarEventModel>> _externalEventsByCalendar = {};

  List<String> selectedCategories = [];
  List<String> selectedCategoryFilters = [];
  Set<String> selectedStatuses = {};
  final Map<int, bool> _completedOverrides = {};
  final Map<int, CategoryModel> _categoriesById = {};
  final List<CategoryModel> _deduplicatedCategories = [];
  static bool _needsRefresh = false;

  static void triggerRefresh() {
    _needsRefresh = true;
    log.info(' Home screen refresh triggered');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_needsRefresh) {
        _needsRefresh = false;
        log.info(' Refresh will be handled by didChangeDependencies');
      }
    });
  }

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final awaitedSettings = await _dioClient.getSettings();
    setState(() {
      _userSettings = awaitedSettings;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_needsRefresh) {
      _needsRefresh = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            final homeworkBloc = context.read<HomeworkBloc>();
            homeworkBloc.add(
              FetchAllHomeworkEvent(
                categoryTitles: _activeCategoryFiltersOrNull(),
              ),
            );
            log.info(' Home screen refreshed after assignment creation/update');
          } catch (e) {
            log.info(' HomeworkBloc not available yet, skipping refresh: $e');
            _needsRefresh = true;
          }
        }
      });
    }
  }

  void _triggerRefreshIfNeeded() {
    if (_needsRefresh) {
      _needsRefresh = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            final homeworkBloc = context.read<HomeworkBloc>();
            homeworkBloc.add(
              FetchAllHomeworkEvent(
                categoryTitles: _activeCategoryFiltersOrNull(),
              ),
            );
            log.info(' Home screen refreshed after assignment creation/update');
          } catch (e) {
            log.info(' HomeworkBloc not available yet: $e');
          }
        }
      });
    }
  }

  void _applyExternalCalendarData(
    List<ExternalCalendarModel> externalCalendars,
    Map<int, List<ExternalCalendarEventModel>> eventsByCalendar,
  ) {
    if (!mounted) return;

    if (kDebugMode) {
      log.info('📅 Applying external calendar data:');
      log.info('   - Calendars count: ${externalCalendars.length}');
      int totalEvents = eventsByCalendar.values.fold(
        0,
        (sum, list) => sum + list.length,
      );
      log.info('   - Total events: $totalEvents');
      for (var externalCalendar in externalCalendars) {
        log.info(
          '   - Calendar: ${externalCalendar.title} (ID: ${externalCalendar.id}, shown: ${externalCalendar.shownOnCalendar})',
        );
        log.info(
          '     Events: ${eventsByCalendar[externalCalendar.id]?.length ?? 0}',
        );
      }
    }

    setState(() {
      _externalCalendars = externalCalendars;
      _externalEventsByCalendar = eventsByCalendar;
    });

    // Auto-enable external calendar filter if any calendars are shown
    final hasAnyShownCalendars = externalCalendars.any(
      (externalCalendar) => externalCalendar.shownOnCalendar,
    );
    if (kDebugMode) {
      log.info('   - Has shown calendars: $hasAnyShownCalendars');
      log.info('   - Selected categories: $selectedCategories');
    }

    if (hasAnyShownCalendars && mounted) {
      bool shouldAddCategory = selectedCategories.contains(
        'External Calendars',
      );

      if (shouldAddCategory) {
        selectedCategories = [...selectedCategories, 'External Calendars'];
        if (kDebugMode) {
          log.info('   ✅ Added External Calendar to selected categories');
        }
      }
    }
  }

  Set<int> _getActiveExternalCalendarIds() {
    // Simple logic: Show all calendars enabled in preferences (shownOnCalendar = true)
    final activeIds = _externalCalendars
        .where((calendar) => calendar.shownOnCalendar)
        .map((calendar) => calendar.id)
        .toSet();

    if (kDebugMode) {
      log.info('🎯 _getActiveExternalCalendarIds:');
      log.info('   - Showing calendars with shownOnCalendar=true: $activeIds');
    }

    return activeIds;
  }

  List<ExternalCalendarEventModel> _filterExternalEventsForSelection(
    List<ExternalCalendarEventModel> externalEvents,
  ) {
    if (kDebugMode) {
      log.info('🔍 Filtering external events:');
      log.info('   - Total events: ${externalEvents.length}');
      log.info(
        '   - Category enabled: ${_isCategoryEnabled('External Calendars')}',
      );
      log.info('   - Selected categories: $selectedCategories');
    }

    if (!_isCategoryEnabled('External Calendars')) {
      if (kDebugMode) {
        log.info('   ❌ External calendar filtering disabled');
      }
      return [];
    }

    final activeIds = _getActiveExternalCalendarIds();
    if (kDebugMode) {
      log.info('   - Active calendar IDs: $activeIds');
    }

    if (activeIds.isEmpty) {
      if (kDebugMode) {
        log.info('    No active calendar IDs');
      }
      return [];
    }

    final filtered = externalEvents
        .where((event) => activeIds.contains(event.externalCalendar))
        .toList();

    if (kDebugMode) {
      log.info('   ✅ Filtered to ${filtered.length} events');
    }

    return filtered;
  }

  bool _isCategoryEnabled(String category) {
    if (selectedCategories.isEmpty) return true;
    return selectedCategories.contains(category);
  }

  bool _hasSelectedClasses() {
    if (selectedClasses.isEmpty) return false;
    return selectedClasses.values.any((isSelected) => isSelected);
  }

  Set<int> _getSelectedCourseIds(List<CourseModel> courses) {
    final selectedTitles = _getSelectedCourseTitleSet();
    if (selectedTitles.isEmpty) return {};

    final normalizedCourseMap = _buildNormalizedCourseMap(courses);
    final ids = <int>{};
    for (final title in selectedTitles) {
      final course = normalizedCourseMap[title];
      if (course != null) {
        ids.add(course.id);
      }
    }
    return ids;
  }

  List<HomeworkResponseModel> _filterAssignmentsByClassSelection(
    List<HomeworkResponseModel> homeworks,
    List<CourseModel> courses,
  ) {
    if (!_hasSelectedClasses()) return homeworks;

    final selectedCourseIds = _getSelectedCourseIds(courses);
    if (selectedCourseIds.isEmpty) return homeworks;

    return homeworks
        .where((homework) => selectedCourseIds.contains(homework.course))
        .toList();
  }

  bool _courseHasClassOnDate(CourseModel course, DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);

    try {
      if (course.startDate.isNotEmpty && course.endDate.isNotEmpty) {
        final startDate = DateTime.parse(course.startDate);
        final endDate = DateTime.parse(course.endDate);
        if (targetDate.isBefore(startDate) || targetDate.isAfter(endDate)) {
          return false;
        }
      }
    } catch (_) {
      // Ignore parse issues and continue with schedule checks
    }

    if (course.schedules.isEmpty) {
      return false;
    }

    final dayOfWeek = targetDate.weekday % 7;
    for (final schedule in course.schedules) {
      if (schedule.daysOfWeek.length > dayOfWeek &&
          schedule.daysOfWeek[dayOfWeek] == '1') {
        return true;
      }
    }

    return false;
  }

  Color _externalCalendarColor(int calendarId) {
    for (final calendar in _externalCalendars) {
      if (calendar.id == calendarId) {
        return parseColor(calendar.color);
      }
    }
    return blackColor;
  }

  List<ExternalCalendarEventModel> _resolveExternalEventsFromState(
    ExternalCalendarState state,
  ) {
    if (state is AllExternalCalendarEventsLoaded) {
      return state.events;
    }
    return _externalEventsByCalendar.values.expand((events) => events).toList();
  }

  List<DateTime> _getWeekDates(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  List<String> _getWeekRanges() {
    List<String> weekRanges = [];

    DateTime monthStart = DateTime(
      _calendarFocusedMonth.year,
      _calendarFocusedMonth.month,
      1,
    );

    DateTime firstWeekStart = monthStart;
    while (firstWeekStart.weekday != 1) {
      firstWeekStart = firstWeekStart.subtract(Duration(days: 1));
    }

    for (int i = 0; i < 5; i++) {
      DateTime weekStart = firstWeekStart.add(Duration(days: i * 7));
      DateTime weekEnd = weekStart.add(Duration(days: 6));

      String range;
      if (weekStart.month == weekEnd.month) {
        range = '(${weekStart.day} - ${weekEnd.day})';
      } else {
        range = '(${weekStart.day} - ${weekEnd.day})';
      }
      weekRanges.add(range);
    }

    return weekRanges;
  }

  DateTime _getWeekStartDate(int weekIndex) {
    DateTime monthStart = DateTime(
      _calendarFocusedMonth.year,
      _calendarFocusedMonth.month,
      1,
    );

    DateTime firstWeekStart = monthStart;
    while (firstWeekStart.weekday != 1) {
      firstWeekStart = firstWeekStart.subtract(Duration(days: 1));
    }
    return firstWeekStart.add(Duration(days: weekIndex * 7));
  }

  void _onTimeFilterChanged(int index) {
    setState(() {
      selectedIndex = index;
      switch (index) {
        case 0:
          _currentViewMode = 'Month';
          break;
        case 1:
          _currentViewMode = 'Week';
          break;
        case 2:
          _currentViewMode = 'Day';
          break;
        case 3:
          _currentViewMode = 'Todos';
          break;
      }
    });
  }

  void _previousWeek() {
    setState(() {
      _focusedWeek = _focusedWeek.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _focusedWeek = _focusedWeek.add(const Duration(days: 7));
    });
  }

  void _previousWeekRange() {
    setState(() {
      _calendarFocusedMonth = DateTime(
        _calendarFocusedMonth.year,
        _calendarFocusedMonth.month - 1,
      );
      _selectedWeekIndex = 0;
      _focusedWeek = _getWeekStartDate(0);
      _selectedDate = _focusedWeek;
    });
  }

  void _nextWeekRange() {
    setState(() {
      _calendarFocusedMonth = DateTime(
        _calendarFocusedMonth.year,
        _calendarFocusedMonth.month + 1,
      );
      _selectedWeekIndex = 0;
      _focusedWeek = _getWeekStartDate(0);
      _selectedDate = _focusedWeek;
    });
  }

  void _goToToday() {
    final today = DateTime.now();
    setState(() {
      _selectedDate = today;
      _focusedWeek = today;
      _calendarFocusedMonth = DateTime(today.year, today.month, 1);

      // Compute which of the 5 displayed weeks contains today (weeks start on Monday)
      DateTime monthStart = DateTime(
        _calendarFocusedMonth.year,
        _calendarFocusedMonth.month,
        1,
      );
      DateTime firstWeekStart = monthStart;
      while (firstWeekStart.weekday != 1) {
        firstWeekStart = firstWeekStart.subtract(const Duration(days: 1));
      }
      final int daysFromFirstWeekStart = today
          .difference(
            DateTime(
              firstWeekStart.year,
              firstWeekStart.month,
              firstWeekStart.day,
            ),
          )
          .inDays;
      _selectedWeekIndex = (daysFromFirstWeekStart ~/ 7).clamp(0, 4);
    });
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Checks if a date falls within a date range (inclusive)
  bool _isDateInRange(DateTime date, DateTime startDate, DateTime? endDate) {
    // Normalize dates to ignore time components
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    if (endDate == null) {
      // If no end date, only check start date
      return _isSameDay(normalizedDate, normalizedStart);
    }

    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);

    // Check if date is within range (inclusive)
    return (normalizedDate.isAtSameMomentAs(normalizedStart) ||
            normalizedDate.isAfter(normalizedStart)) &&
        (normalizedDate.isAtSameMomentAs(normalizedEnd) ||
            normalizedDate.isBefore(normalizedEnd));
  }

  bool _hasAssignmentsOnDate(
    DateTime date,
    List<HomeworkResponseModel> homeworks,
  ) {
    return homeworks.any((homework) {
      try {
        final startDate = parseDateTime(homework.start, _userSettings.timeZone);
        DateTime? endDate;
        if (homework.end != null && homework.end!.isNotEmpty) {
          endDate = parseDateTime(homework.end!, _userSettings.timeZone);
        }
        return _isDateInRange(date, startDate, endDate);
      } catch (e) {
        return false;
      }
    });
  }

  bool _hasEventsOnDate(DateTime date, List<EventResponseModel> events) {
    return events.any((event) {
      try {
        final startDate = parseDateTime(event.start, _userSettings.timeZone);
        DateTime? endDate;
        if (event.end != null && event.end!.isNotEmpty) {
          endDate = parseDateTime(event.end!, _userSettings.timeZone);
        }
        return _isDateInRange(date, startDate, endDate);
      } catch (e) {
        return false;
      }
    });
  }

  bool _hasCoursesOnDate(DateTime date, List<CourseModel> courses) {
    return courses.any((course) {
      final isClassSelected =
          selectedClasses.isEmpty || selectedClasses[course.title] == true;
      if (!isClassSelected) return false;
      return _courseHasClassOnDate(course, date);
    });
  }

  bool _hasExternalEventsOnDate(
    DateTime date,
    List<ExternalCalendarEventModel> externalEvents,
  ) {
    return externalEvents.any((event) {
      try {
        final startDate = parseDateTime(event.start, _userSettings.timeZone);
        DateTime? endDate;
        if (event.end != null && event.end!.isNotEmpty) {
          endDate = parseDateTime(event.end!, _userSettings.timeZone);
        }
        return _isDateInRange(date, startDate, endDate);
      } catch (e) {
        return false;
      }
    });
  }

  // Get color dots for a specific date
  List<Color> _getColorDotsForDate(
    DateTime date, {
    required List<HomeworkResponseModel> homeworks,
    required List<EventResponseModel> events,
    required List<CourseModel> courses,
    required List<ExternalCalendarEventModel> externalEvents,
  }) {
    List<Color> dots = [];
    final filteredExternalEvents = _filterExternalEventsForSelection(
      externalEvents,
    );

    if (kDebugMode && date.day == 11 && date.month == 11) {
      log.info('🎯 Getting dots for Nov 11:');
      log.info('   - Incoming external events: ${externalEvents.length}');
      log.info(
        '   - Filtered external events: ${filteredExternalEvents.length}',
      );
    }

    final showAssignments = _isCategoryEnabled('Assignments');
    final showEvents = _isCategoryEnabled('Events');
    final showClassSchedule = _isCategoryEnabled('Class Schedules');
    final showExternal = _isCategoryEnabled('External Calendars');

    // Only show dots for selected categories
    if (showAssignments && _hasAssignmentsOnDate(date, homeworks)) {
      dots.add(darkBlueColor);
    }
    if (showEvents && _hasEventsOnDate(date, events)) {
      dots.add(parseColor(_userSettings.eventsColor));
    }
    if (showClassSchedule && _hasCoursesOnDate(date, courses)) {
      dots.add(greenColor);
    }
    if (showExternal &&
        _hasExternalEventsOnDate(date, filteredExternalEvents)) {
      dots.add(yellowColor);
    }

    return dots;
  }

  bool _isHomeworkCompleted(HomeworkResponseModel hw) {
    return _completedOverrides.containsKey(hw.id)
        ? _completedOverrides[hw.id]!
        : hw.completed;
  }

  bool _matchesAssignmentStatus(HomeworkResponseModel homework) {
    // While the user is actively toggling completion, always keep the item visible
    if (_completedOverrides.containsKey(homework.id)) return true;
    if (selectedStatuses.isEmpty) return true;
    bool matches = false;
    if (selectedStatuses.contains('Complete')) {
      matches = matches || (_isHomeworkCompleted(homework) == true);
    }
    if (selectedStatuses.contains('Incomplete')) {
      matches = matches || (_isHomeworkCompleted(homework) == false);
    }
    if (selectedStatuses.contains('Overdue')) {
      try {
        final bool isOverdue =
            (_isHomeworkCompleted(homework) == false) &&
            DateTime.parse(homework.start).isBefore(DateTime.now());
        matches = matches || isOverdue;
      } catch (_) {
        // ignore parsing errors for overdue
      }
    }
    return matches;
  }

  List<HomeworkResponseModel> _applyCategoryFilterToHomeworks(
    List<HomeworkResponseModel> homeworks,
  ) {
    if (selectedCategoryFilters.isEmpty) return homeworks;
    final filters = _normalizedCategoryFilters()
        .map((title) => title.trim())
        .toSet();
    return homeworks.where((homework) {
      final categoryId = homework.category;
      if (categoryId == null || categoryId <= 0) {
        return false;
      }
      final category = _categoriesById[categoryId];
      if (category == null || category.title.trim().isEmpty) {
        return false;
      }
      return filters.contains(category.title.trim());
    }).toList();
  }

  // Get all items for a specific week
  List<Widget> _getWeekItems(
    DateTime weekStart, {
    required List<HomeworkResponseModel> homeworks,
    required List<EventResponseModel> events,
    required List<CourseModel> courses,
    required List<ExternalCalendarEventModel> externalEvents,
  }) {
    List<Widget> weekItems = [];
    final filteredExternalEventsForSelection =
        _filterExternalEventsForSelection(externalEvents);
    final showAssignments = _isCategoryEnabled('Assignments');
    final showEvents = _isCategoryEnabled('Events');
    final showClassSchedule = _isCategoryEnabled('Class Schedules');
    final showExternal = _isCategoryEnabled('External Calendars');

    List<DateTime> weekDates = [];
    for (int i = 0; i < 7; i++) {
      weekDates.add(weekStart.add(Duration(days: i)));
    }

    for (DateTime date in weekDates) {
      List<HomeworkResponseModel> dayAssignments = homeworks.where((homework) {
        try {
          final startDate = parseDateTime(
            homework.start,
            _userSettings.timeZone,
          );
          DateTime? endDate;
          if (homework.end != null && homework.end!.isNotEmpty) {
            endDate = parseDateTime(homework.end!, _userSettings.timeZone);
          }
          if (!_isDateInRange(date, startDate, endDate)) return false;
          return _matchesAssignmentStatus(homework);
        } catch (e) {
          return false;
        }
      }).toList();
      dayAssignments = _applyCategoryFilterToHomeworks(dayAssignments);
      List<EventResponseModel> dayEvents = events.where((event) {
        try {
          final startDate = parseDateTime(event.start, _userSettings.timeZone);
          DateTime? endDate;
          if (event.end != null && event.end!.isNotEmpty) {
            endDate = parseDateTime(event.end!, _userSettings.timeZone);
          }
          return _isDateInRange(date, startDate, endDate);
        } catch (e) {
          return false;
        }
      }).toList();

      List<CourseModel> dayCourses = courses.where((course) {
        final isClassSelected =
            selectedClasses.isEmpty || selectedClasses[course.title] == true;
        if (!isClassSelected) return false;
        return _courseHasClassOnDate(course, date);
      }).toList();

      List<ExternalCalendarEventModel> dayExternalEvents =
          filteredExternalEventsForSelection.where((event) {
            try {
              final startDate = parseDateTime(
                event.start,
                _userSettings.timeZone,
              );
              DateTime? endDate;
              if (event.end != null && event.end!.isNotEmpty) {
                endDate = parseDateTime(event.end!, _userSettings.timeZone);
              }
              return _isDateInRange(date, startDate, endDate);
            } catch (e) {
              return false;
            }
          }).toList();

      List<HomeworkResponseModel> filteredAssignments = showAssignments
          ? dayAssignments
          : [];
      List<EventResponseModel> filteredEvents = showEvents ? dayEvents : [];
      List<CourseModel> filteredCourses = showClassSchedule ? dayCourses : [];
      List<ExternalCalendarEventModel> filteredExternalEvents = showExternal
          ? dayExternalEvents
          : [];

      if (filteredAssignments.isNotEmpty ||
          filteredEvents.isNotEmpty ||
          filteredCourses.isNotEmpty ||
          filteredExternalEvents.isNotEmpty) {
        weekItems.add(
          Container(
            margin: EdgeInsets.only(bottom: 8.v, top: 8.v),
            child: Text(
              DateFormat('EEEE, MMMM dd').format(date),
              style: AppTextStyle.bTextStyle.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        );

        for (var assignment in filteredAssignments) {
          weekItems.add(_buildAssignmentCard(assignment, courses));
        }

        for (var event in filteredEvents) {
          weekItems.add(_buildEventCard(context, event));
        }

        for (var course in filteredCourses) {
          weekItems.add(
            _buildCourseCard(course, courses.indexOf(course), date),
          );
        }

        for (var externalEvent in filteredExternalEvents) {
          weekItems.add(
            _buildExternalCalendarEventCard(context, externalEvent),
          );
        }
      }
    }

    return weekItems;
  }

  String _getCourseTimeForDate(CourseModel course, DateTime dateTime) {
    if (course.schedules.isEmpty) return '';

    final selectedDayOfWeek = dateTime.weekday % 7;

    for (var schedule in course.schedules) {
      if (schedule.daysOfWeek.length > selectedDayOfWeek &&
          schedule.daysOfWeek[selectedDayOfWeek] == '1') {
        String startTime = '';

        switch (selectedDayOfWeek) {
          case 0:
            startTime = schedule.sunStartTime;
            break;
          case 1:
            startTime = schedule.monStartTime;
            break;
          case 2:
            startTime = schedule.tueStartTime;
            break;
          case 3:
            startTime = schedule.wedStartTime;
            break;
          case 4:
            startTime = schedule.thuStartTime;
            break;
          case 5:
            startTime = schedule.friStartTime;
            break;
          case 6:
            startTime = schedule.satStartTime;
            break;
        }

        try {
          final start = DateFormat(
            'h:mm a',
          ).format(DateFormat('HH:mm:ss').parse(startTime));
          // final end = DateFormat('h:mm a').format(DateFormat('HH:mm:ss').parse('$endTime'));
          // return '$start - $end';
          return start;
        } catch (e) {
          return startTime;
        }
      }
    }

    return '';
  }

  String _normalizeCourseTitle(String title) {
    return title.trim().toLowerCase();
  }

  Set<String> _getSelectedCourseTitleSet() {
    if (selectedClasses.isEmpty) return {};
    return selectedClasses.entries
        .where((entry) => entry.value)
        .map((entry) => _normalizeCourseTitle(entry.key))
        .toSet();
  }

  Map<String, CourseModel> _buildNormalizedCourseMap(
    List<CourseModel> courses,
  ) {
    final map = <String, CourseModel>{};
    for (final course in courses) {
      final normalized = _normalizeCourseTitle(course.title);
      map.putIfAbsent(normalized, () => course);
    }
    return map;
  }

  List<String> _normalizedCategoryFilters() {
    final unique = <String>{};
    for (final title in selectedCategoryFilters) {
      final trimmed = title.trim();
      if (trimmed.isNotEmpty) {
        unique.add(trimmed);
      }
    }
    return unique.toList();
  }

  void _populateCategories(List<CategoryModel> categories) {
    for (final category in categories) {
      _categoriesById[category.id] = category;
    }

    final uniqueCategories = <String, CategoryModel>{};
    for (var category in categories) {
      if (!uniqueCategories.containsKey(category.title)) {
        uniqueCategories[category.title] = category;
      }
    }

    _deduplicatedCategories.addAll(uniqueCategories.values.toList());
  }

  List<String>? _activeCategoryFiltersOrNull() {
    final filters = _normalizedCategoryFilters();
    return filters.isEmpty ? null : filters;
  }

  void _refetchHomeworkWithCurrentFilters({HomeworkBloc? homeworkBloc}) {
    if (!mounted) return;
    final filters = _activeCategoryFiltersOrNull();
    final bloc = homeworkBloc ?? context.read<HomeworkBloc>();
    bloc.add(FetchAllHomeworkEvent(categoryTitles: filters));
  }

  int? _extractCourseIdFromOwner(String? ownerId) {
    if (ownerId == null || ownerId.isEmpty) return null;

    final patterns = <RegExp>[
      RegExp(r'courseschedule[_:/\-](\d+)', caseSensitive: false),
      RegExp(r'course[_:/\-](\d+)', caseSensitive: false),
      RegExp(r'course=(\d+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(ownerId);
      if (match != null) {
        final value = match.group(1);
        if (value != null) {
          final parsed = int.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
    }

    return null;
  }

  List<EventResponseModel> _filterEventsByClassSelection(
    List<EventResponseModel> events,
    List<CourseModel> courses,
  ) {
    if (!_hasSelectedClasses()) return events;

    final selectedTitles = _getSelectedCourseTitleSet();
    if (selectedTitles.isEmpty) return events;

    final normalizedCourseMap = _buildNormalizedCourseMap(courses);
    final selectedCourseIds = <int>{};
    for (final title in selectedTitles) {
      final course = normalizedCourseMap[title];
      if (course != null) {
        selectedCourseIds.add(course.id);
      }
    }

    return events.where((event) {
      final normalizedEventTitle = _normalizeCourseTitle(event.title);
      final eventCourseId = event.courseId;
      final eventCourseTitle = event.courseTitle != null
          ? _normalizeCourseTitle(event.courseTitle!)
          : null;
      final ownerCourseId = _extractCourseIdFromOwner(event.ownerId);

      final matchesCourseId =
          eventCourseId != null && selectedCourseIds.contains(eventCourseId);
      final matchesOwnerId =
          ownerCourseId != null && selectedCourseIds.contains(ownerCourseId);
      final matchesCourseTitle =
          eventCourseTitle != null && selectedTitles.contains(eventCourseTitle);
      final matchesEventTitle = selectedTitles.contains(normalizedEventTitle);

      if (matchesCourseId ||
          matchesOwnerId ||
          matchesCourseTitle ||
          matchesEventTitle) {
        return true;
      }

      final hasCourseAssociation =
          eventCourseId != null ||
          ownerCourseId != null ||
          eventCourseTitle != null ||
          normalizedCourseMap.containsKey(normalizedEventTitle);

      if (!hasCourseAssociation) {
        // Hide unassociated events when specific courses are selected
        return false;
      }

      return false;
    }).toList();
  }

  void _showFilterMenu(BuildContext triggerContext) {
    final RenderBox button = triggerContext.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(triggerContext).context.findRenderObject() as RenderBox;
    final homeworkBloc = triggerContext.read<HomeworkBloc>();
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: triggerContext,
      position: position,
      color: whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(color: whiteColor),
            width: 250,
            padding: EdgeInsets.all(16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          selectedClasses = {};
                          selectedCategories = [];
                          selectedCategoryFilters = [];
                          selectedStatuses = {};
                        });
                        _refetchHomeworkWithCurrentFilters(
                          homeworkBloc: homeworkBloc,
                        );
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.v),
                        child: Text(
                          'Clear Filters',
                          style: AppTextStyle.cTextStyle.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.check, color: greenColor, size: 22.h),
                    ),
                  ],
                ),
                Divider(height: 20.v),

                StatefulBuilder(
                  builder: (context, setMenuState) {
                    return Column(
                      children: [
                        CheckboxListTile(
                          value: selectedCategories.contains('Assignments'),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                if (!selectedCategories.contains(
                                  'Assignments',
                                )) {
                                  selectedCategories = [
                                    ...selectedCategories,
                                    'Assignments',
                                  ];
                                }
                              } else {
                                selectedCategories = selectedCategories
                                    .where((cat) => cat != 'Assignments')
                                    .toList();
                              }
                            });
                            setMenuState(() {
                              // Trigger menu rebuild
                            });
                          },
                          title: Text(
                            'Assignments',
                            style: AppTextStyle.eTextStyle.copyWith(
                              color: textColor,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          activeColor: primaryColor,
                        ),
                        CheckboxListTile(
                          value: selectedCategories.contains('Events'),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                if (!selectedCategories.contains('Events')) {
                                  selectedCategories = [
                                    ...selectedCategories,
                                    'Events',
                                  ];
                                }
                              } else {
                                selectedCategories = selectedCategories
                                    .where((cat) => cat != 'Events')
                                    .toList();
                              }
                            });
                            setMenuState(() {
                              // Trigger menu rebuild
                            });
                          },
                          title: Row(
                            children: [
                              Text(
                                'Events',
                                style: AppTextStyle.eTextStyle.copyWith(
                                  color: textColor,
                                ),
                              ),
                              SizedBox(width: 8.h),
                              Container(
                                width: 12.h,
                                height: 12.h,
                                decoration: BoxDecoration(
                                  color: parseColor(_userSettings.eventsColor),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          activeColor: primaryColor,
                        ),
                        CheckboxListTile(
                          value: selectedCategories.contains('Class Schedules'),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                if (!selectedCategories.contains(
                                  'Class Schedules',
                                )) {
                                  selectedCategories = [
                                    ...selectedCategories,
                                    'Class Schedules',
                                  ];
                                }
                              } else {
                                selectedCategories = selectedCategories
                                    .where((cat) => cat != 'Class Schedules')
                                    .toList();
                              }
                            });
                            setMenuState(() {
                              // Trigger menu rebuild
                            });
                          },
                          title: Text(
                            'Class Schedules',
                            style: AppTextStyle.eTextStyle.copyWith(
                              color: textColor,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          activeColor: primaryColor,
                        ),
                        CheckboxListTile(
                          value: selectedCategories.contains(
                            'External Calendars',
                          ),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                if (!selectedCategories.contains(
                                  'External Calendars',
                                )) {
                                  selectedCategories = [
                                    ...selectedCategories,
                                    'External Calendars',
                                  ];
                                }
                              } else {
                                selectedCategories = selectedCategories
                                    .where((cat) => cat != 'External Calendars')
                                    .toList();
                              }
                            });
                            setMenuState(() {
                              // Trigger menu rebuild
                            });
                          },
                          title: Text(
                            'External Calendars',
                            style: AppTextStyle.eTextStyle.copyWith(
                              color: textColor,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          activeColor: primaryColor,
                        ),
                      ],
                    );
                  },
                ),
                Divider(height: 20.v),
                StatefulBuilder(
                  builder: (context, setMenuState) {
                    Widget buildStatusTile(String label) {
                      final isChecked = selectedStatuses.contains(label);
                      return CheckboxListTile(
                        value: isChecked,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedStatuses = {...selectedStatuses, label};
                            } else {
                              selectedStatuses = selectedStatuses
                                  .where((s) => s != label)
                                  .toSet();
                            }
                          });
                          setMenuState(() {
                            // Trigger menu rebuild
                          });
                        },
                        title: Text(
                          label,
                          style: AppTextStyle.eTextStyle.copyWith(
                            color: textColor,
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: primaryColor,
                      );
                    }

                    return Column(
                      children: [
                        buildStatusTile('Complete'),
                        buildStatusTile('Incomplete'),
                        buildStatusTile('Overdue'),
                      ],
                    );
                  },
                ),
                Divider(height: 20.v),
                Text(
                  'Categories',
                  style: AppTextStyle.bTextStyle.copyWith(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.v),
                StatefulBuilder(
                  builder: (context, setMenuState) {
                    return Column(
                      children: _deduplicatedCategories.map((category) {
                        return CheckboxListTile(
                          value: selectedCategoryFilters.contains(
                            category.title,
                          ),
                          onChanged: (value) {
                            setState(() {
                              final updatedFilters = <String>{
                                ...selectedCategoryFilters,
                              };
                              if (value == true) {
                                updatedFilters.add(category.title);
                              } else {
                                updatedFilters.remove(category.title);
                              }
                              selectedCategoryFilters = updatedFilters.toList();
                            });
                            _refetchHomeworkWithCurrentFilters(
                              homeworkBloc: homeworkBloc,
                            );
                            setMenuState(() {
                              // Trigger menu rebuild
                            });
                          },
                          title: Row(
                            children: [
                              SizedBox(width: 8.h),
                              Expanded(
                                child: Text(
                                  category.title,
                                  style: AppTextStyle.eTextStyle.copyWith(
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          activeColor: primaryColor,
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showClassesMenu(BuildContext context, List<CourseModel> courses) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final Map<String, CourseModel> uniqueCourseMap = {};
    for (final course in courses) {
      final title = course.title.trim();
      if (title.isEmpty) continue;
      final normalized = title.toLowerCase();
      uniqueCourseMap.putIfAbsent(normalized, () => course);
    }
    final List<CourseModel> displayCourses = uniqueCourseMap.values.toList();

    showMenu(
      context: context,
      position: position,
      color: whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(color: whiteColor),
            width: 300,
            padding: EdgeInsets.all(16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          selectedClasses = {};
                        });
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.v),
                        child: Text(
                          'Clear Filters',
                          style: AppTextStyle.cTextStyle.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.check, color: greenColor, size: 22.h),
                    ),
                  ],
                ),
                Divider(height: 20.v),

                if (displayCourses.isEmpty)
                  SizedBox(
                    height: 60,
                    child: Center(
                      child: Text(
                        'No classes available',
                        style: AppTextStyle.eTextStyle.copyWith(
                          color: textColor.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                else
                  StatefulBuilder(
                    builder: (context, setMenuState) {
                      return Column(
                        children: displayCourses.map((course) {
                          Color courseColor = primaryColor;
                          try {
                            final colorValue = int.parse(
                              course.color.replaceFirst('#', 'ff'),
                              radix: 16,
                            );
                            courseColor = Color(colorValue);
                          } catch (e) {
                            courseColor = primaryColor;
                          }

                          final isSelected =
                              selectedClasses[course.title] ?? false;

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  selectedClasses = {
                                    ...selectedClasses,
                                    course.title: true,
                                  };
                                } else {
                                  final newMap = Map<String, bool>.from(
                                    selectedClasses,
                                  );
                                  newMap.remove(course.title);
                                  selectedClasses = newMap;
                                }
                              });
                              setMenuState(() {
                                // Trigger menu rebuild
                              });
                            },
                            title: Row(
                              children: [
                                Container(
                                  width: 12.h,
                                  height: 12.h,
                                  decoration: BoxDecoration(
                                    color: courseColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 8.h),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        course.title,
                                        style: AppTextStyle.cTextStyle.copyWith(
                                          color: textColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (course.room.isNotEmpty)
                                        Text(
                                          course.room,
                                          style: AppTextStyle.eTextStyle
                                              .copyWith(
                                                color: textColor.withValues(
                                                  alpha: 0.6,
                                                ),
                                                fontSize: 11,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      if (course.teacherName.isNotEmpty)
                                        Text(
                                          course.teacherName,
                                          style: AppTextStyle.eTextStyle
                                              .copyWith(
                                                color: textColor.withValues(
                                                  alpha: 0.6,
                                                ),
                                                fontSize: 10,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            activeColor: primaryColor,
                          );
                        }).toList(),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekView({
    List<CourseModel> courses = const [],
    List<HomeworkResponseModel> homeworks = const [],
    List<EventResponseModel> events = const [],
    List<ExternalCalendarEventModel> externalEvents = const [],
  }) {
    final weekRanges = _getWeekRanges();
    final classFilteredAssignments = _filterAssignmentsByClassSelection(
      homeworks,
      courses,
    );
    final categoryFilteredAssignments = _applyCategoryFilterToHomeworks(
      classFilteredAssignments,
    );
    final classFilteredEvents = _filterEventsByClassSelection(events, courses);
    final filteredExternalEvents = _filterExternalEventsForSelection(
      externalEvents,
    );
    final showAssignments = _isCategoryEnabled('Assignments');
    final showEvents = _isCategoryEnabled('Events');
    final showClassSchedule = _isCategoryEnabled('Class Schedules');
    final showExternal = _isCategoryEnabled('External Calendars');
    return Column(
      children: [
        // Week selector
        SizedBox(
          height: 50.v,
          child: Row(
            children: [
              // Left arrow
              IconButton(
                icon: Icon(Icons.chevron_left, color: primaryColor),
                onPressed: _previousWeekRange,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              // Week ranges list
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: weekRanges.length,
                  itemBuilder: (context, index) {
                    bool isSelected = index == _selectedWeekIndex;

                    // Get the start date of this week using the same logic as _getWeekRanges
                    DateTime monthStart = DateTime(
                      _calendarFocusedMonth.year,
                      _calendarFocusedMonth.month,
                      1,
                    );
                    DateTime firstWeekStart = monthStart;
                    while (firstWeekStart.weekday != 1) {
                      // 1 = Monday
                      firstWeekStart = firstWeekStart.subtract(
                        Duration(days: 1),
                      );
                    }
                    DateTime weekStart = firstWeekStart.add(
                      Duration(days: index * 7),
                    );

                    // Count items for this week based on selected categories
                    int itemCount = 0;
                    for (int i = 0; i < 7; i++) {
                      DateTime date = weekStart.add(Duration(days: i));
                      if (showAssignments &&
                          _hasAssignmentsOnDate(
                            date,
                            categoryFilteredAssignments,
                          )) {
                        itemCount++;
                      }
                      if (showEvents &&
                          _hasEventsOnDate(date, classFilteredEvents)) {
                        itemCount++;
                      }
                      if (showClassSchedule &&
                          _hasCoursesOnDate(date, courses)) {
                        itemCount++;
                      }
                      if (showExternal &&
                          _hasExternalEventsOnDate(
                            date,
                            filteredExternalEvents,
                          )) {
                        itemCount++;
                      }
                    }

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedWeekIndex = index;
                          _focusedWeek = weekStart;
                          _selectedDate = weekStart;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.h,
                          vertical: 8.v,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor : transparentColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? primaryColor
                                : greyColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              weekRanges[index],
                              style: AppTextStyle.eTextStyle.copyWith(
                                color: isSelected ? whiteColor : textColor,
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                            if (itemCount > 0) ...[
                              SizedBox(width: 4.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.h,
                                  vertical: 2.v,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? whiteColor.withValues(alpha: 0.2)
                                      : primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$itemCount',
                                  style: AppTextStyle.fTextStyle.copyWith(
                                    color: isSelected
                                        ? whiteColor
                                        : primaryColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => SizedBox(width: 8.h),
                ),
              ),

              // Right arrow
              IconButton(
                icon: Icon(Icons.chevron_right, color: primaryColor),
                onPressed: _nextWeekRange,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        // Week content display
        if (_selectedWeekIndex >= 0) ...[
          SizedBox(height: 16.v),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: greyColor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Week header
                  Container(
                    padding: EdgeInsets.all(16.h),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_view_week, color: primaryColor),
                        SizedBox(width: 8.h),
                        Text(
                          'Week ${_selectedWeekIndex + 1} - ${weekRanges[_selectedWeekIndex]}',
                          style: AppTextStyle.bTextStyle.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Week items list
                  Expanded(
                    child: _selectedWeekIndex < weekRanges.length
                        ? _buildWeekContent(
                            _getWeekStartDate(_selectedWeekIndex),
                            homeworks: categoryFilteredAssignments,
                            events: classFilteredEvents,
                            courses: courses,
                            externalEvents: externalEvents,
                          )
                        : Center(
                            child: Text(
                              'No week selected',
                              style: AppTextStyle.cTextStyle.copyWith(
                                color: textColor.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWeekContent(
    DateTime weekStart, {
    required List<HomeworkResponseModel> homeworks,
    required List<EventResponseModel> events,
    required List<CourseModel> courses,
    required List<ExternalCalendarEventModel> externalEvents,
  }) {
    final weekItems = _getWeekItems(
      weekStart,
      homeworks: homeworks,
      events: events,
      courses: courses,
      externalEvents: externalEvents,
    );

    if (weekItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: textColor.withValues(alpha: 0.3),
            ),
            SizedBox(height: 16),
            Text(
              'No items for this week',
              style: AppTextStyle.bTextStyle.copyWith(
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(16.h),
      itemCount: weekItems.length,
      itemBuilder: (context, index) => weekItems[index],
      separatorBuilder: (context, index) => SizedBox(height: 12.v),
    );
  }

  Widget _buildTodosView({
    List<CourseModel> courses = const [],
    List<HomeworkResponseModel> homeworks = const [],
  }) {
    List<Widget> allItems = [];
    final classFilteredAssignments = _filterAssignmentsByClassSelection(
      homeworks,
      courses,
    );
    final categoryFilteredAssignments = _applyCategoryFilterToHomeworks(
      classFilteredAssignments,
    );

    final showAssignments = _isCategoryEnabled('Assignments');

    if (showAssignments && categoryFilteredAssignments.isNotEmpty) {
      for (var homework in categoryFilteredAssignments) {
        if (_matchesAssignmentStatus(homework)) {
          allItems.add(_buildAssignmentCard(homework, courses));
        }
      }
    }

    if (allItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.list_outlined,
              size: 48,
              color: textColor.withValues(alpha: 0.3),
            ),
            SizedBox(height: 16),
            Text(
              'No items found',
              style: AppTextStyle.bTextStyle.copyWith(
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: AppTextStyle.cTextStyle.copyWith(
                color: textColor.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(16.h),
      itemCount: allItems.length,
      itemBuilder: (context, index) => allItems[index],
      separatorBuilder: (context, index) => SizedBox(height: 12.v),
    );
  }

  Widget _buildMonthView({
    List<HomeworkResponseModel> homeworks = const [],
    List<EventResponseModel> events = const [],
    List<CourseModel> courses = const [],
    List<ExternalCalendarEventModel> externalEvents = const [],
  }) {
    final classFilteredAssignments = _filterAssignmentsByClassSelection(
      homeworks,
      courses,
    );
    final categoryFilteredAssignments = _applyCategoryFilterToHomeworks(
      classFilteredAssignments,
    );
    final classFilteredEvents = _filterEventsByClassSelection(events, courses);
    return SingleChildScrollView(
      child: Container(
        constraints: BoxConstraints(minHeight: 300.v),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: primaryColor),
                  onPressed: () {
                    setState(() {
                      _calendarFocusedMonth = DateTime(
                        _calendarFocusedMonth.year,
                        _calendarFocusedMonth.month - 1,
                      );
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_calendarFocusedMonth),
                  style: AppTextStyle.bTextStyle.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: primaryColor),
                  onPressed: () {
                    setState(() {
                      _calendarFocusedMonth = DateTime(
                        _calendarFocusedMonth.year,
                        _calendarFocusedMonth.month + 1,
                      );
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: 8.v),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: dayNamesAbbrev
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: AppTextStyle.cTextStyle.copyWith(
                            color: textColor.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: 8.v),
            // Calendar grid
            _buildCalendarGridForMonth(
              homeworks: categoryFilteredAssignments,
              events: classFilteredEvents,
              courses: courses,
              externalEvents: externalEvents,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGridForMonth({
    List<HomeworkResponseModel> homeworks = const [],
    List<EventResponseModel> events = const [],
    List<CourseModel> courses = const [],
    List<ExternalCalendarEventModel> externalEvents = const [],
  }) {
    final firstDayOfMonth = DateTime(
      _calendarFocusedMonth.year,
      _calendarFocusedMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _calendarFocusedMonth.year,
      _calendarFocusedMonth.month + 1,
      0,
    );
    final startingWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    final previousMonth = DateTime(
      _calendarFocusedMonth.year,
      _calendarFocusedMonth.month,
      0,
    );
    final daysFromPreviousMonth = startingWeekday;

    List<Widget> dayWidgets = [];

    for (int i = daysFromPreviousMonth; i > 0; i--) {
      final day = previousMonth.day - i + 1;
      final date = DateTime(previousMonth.year, previousMonth.month, day);
      final colorDots = _getColorDotsForDate(
        date,
        homeworks: homeworks,
        events: events,
        courses: courses,
        externalEvents: externalEvents,
      );
      dayWidgets.add(
        _buildMonthDayCell(
          day,
          isCurrentMonth: false,
          date: date,
          colorDots: colorDots,
        ),
      );
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(
        _calendarFocusedMonth.year,
        _calendarFocusedMonth.month,
        day,
      );
      final colorDots = _getColorDotsForDate(
        date,
        homeworks: homeworks,
        events: events,
        courses: courses,
        externalEvents: externalEvents,
      );
      dayWidgets.add(
        _buildMonthDayCell(
          day,
          isCurrentMonth: true,
          date: date,
          colorDots: colorDots,
        ),
      );
    }

    final remainingCells = (7 - (dayWidgets.length % 7)) % 7;
    for (int day = 1; day <= remainingCells; day++) {
      final nextMonth = DateTime(
        _calendarFocusedMonth.year,
        _calendarFocusedMonth.month + 1,
        day,
      );
      final colorDots = _getColorDotsForDate(
        nextMonth,
        homeworks: homeworks,
        events: events,
        courses: courses,
        externalEvents: externalEvents,
      );
      dayWidgets.add(
        _buildMonthDayCell(
          day,
          isCurrentMonth: false,
          date: nextMonth,
          colorDots: colorDots,
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 1.0,
      children: dayWidgets,
    );
  }

  Widget _buildMonthDayCell(
    int day, {
    required bool isCurrentMonth,
    required DateTime date,
    List<Color> colorDots = const [],
  }) {
    final isSelected =
        _selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day;

    final isToday =
        DateTime.now().year == date.year &&
        DateTime.now().month == date.month &&
        DateTime.now().day == date.day;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
          _focusedWeek = date;
        });
      },
      child: Container(
        margin: EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : isToday
              ? primaryColor.withValues(alpha: 0.2)
              : transparentColor,
          borderRadius: BorderRadius.circular(6),
          border: isToday && !isSelected
              ? Border.all(color: primaryColor, width: 1)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                color: isSelected
                    ? whiteColor
                    : isCurrentMonth
                    ? textColor
                    : textColor.withValues(alpha: 0.3),
                fontWeight: isSelected || isToday
                    ? FontWeight.w600
                    : FontWeight.w400,
                fontSize: 12,
              ),
            ),
            if (colorDots.isNotEmpty) ...[
              SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: colorDots
                    .take(4)
                    .map(
                      (color) => Container(
                        width: 4,
                        height: 4,
                        margin: EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weekDates = _getWeekDates(_focusedWeek);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerRefreshIfNeeded();
    });

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => CourseBloc(
            courseRepository: CourseRepositoryImpl(
              remoteDataSource: CourseRemoteDataSourceImpl(
                dioClient: DioClient(),
              ),
            ),
          )..add(FetchCoursesEvent()),
        ),
        BlocProvider(
          create: (context) =>
              HomeworkBloc(
                homeworkRepository: HomeworkRepositoryImpl(
                  remoteDataSource: HomeworkRemoteDataSourceImpl(
                    dioClient: DioClient(),
                  ),
                ),
              )..add(
                FetchAllHomeworkEvent(
                  categoryTitles: _activeCategoryFiltersOrNull(),
                ),
              ),
        ),
        BlocProvider(
          create: (context) => EventBloc(
            eventRepository: EventRepositoryImpl(
              remoteDataSource: EventRemoteDataSourceImpl(
                dioClient: DioClient(),
              ),
            ),
          )..add(FetchAllEventsEvent()),
        ),
        BlocProvider(
          create: (context) => ExternalCalendarBloc(
            externalCalendarRepository: ExternalCalendarRepositoryImpl(
              remoteDataSource: ExternalCalendarRemoteDataSourceImpl(
                dioClient: DioClient(),
              ),
            ),
          )..add(FetchExternalCalendarEventsEvent()),
        ),
        BlocProvider(
          create: (context) => CategoryBloc(
            categoryRepository: CategoryRepositoryImpl(
              remoteDataSource: CategoryRemoteDataSourceImpl(
                dioClient: DioClient(),
              ),
            ),
          )..add(const category_event.FetchCategoriesEvent()),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<HomeworkBloc, HomeworkState>(
            listener: (context, state) {
              if (state is HomeworkDeleted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: whiteColor),
                        SizedBox(width: 8),
                        Text('Assignment deleted successfully'),
                      ],
                    ),
                    backgroundColor: greenColor,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
                context.read<HomeworkBloc>().add(
                  FetchAllHomeworkEvent(
                    categoryTitles: _activeCategoryFiltersOrNull(),
                  ),
                );
              } else if (state is HomeworkDeleteError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error_outline, color: whiteColor),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Failed to delete: ${state.message}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: redColor,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 3),
                  ),
                );
              } else if (state is HomeworkDeleting) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(whiteColor),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Deleting assignment...'),
                      ],
                    ),
                    backgroundColor: primaryColor,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          BlocListener<EventBloc, EventState>(
            listener: (context, state) {
              if (state is EventDeleted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: whiteColor),
                        SizedBox(width: 8),
                        Text('Event deleted successfully'),
                      ],
                    ),
                    backgroundColor: greenColor,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
                context.read<EventBloc>().add(FetchAllEventsEvent());
              } else if (state is EventDeleteError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error_outline, color: whiteColor),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Failed to delete: ${state.message}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: redColor,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
          BlocListener<ExternalCalendarBloc, ExternalCalendarState>(
            listener: (context, state) {
              if (state is AllExternalCalendarEventsLoaded) {
                _applyExternalCalendarData(
                  state.calendars,
                  state.eventsByCalendar,
                );
              }
            },
          ),
          BlocListener<CategoryBloc, CategoryState>(
            listener: (context, state) {
              if (state is CategoryLoaded) {
                _populateCategories(state.categories);
              }
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: softGrey,
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 16.v,
                    horizontal: 16.h,
                  ),
                  decoration: BoxDecoration(
                    color: whiteColor,
                    boxShadow: [
                      BoxShadow(
                        color: blackColor.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.settingScreen,
                          ).then((value) async {
                            await loadSettings();
                          });
                        },
                        child: Icon(
                          Icons.settings_outlined,
                          color: primaryColor,
                          size: 24,
                        ),
                      ),

                      Text(
                        'Calendar',
                        style: AppTextStyle.bTextStyle.copyWith(
                          color: textColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.notificationScreen,
                          );
                        },
                        child: Icon(Icons.notifications, color: primaryColor),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.h),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 16.v),

                        Container(
                          padding: EdgeInsets.all(16.h),
                          decoration: BoxDecoration(
                            color: whiteColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: greyColor.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: _goToToday,
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12.h,
                                            vertical: 4.v,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: primaryColor,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              3.adaptSize,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                size: 16.adaptSize,
                                                color: primaryColor,
                                              ),
                                              SizedBox(width: 12.h),
                                              Text(
                                                'Today ',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.chevron_left,
                                          color: textColor,
                                        ),
                                        onPressed: _previousWeek,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      SizedBox(width: 8.h),
                                      IconButton(
                                        icon: Icon(
                                          Icons.chevron_right,
                                          color: textColor,
                                        ),
                                        onPressed: _nextWeek,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.v),

                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 50.h,
                                    child: BlocBuilder<CourseBloc, CourseState>(
                                      builder: (context, state) {
                                        // Get courses from the state
                                        List<CourseModel> courses = [];
                                        if (state is CourseLoaded) {
                                          courses = state.courses;
                                        }

                                        return Builder(
                                          builder: (classesContext) {
                                            return GestureDetector(
                                              onTap: () => _showClassesMenu(
                                                classesContext,
                                                courses,
                                              ),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 2.h,
                                                  vertical: 6.v,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: primaryColor
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: primaryColor,
                                                  ),
                                                ),
                                                child: Icon(
                                                  Icons.menu_book,
                                                  color: primaryColor,
                                                  size: 20,
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 8.h),
                                  Builder(
                                    builder: (filterContext) {
                                      return GestureDetector(
                                        onTap: () =>
                                            _showFilterMenu(filterContext),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10.h,
                                            vertical: 6.v,
                                          ),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: primaryColor.withValues(
                                                alpha: 0.5,
                                              ),
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.filter_alt,
                                            color: primaryColor,
                                            size: 20.adaptSize,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(width: 22.h),

                                  Expanded(
                                    child: SizedBox(
                                      height: 38.v,
                                      child: ListView.separated(
                                        shrinkWrap: true,
                                        itemCount: mobileViews.length,
                                        scrollDirection: Axis.horizontal,
                                        itemBuilder: (context, index) {
                                          bool isSelected =
                                              selectedIndex == index;

                                          return GestureDetector(
                                            onTap: () {
                                              _onTimeFilterChanged(index);
                                            },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 10.h,
                                                vertical: 6.v,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                color: isSelected
                                                    ? primaryColor
                                                    : transparentColor,
                                                border: Border.all(
                                                  color: isSelected
                                                      ? primaryColor
                                                      : greyColor.withValues(
                                                          alpha: 0.5,
                                                        ),
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  mobileViews[index],
                                                  style: AppTextStyle.eTextStyle
                                                      .copyWith(
                                                        color: isSelected
                                                            ? whiteColor
                                                            : textColor,
                                                        fontSize: 13,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        separatorBuilder: (context, index) {
                                          return SizedBox(width: 6.h);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.v),

                        if (_currentViewMode != 'Todos')
                          Text(
                            DateFormat('EEEE, MMMM dd').format(_selectedDate),
                            style: AppTextStyle.bTextStyle.copyWith(
                              color: blackColor,
                            ),
                          )
                        else
                          Text(
                            'Assignments',
                            style: AppTextStyle.bTextStyle.copyWith(
                              color: blackColor,
                            ),
                          ),
                        SizedBox(height: 12.v),

                        if (_currentViewMode == 'Week')
                          Expanded(
                            child: BlocBuilder<CourseBloc, CourseState>(
                              builder: (context, courseState) {
                                return BlocBuilder<HomeworkBloc, HomeworkState>(
                                  builder: (context, homeworkState) {
                                    return BlocBuilder<EventBloc, EventState>(
                                      builder: (context, eventState) {
                                        return BlocBuilder<
                                          ExternalCalendarBloc,
                                          ExternalCalendarState
                                        >(
                                          builder:
                                              (context, externalCalendarState) {
                                                List<CourseModel> courses = [];
                                                if (courseState
                                                    is CourseLoaded) {
                                                  courses = courseState.courses;
                                                }

                                                List<HomeworkResponseModel>
                                                homeworks = [];
                                                if (homeworkState
                                                    is HomeworkLoaded) {
                                                  homeworks =
                                                      homeworkState.homeworks;
                                                }

                                                List<EventResponseModel>
                                                events = [];
                                                if (eventState is EventLoaded) {
                                                  events = eventState.events;
                                                }

                                                final externalEvents =
                                                    _resolveExternalEventsFromState(
                                                      externalCalendarState,
                                                    );

                                                return _buildWeekView(
                                                  homeworks: homeworks,
                                                  events: events,
                                                  courses: courses,
                                                  externalEvents:
                                                      externalEvents,
                                                );
                                              },
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          )
                        else if (_currentViewMode == 'Todos')
                          Expanded(
                            child: BlocBuilder<CourseBloc, CourseState>(
                              builder: (context, courseState) {
                                return BlocBuilder<HomeworkBloc, HomeworkState>(
                                  builder: (context, homeworkState) {
                                    return BlocBuilder<EventBloc, EventState>(
                                      builder: (context, eventState) {
                                        return BlocBuilder<
                                          ExternalCalendarBloc,
                                          ExternalCalendarState
                                        >(
                                          builder:
                                              (context, externalCalendarState) {
                                                List<CourseModel> courses = [];
                                                if (courseState
                                                    is CourseLoaded) {
                                                  courses = courseState.courses;
                                                }

                                                List<HomeworkResponseModel>
                                                homeworks = [];
                                                if (homeworkState
                                                    is HomeworkLoaded) {
                                                  homeworks =
                                                      homeworkState.homeworks;
                                                }

                                                return _buildTodosView(
                                                  courses: courses,
                                                  homeworks: homeworks,
                                                );
                                              },
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          )
                        else
                          BlocBuilder<CourseBloc, CourseState>(
                            builder: (context, courseState) {
                              return BlocBuilder<HomeworkBloc, HomeworkState>(
                                builder: (context, homeworkState) {
                                  return BlocBuilder<EventBloc, EventState>(
                                    builder: (context, eventState) {
                                      return BlocBuilder<
                                        ExternalCalendarBloc,
                                        ExternalCalendarState
                                      >(
                                        builder: (context, externalCalendarState) {
                                          List<CourseModel> courses = [];
                                          if (courseState is CourseLoaded) {
                                            courses = courseState.courses;
                                          }

                                          List<HomeworkResponseModel>
                                          homeworks = [];
                                          if (homeworkState is HomeworkLoaded) {
                                            homeworks = homeworkState.homeworks;
                                          }

                                          List<EventResponseModel> events = [];
                                          if (eventState is EventLoaded) {
                                            events = eventState.events;
                                          }

                                          final externalEvents =
                                              _resolveExternalEventsFromState(
                                                externalCalendarState,
                                              );

                                          if (_currentViewMode == 'Month') {
                                            return _buildMonthView(
                                              homeworks: homeworks,
                                              events: events,
                                              courses: courses,
                                              externalEvents: externalEvents,
                                            );
                                          } else {
                                            return Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: weekDates.map((date) {
                                                final isSelected = _isSameDay(
                                                  date,
                                                  _selectedDate,
                                                );
                                                final dayName = DateFormat(
                                                  'EEE',
                                                ).format(date).substring(0, 3);

                                                return GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _selectedDate = date;
                                                    });
                                                  },
                                                  child: Container(
                                                    width: 40.h,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          vertical: 8.v,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: isSelected
                                                          ? primaryColor
                                                          : transparentColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        Text(
                                                          dayName,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: isSelected
                                                                ? whiteColor
                                                                : greyColor,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                        SizedBox(height: 4.v),
                                                        Text(
                                                          '${date.day}',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            color: isSelected
                                                                ? whiteColor
                                                                : textColor,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            );
                                          }
                                        },
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),

                        SizedBox(height: 12.v),

                        if (_currentViewMode != 'Week' &&
                            _currentViewMode != 'Month' &&
                            _currentViewMode != 'Todos')
                          Expanded(
                            child: BlocBuilder<CourseBloc, CourseState>(
                              builder: (context, courseState) {
                                return BlocBuilder<HomeworkBloc, HomeworkState>(
                                  builder: (context, homeworkState) {
                                    if (courseState is CourseLoading ||
                                        homeworkState is HomeworkLoading) {
                                      return Center(
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation(
                                            whiteColor,
                                          ),
                                          color: primaryColor,
                                        ),
                                      );
                                    }

                                    if (courseState is CourseError) {
                                      return Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.error_outline,
                                              size: 48,
                                              color: redColor,
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              courseState.message,
                                              textAlign: TextAlign.center,
                                              style: AppTextStyle.cTextStyle
                                                  .copyWith(color: textColor),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    if (courseState is CourseLoaded) {
                                      final selectedCourseNames =
                                          selectedClasses.entries
                                              .where((entry) => entry.value)
                                              .map((entry) => entry.key)
                                              .toList();

                                      final filteredCourses = courseState
                                          .courses
                                          .where((course) {
                                            final isClassSelected =
                                                selectedCourseNames.isEmpty ||
                                                selectedCourseNames.contains(
                                                  course.title,
                                                );
                                            if (!isClassSelected) return false;
                                            return _courseHasClassOnDate(
                                              course,
                                              _selectedDate,
                                            );
                                          })
                                          .toList();

                                      final showAssignments =
                                          _isCategoryEnabled('Assignments');
                                      final showEvents = _isCategoryEnabled(
                                        'Events',
                                      );
                                      final showClassSchedule =
                                          _isCategoryEnabled('Class Schedules');
                                      final showExternal = _isCategoryEnabled(
                                        'External Calendars',
                                      );

                                      List<HomeworkResponseModel>
                                      filteredHomework = [];
                                      if (homeworkState is HomeworkLoaded) {
                                        final classFilteredAssignments =
                                            _filterAssignmentsByClassSelection(
                                              homeworkState.homeworks,
                                              courseState.courses,
                                            );
                                        final categoryFilteredAssignments =
                                            _applyCategoryFilterToHomeworks(
                                              classFilteredAssignments,
                                            );
                                        filteredHomework =
                                            categoryFilteredAssignments.where((
                                              homework,
                                            ) {
                                              try {
                                                final start = parseDateTime(
                                                  homework.start,
                                                  _userSettings.timeZone,
                                                );
                                                DateTime? end;
                                                if (homework.end != null &&
                                                    homework.end!.isNotEmpty) {
                                                  end = parseDateTime(
                                                    homework.end!,
                                                    _userSettings.timeZone,
                                                  );
                                                }
                                                if (!_isDateInRange(
                                                  _selectedDate,
                                                  start,
                                                  end,
                                                )) {
                                                  return false;
                                                }
                                                return _matchesAssignmentStatus(
                                                  homework,
                                                );
                                              } catch (e) {
                                                return false;
                                              }
                                            }).toList();
                                      }

                                      List<EventResponseModel> filteredEvents =
                                          [];
                                      final eventState = context
                                          .watch<EventBloc>()
                                          .state;
                                      if (eventState is EventLoaded) {
                                        final classFilteredEventsForDay =
                                            _filterEventsByClassSelection(
                                              eventState.events,
                                              courseState.courses,
                                            );
                                        filteredEvents =
                                            classFilteredEventsForDay.where((
                                              event,
                                            ) {
                                              try {
                                                final eventStart =
                                                    parseDateTime(
                                                      event.start,
                                                      _userSettings.timeZone,
                                                    );
                                                DateTime? eventEnd;
                                                if (event.end != null &&
                                                    event.end!.isNotEmpty) {
                                                  eventEnd = parseDateTime(
                                                    event.end!,
                                                    _userSettings.timeZone,
                                                  );
                                                }
                                                return _isDateInRange(
                                                  _selectedDate,
                                                  eventStart,
                                                  eventEnd,
                                                );
                                              } catch (e) {
                                                return false;
                                              }
                                            }).toList();
                                      }

                                      final externalCalendarState = context
                                          .watch<ExternalCalendarBloc>()
                                          .state;
                                      final allExternalEvents =
                                          _resolveExternalEventsFromState(
                                            externalCalendarState,
                                          );
                                      final filteredExternalEvents =
                                          _filterExternalEventsForSelection(
                                            allExternalEvents,
                                          ).where((event) {
                                            try {
                                              final eventStart = parseDateTime(
                                                event.start,
                                                _userSettings.timeZone,
                                              );
                                              DateTime? eventEnd;
                                              if (event.end != null &&
                                                  event.end!.isNotEmpty) {
                                                eventEnd = parseDateTime(
                                                  event.end!,
                                                  _userSettings.timeZone,
                                                );
                                              }
                                              return _isDateInRange(
                                                _selectedDate,
                                                eventStart,
                                                eventEnd,
                                              );
                                            } catch (e) {
                                              return false;
                                            }
                                          }).toList();
                                      List<Widget> itemWidgets = [];
                                      final coursesToShow = showClassSchedule
                                          ? filteredCourses
                                          : <CourseModel>[];

                                      if (showClassSchedule &&
                                          coursesToShow.isNotEmpty) {
                                        for (
                                          var i = 0;
                                          i < coursesToShow.length;
                                          i++
                                        ) {
                                          final course = coursesToShow[i];
                                          itemWidgets.add(
                                            _buildCourseCard(
                                              course,
                                              i,
                                              _selectedDate,
                                            ),
                                          );
                                        }
                                      }

                                      if (showAssignments &&
                                          filteredHomework.isNotEmpty) {
                                        for (var homework in filteredHomework) {
                                          itemWidgets.add(
                                            _buildAssignmentCard(
                                              homework,
                                              courseState.courses,
                                            ),
                                          );
                                        }
                                      }

                                      if (showEvents &&
                                          filteredEvents.isNotEmpty) {
                                        for (var event in filteredEvents) {
                                          itemWidgets.add(
                                            _buildEventCard(context, event),
                                          );
                                        }
                                      }

                                      // Add external calendar events if "External Calendar" is selected
                                      if (showExternal &&
                                          filteredExternalEvents.isNotEmpty) {
                                        for (var externalEvent
                                            in filteredExternalEvents) {
                                          itemWidgets.add(
                                            _buildExternalCalendarEventCard(
                                              context,
                                              externalEvent,
                                            ),
                                          );
                                        }
                                      }

                                      if (itemWidgets.isEmpty) {
                                        return Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.calendar_today_outlined,
                                                size: 48,
                                                color: textColor.withValues(
                                                  alpha: 0.3,
                                                ),
                                              ),
                                              SizedBox(height: 16),
                                              Text(
                                                'No items for selected date',
                                                style: AppTextStyle.bTextStyle
                                                    .copyWith(
                                                      color: textColor
                                                          .withValues(
                                                            alpha: 0.6,
                                                          ),
                                                    ),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Try selecting different filters',
                                                style: AppTextStyle.cTextStyle
                                                    .copyWith(
                                                      color: textColor
                                                          .withValues(
                                                            alpha: 0.5,
                                                          ),
                                                    ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      return ListView.separated(
                                        itemCount: itemWidgets.length,
                                        itemBuilder: (context, index) =>
                                            itemWidgets[index],
                                        separatorBuilder: (context, index) =>
                                            SizedBox(height: 12.v),
                                      );
                                    }

                                    // Default state - no data loaded yet
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.school_outlined,
                                            size: 48,
                                            color: textColor.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'Loading...',
                                            style: AppTextStyle.bTextStyle
                                                .copyWith(
                                                  color: textColor.withValues(
                                                    alpha: 0.6,
                                                  ),
                                                ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: Padding(
            padding: EdgeInsets.only(bottom: 105.h),
            child: FloatingActionButton(
              backgroundColor: primaryColor,
              elevation: 6,
              shape: const CircleBorder(),
              // ensures perfect circle shape
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.addAssignmentScreen);
              },
              child: Icon(Icons.add, color: whiteColor, size: 28.adaptSize),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(CourseModel course, int index, DateTime dateTime) {
    // Parse course color
    Color courseColor = primaryColor;
    try {
      final colorValue = int.parse(
        course.color.replaceFirst('#', 'ff'),
        radix: 16,
      );
      courseColor = Color(colorValue);
    } catch (e) {
      courseColor = preferredColors[index % preferredColors.length];
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.h),
      decoration: BoxDecoration(
        color: courseColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9.adaptSize),
      ),
      child: Row(
        children: [
          Container(
            width: 4.h,
            height: 38.v,
            decoration: BoxDecoration(
              color: courseColor,
              borderRadius: BorderRadius.circular(12.adaptSize),
            ),
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: AppTextStyle.cTextStyle.copyWith(
                    color: courseColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6.v),
                Row(
                  children: [
                    if (course.room.isNotEmpty) ...[
                      Icon(
                        Icons.room_outlined,
                        size: 14,
                        color: courseColor.withValues(alpha: 0.7),
                      ),
                      SizedBox(width: 4.h),
                      Text(
                        course.room,
                        style: AppTextStyle.fTextStyle.copyWith(
                          color: courseColor.withValues(alpha: 0.7),
                        ),
                      ),
                      SizedBox(width: 12.h),
                    ],
                  ],
                ),
                SizedBox(height: 4.v),
                // Show schedule time for selected day
                if (course.schedules.isNotEmpty &&
                    course.schedules[0].daysOfWeek != '0000000' &&
                    _getCourseTimeForDate(course, dateTime).isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: courseColor.withValues(alpha: 0.6),
                      ),
                      SizedBox(width: 4.h),
                      Text(
                        _getCourseTimeForDate(course, dateTime),
                        style: AppTextStyle.fTextStyle.copyWith(
                          color: courseColor.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    HomeworkResponseModel homework,
    List<CourseModel> courses,
    HomeworkBloc homeworkBloc,
  ) {
    CourseModel? courseNullable;
    try {
      courseNullable = courses.firstWhere((c) => c.id == homework.course);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete: class not found'),
          backgroundColor: redColor,
        ),
      );
      return;
    }

    final course = courseNullable;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              SizedBox(width: 12),
              Text(
                'Delete Assignment',
                style: AppTextStyle.bTextStyle.copyWith(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete this assignment?',
                style: AppTextStyle.cTextStyle.copyWith(
                  color: textColor,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: redColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: redColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.assignment_outlined, color: redColor, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        homework.title,
                        style: AppTextStyle.cTextStyle.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This action cannot be undone.',
                style: AppTextStyle.eTextStyle.copyWith(
                  color: textColor.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: AppTextStyle.cTextStyle.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                // Trigger delete event
                log.info('🗑️ Deleting homework: ${homework.id}');
                log.info('   - Group ID: ${course.courseGroup}');
                log.info('   - Course ID: ${homework.course}');
                log.info('   - Homework ID: ${homework.id}');

                homeworkBloc.add(
                  DeleteHomeworkEvent(
                    groupId: course.courseGroup,
                    courseId: homework.course,
                    homeworkId: homework.id,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: redColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Delete',
                style: AppTextStyle.cTextStyle.copyWith(
                  color: whiteColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAssignmentCard(
    HomeworkResponseModel homework,
    List<CourseModel> courses,
  ) {
    Color assignmentColor = primaryColor;
    try {
      final course = courses.firstWhere(
        (c) => c.id == homework.course,
        orElse: () => courses.isNotEmpty
            ? courses.first
            : CourseModel(
                id: 0,
                title: '',
                room: '',
                credits: '',
                color: '#3f51b5',
                website: '',
                isOnline: false,
                currentGrade: '',
                teacherName: '',
                teacherEmail: '',
                startDate: '',
                endDate: '',
                schedules: [],
                courseGroup: 0,
                numDays: 0,
                numDaysCompleted: 0,
                hasWeightedGrading: false,
                numHomework: 0,
                numHomeworkCompleted: 0,
                numHomeworkGraded: 0,
              ),
      );
      final colorValue = int.parse(
        course.color.replaceFirst('#', 'ff'),
        radix: 16,
      );
      assignmentColor = Color(colorValue);
    } catch (e) {
      assignmentColor = primaryColor;
    }

    // Parse homework time
    String timeDisplay = '';
    try {
      if (homework.allDay) {
        if (_currentViewMode == 'Todos') {
          final startTime = parseDateTime(
            homework.start,
            _userSettings.timeZone,
          );
          timeDisplay = DateFormat('MMM dd, yyyy').format(startTime);
        } else {
          timeDisplay = '';
        }
      } else {
        final startTime = parseDateTime(homework.start, _userSettings.timeZone);
        final formattedTime = DateFormat('h:mm a').format(startTime);
        final formattedDate = DateFormat('MMM dd, yyyy').format(startTime);
        if (homework.end != null &&
            homework.end!.isNotEmpty &&
            homework.start != homework.end) {
          final endTime = parseDateTime(homework.end!, _userSettings.timeZone);
          final formattedEndTime = DateFormat('h:mm a').format(endTime);
          timeDisplay = '$formattedTime - $formattedEndTime';
          if (_currentViewMode == 'Todos') {
            timeDisplay = '$formattedDate • $timeDisplay';
          }
        } else {
          timeDisplay = formattedTime;
          if (_currentViewMode == 'Todos') {
            timeDisplay = '$formattedDate • $timeDisplay';
          }
        }
      }
    } catch (e) {
      timeDisplay = '';
    }

    final bool isCompleted = _completedOverrides.containsKey(homework.id)
        ? _completedOverrides[homework.id]!
        : homework.completed;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.h),
      decoration: BoxDecoration(
        color: assignmentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9.adaptSize),
      ),
      child: Row(
        children: [
          Container(
            width: 4.h,
            height: 38.v,
            decoration: BoxDecoration(
              color: assignmentColor,
              borderRadius: BorderRadius.circular(12.adaptSize),
            ),
          ),
          SizedBox(width: 12.h),
          Checkbox(
            value: isCompleted,
            onChanged: (checked) {
              // Local-only toggle per client request
              setState(() {
                _completedOverrides[homework.id] = checked ?? false;
              });
            },
            activeColor: assignmentColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        homework.title,
                        style: AppTextStyle.cTextStyle.copyWith(
                          color: assignmentColor,
                          fontWeight: FontWeight.w600,
                          decorationColor: assignmentColor,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.v),
                Row(
                  children: [
                    // Category and Grade inline
                    ...(() {
                      final List<Widget> info = [];
                      if (homework.category != null &&
                          _categoriesById[homework.category] != null) {
                        info.add(
                          Icon(
                            Icons.label_outline,
                            size: 14,
                            color: assignmentColor.withValues(alpha: 0.7),
                          ),
                        );
                        info.add(SizedBox(width: 4.h));
                        info.add(
                          Text(
                            _categoriesById[homework.category]!.title,
                            style: AppTextStyle.fTextStyle.copyWith(
                              color: assignmentColor.withValues(alpha: 0.7),
                            ),
                          ),
                        );
                      }
                      // Grade (if present)
                      if (homework.currentGrade != null &&
                          homework.currentGrade!.trim().isNotEmpty) {
                        info.add(SizedBox(width: 10.h));
                        info.add(
                          Icon(
                            Icons.grade_outlined,
                            size: 14,
                            color: assignmentColor.withValues(alpha: 0.7),
                          ),
                        );
                        info.add(SizedBox(width: 4.h));
                        info.add(
                          Text(
                            homework.getFormattedGrade(),
                            style: AppTextStyle.fTextStyle.copyWith(
                              color: assignmentColor.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }
                      return info;
                    })(),
                  ],
                ),
                if (timeDisplay.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: assignmentColor.withValues(alpha: 0.7),
                      ),
                      SizedBox(width: 4.h),
                      Text(
                        timeDisplay,
                        style: AppTextStyle.fTextStyle.copyWith(
                          color: assignmentColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          SizedBox(width: 4.h),

          GestureDetector(
            onTap: () {
              // Navigate to edit assignment screen
              Navigator.pushNamed(
                context,
                AppRoutes.addAssignmentScreen,
                arguments: {'homework': homework, 'isEditMode': true},
              );
            },
            child: Icon(Icons.edit_outlined, size: 22, color: assignmentColor),
          ),
          SizedBox(width: 12.h),
          BlocBuilder<HomeworkBloc, HomeworkState>(
            builder: (context, homeworkState) {
              return GestureDetector(
                onTap: () {
                  _showDeleteConfirmation(
                    context,
                    homework,
                    courses,
                    context.read<HomeworkBloc>(),
                  );
                },
                child: Icon(Icons.delete_outline, size: 22, color: redColor),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, EventResponseModel event) {
    Color eventColor = parseColor(_userSettings.eventsColor);
    String timeDisplay = '';
    try {
      if (event.allDay) {
        timeDisplay = 'All day';
      } else {
        final startTime = parseDateTime(event.start, _userSettings.timeZone);
        final formattedTime = DateFormat('h:mm a').format(startTime);
        if (event.end != null &&
            event.end!.isNotEmpty &&
            event.start != event.end) {
          final endTime = parseDateTime(event.end!, _userSettings.timeZone);
          final formattedEndTime = DateFormat('h:mm a').format(endTime);
          timeDisplay = '$formattedTime - $formattedEndTime';
        } else {
          timeDisplay = formattedTime;
        }
      }
    } catch (e) {
      timeDisplay = 'All day';
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.h),
      decoration: BoxDecoration(
        color: eventColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9.adaptSize),
      ),
      child: Row(
        children: [
          Container(
            width: 4.h,
            height: 38.v,
            decoration: BoxDecoration(
              color: eventColor,
              borderRadius: BorderRadius.circular(12.adaptSize),
            ),
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.event_outlined, size: 16, color: eventColor),
                    SizedBox(width: 6.h),
                    Expanded(
                      child: Text(
                        event.title,
                        style: AppTextStyle.cTextStyle.copyWith(
                          color: eventColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.v),
                if (timeDisplay.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: eventColor.withValues(alpha: 0.7),
                      ),
                      SizedBox(width: 4.h),
                      Text(
                        timeDisplay,
                        style: AppTextStyle.fTextStyle.copyWith(
                          color: eventColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          SizedBox(width: 4.h),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.addEventScreen,
                arguments: {'eventId': event.id, 'isEditMode': true},
              );
            },
            child: Icon(
              Icons.edit_outlined,
              size: 22,
              color: eventColor.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(width: 12.h),
          GestureDetector(
            onTap: () {
              _showDeleteEventConfirmation(context, event);
            },
            child: Icon(
              Icons.delete_outline,
              size: 22,
              color: redColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteEventConfirmation(
    BuildContext context,
    EventResponseModel event,
  ) {
    // Store the EventBloc reference before showing dialog
    final eventBloc = context.read<EventBloc>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Delete Event',
            style: AppTextStyle.cTextStyle.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${event.title}"?',
            style: AppTextStyle.eTextStyle,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: AppTextStyle.eTextStyle.copyWith(color: textColor),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Use the stored EventBloc reference instead of context.read
                eventBloc.add(DeleteEventEvent(eventId: event.id));
              },
              child: Text(
                'Delete',
                style: AppTextStyle.eTextStyle.copyWith(
                  color: redColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExternalCalendarEventCard(
    BuildContext context,
    ExternalCalendarEventModel externalEvent,
  ) {
    Color eventColor = _externalCalendarColor(externalEvent.externalCalendar);
    String timeDisplay = '';
    try {
      if (externalEvent.allDay) {
        timeDisplay = 'All day';
      } else {
        final startTime = parseDateTime(
          externalEvent.start,
          _userSettings.timeZone,
        );
        final formattedTime = DateFormat('h:mm a').format(startTime);
        if (externalEvent.end != null &&
            externalEvent.end!.isNotEmpty &&
            externalEvent.start != externalEvent.end) {
          final endTime = parseDateTime(
            externalEvent.end!,
            _userSettings.timeZone,
          );
          final formattedEndTime = DateFormat('h:mm a').format(endTime);
          timeDisplay = '$formattedTime - $formattedEndTime';
        } else {
          timeDisplay = formattedTime;
        }
      }
    } catch (e) {
      timeDisplay = 'All day';
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.h),
      decoration: BoxDecoration(
        color: eventColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9.adaptSize),
      ),
      child: Row(
        children: [
          Container(
            width: 4.h,
            height: 38.v,
            decoration: BoxDecoration(
              color: eventColor,
              borderRadius: BorderRadius.circular(12.adaptSize),
            ),
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: eventColor,
                    ),
                    SizedBox(width: 6.h),
                    Expanded(
                      child: Text(
                        externalEvent.title,
                        style: AppTextStyle.cTextStyle.copyWith(
                          color: eventColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Badge to indicate external source
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.h,
                        vertical: 2.v,
                      ),
                      decoration: BoxDecoration(
                        color: eventColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'External',
                        style: AppTextStyle.fTextStyle.copyWith(
                          color: eventColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.v),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: eventColor.withValues(alpha: 0.7),
                    ),
                    SizedBox(width: 4.h),
                    Text(
                      timeDisplay,
                      style: AppTextStyle.fTextStyle.copyWith(
                        color: eventColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';
import 'package:heliumapp/data/models/notification/notification_model.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/planner_item_base_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_event_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/error_helpers.dart';
import 'package:heliumapp/utils/platform_behavior.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/sort_helpers.dart';
import 'package:logging/logging.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:timezone/standalone.dart' as tz;

final _log = Logger('utils');

enum PlannerItemType { event, homework, external, courseSchedule }

enum PlannerView { month, week, threeDay, day, agenda, todos }

enum PlannerFilterType {
  assignments('Assignments'),
  events('Events'),
  classSchedules('Class Schedules'),
  externalCalendars('External Calendars');

  const PlannerFilterType(this.value);
  final String value;
}

enum PlannerFilterStatus {
  complete('Complete'),
  incomplete('Incomplete'),
  graded('Graded'),
  ungraded('Ungraded'),
  overdue('Overdue');

  const PlannerFilterStatus(this.value);
  final String value;
}

/// Added to a save's confirmation when the assignment lands outside the dates
/// the Todos view shows.
const outsideTodosWindowNote =
    "It's outside your groups' dates, so it won't show in Todos.";

class PlannerHelper {
  static final List<int> weekStartsOnRemap = [7, 1, 2, 3, 4, 5, 6];

  /// Start value to prefill a new planner item with, in [timeZone].
  ///
  /// Todos and agenda have no confident selection, so they use now; calendar
  /// views use the tapped cell. Returned zoned so the add form can read it as
  /// wall clock without re-resolving it against the device.
  static DateTime? initialDateForNewItem({
    required PlannerView view,
    required DateTime? selectedDate,
    required DateTime now,
    required tz.Location timeZone,
  }) {
    if (view == PlannerView.todos || view == PlannerView.agenda) {
      final local = tz.TZDateTime.from(now, timeZone);
      return tz.TZDateTime(
        timeZone,
        local.year,
        local.month,
        local.day,
        local.hour,
      );
    }
    if (selectedDate == null) {
      return null;
    }
    return HeliumDateTime.wallClockIn(selectedDate, timeZone);
  }

  /// Selection for a region carrying a date but no hour — a month cell, or the
  /// all-day panel. The current [timeZone] hour stands in so new items do not
  /// prefill at midnight. Naive, because SfCalendar is handed it back.
  static DateTime selectionWithCurrentHour({
    required DateTime date,
    required DateTime now,
    required tz.Location timeZone,
  }) {
    final local = tz.TZDateTime.from(now, timeZone);
    return DateTime(date.year, date.month, date.day, local.hour);
  }

  /// Index of the first item in [sorted] due on or after today in [timeZone],
  /// or -1 when every item is in the past. [sorted] must be ordered by `start`.
  static int firstIndexDueOnOrAfter(
    List<HomeworkModel> sorted,
    DateTime now,
    tz.Location timeZone,
  ) {
    // `now` need only be a correct instant, so the device's own zone is moot.
    final startOfToday = HeliumDateTime.midnightIn(now, timeZone);
    for (int i = 0; i < sorted.length; i++) {
      if (!sorted[i].start.isBefore(startOfToday)) {
        return i;
      }
    }
    return -1;
  }

  /// Layout width of the completion checkbox on a planner calendar item.
  /// Kept in sync with the [SizedBox] in `PlannerItemCalendarTile._buildCheckboxWidget`.
  static const double checkboxWidth = 17;

  static void _logMissingEntity(
    int reminderId,
    String entityType,
    int entityId,
  ) {
    final msg =
        'Reminder $reminderId has $entityType ID $entityId but entity is null';
    ErrorHelpers.logAndReport(
      msg,
      Exception(msg),
      StackTrace.current,
    );
  }

  static NotificationModel mapPayloadToNotification(dynamic payload) {
    final reminder = ReminderModel.fromJson(payload);

    final DateTime startDt;
    if (reminder.homework != null) {
      if (reminder.homework!.entity == null) {
        _logMissingEntity(reminder.id, 'homework', reminder.homework!.id);
        startDt = reminder.startOfRange ?? DateTime.now();
      } else {
        startDt = reminder.homework!.entity!.start;
      }
    } else if (reminder.event != null) {
      if (reminder.event!.entity == null) {
        _logMissingEntity(reminder.id, 'event', reminder.event!.id);
        startDt = reminder.startOfRange ?? DateTime.now();
      } else {
        startDt = reminder.event!.entity!.start;
      }
    } else if (reminder.course != null) {
      startDt = reminder.startOfRange ?? DateTime.now();
    } else {
      _log.warning(
        'Reminder ${reminder.id} has no linked entity, using now as "start"',
      );
      startDt = DateTime.now();
    }
    final String start = startDt.toIso8601String();

    return NotificationModel(
      id: reminder.id,
      title: payload['notification_title'] as String,
      body: payload['notification_body'] as String,
      reminder: reminder,
      timestamp: start,
    );
  }

  static CalendarView mapHeliumViewToSfCalendarView(PlannerView view) {
    switch (view) {
      case PlannerView.month:
        return CalendarView.month;
      case PlannerView.week:
        return CalendarView.week;
      case PlannerView.threeDay:
        return CalendarView.day;
      case PlannerView.day:
        return CalendarView.day;
      case PlannerView.agenda:
        return CalendarView.schedule;
      case PlannerView.todos:
        // We default to day so SfCalendar does not query for more data than
        // necessary when we're on a non-calendar view
        return CalendarView.day;
    }
  }

  /// Not injective: `threeDay`, `day` and `todos` all use [CalendarView.day], so a caller
  /// holding a current [PlannerView] must rule it out before trusting this.
  static PlannerView mapSfCalendarViewToHeliumView(CalendarView view) {
    switch (view) {
      case CalendarView.month:
        return PlannerView.month;
      case CalendarView.week:
        return PlannerView.week;
      case CalendarView.day:
        return PlannerView.day;
      case CalendarView.schedule:
        return PlannerView.agenda;
      default:
        // For any other SfCalendar views, default to day
        return PlannerView.day;
    }
  }

  static PlannerView mapApiViewToHeliumView(int view) {
    switch (view) {
      case 0:
        return PlannerView.month;
      case 1:
        return PlannerView.week;
      case 2:
        return PlannerView.day;
      case 5:
        return PlannerView.threeDay;
      case 3:
        return PlannerView.todos;
      case 4:
        return PlannerView.agenda;
      default:
        return PlannerView.month;
    }
  }

  static int mapHeliumViewToApiView(PlannerView view) {
    switch (view) {
      case PlannerView.month:
        return 0;
      case PlannerView.week:
        return 1;
      case PlannerView.day:
        return 2;
      case PlannerView.threeDay:
        return 5;
      case PlannerView.agenda:
        return 4;
      case PlannerView.todos:
        return 3;
    }
  }

  static AlignmentGeometry getAlignmentForView(
    BuildContext context,
    bool isInAgenda,
    PlannerView view,
  ) {
    if (Responsive.isMobile(context)) {
      return Alignment.topLeft;
    }

    if (view == PlannerView.month && isInAgenda) {
      return Alignment.topLeft;
    }

    return view != PlannerView.month ? Alignment.topLeft : Alignment.centerLeft;
  }

  static bool shouldShowCheckbox(
    PlannerItemBaseModel plannerItem,
    double appointmentWidth,
  ) {
    if (plannerItem is! HomeworkModel) {
      return false;
    }

    if (!_hasRoomForCheckbox(appointmentWidth)) {
      return false;
    }

    return true;
  }

  /// True when an appointment is wide enough to render the checkbox and still
  /// leave at least an equal-sized tap zone for opening the item, which ends up
  /// being the 3-day view on mobile as the narrowest.
  static const double minCheckboxWidth = 62;

  static bool _hasRoomForCheckbox(double appointmentWidth) {
    return appointmentWidth >= minCheckboxWidth;
  }

  static bool shouldShowSchoolIcon(
    BuildContext context,
    PlannerItemBaseModel plannerItem,
    PlannerView view,
  ) {
    if (plannerItem is! CourseScheduleEventModel) {
      return false;
    }

    return true;
  }

  static bool shouldShowTimeBeforeTitle(
    BuildContext context,
    plannerItem,
    bool isInAgenda,
    PlannerView view,
  ) {
    if (Responsive.isMobile(context) &&
        (view != PlannerView.agenda || view != PlannerView.todos)) {
      return false;
    }

    if (view == PlannerView.month && isInAgenda) {
      return false;
    }

    if (plannerItem.allDay) {
      return false;
    }

    if (view != PlannerView.month) {
      return false;
    }

    return true;
  }

  static bool shouldShowTimeBelowTitle(
    BuildContext context,
    plannerItem,
    bool isInAgenda,
    PlannerView view,
  ) {
    if (plannerItem.allDay) {
      return false;
    }

    if (Responsive.isMobile(context)) {
      if (view == PlannerView.week || view == PlannerView.day) {
        return false;
      }
    }

    if (!Responsive.isMobile(context) && view == PlannerView.month) {
      if (!isInAgenda) {
        return false;
      }
    }

    return true;
  }

  static bool shouldShowLocationBelowTitle(
    BuildContext context,
    plannerItem,
    bool isInAgenda,
    PlannerView view,
  ) {
    if (isInAgenda && plannerItem.allDay) {
      return true;
    }

    if (plannerItem.allDay) {
      return false;
    }

    if (!Responsive.isMobile(context) && view == PlannerView.month) {
      if (!isInAgenda) {
        return false;
      }
    }

    return true;
  }

  static bool shouldShowEditButton(BuildContext context) {
    return PlatformBehavior.showItemActions(context);
  }

  static bool shouldShowEditButtonForPlannerItem(
    BuildContext context,
    PlannerItemBaseModel plannerItem,
  ) {
    if (!shouldShowEditButton(context)) {
      return false;
    }

    return plannerItem is HomeworkModel || plannerItem is EventModel;
  }

  static bool shouldShowDeleteButton(PlannerItemBaseModel plannerItem) {
    return plannerItem is HomeworkModel || plannerItem is EventModel;
  }

  static bool shouldOpenOnItemTap(BuildContext context) =>
      !shouldShowEditButton(context);

  static List<CourseModel> sortByGroupStartThenByTitle(
    List<CourseModel> courses,
    List<CourseGroupModel> courseGroups,
  ) {
    final sortedGroups = List<CourseGroupModel>.from(courseGroups);
    Sort.byStartDate(sortedGroups);

    final groupOrder = <int, int>{};
    for (int i = 0; i < sortedGroups.length; i++) {
      groupOrder[sortedGroups[i].id] = i;
    }

    return List<CourseModel>.from(courses)..sort((a, b) {
      final groupComparison = (groupOrder[a.courseGroup] ?? 0).compareTo(
        groupOrder[b.courseGroup] ?? 0,
      );
      if (groupComparison != 0) return groupComparison;

      return Sort.compareNatural(a.title, b.title);
    });
  }

  /// Returns the widest `from/to` window spanned by the visible (non-hidden)
  /// groups in [courseGroups], or `null` when none are visible.
  static ({DateTime from, DateTime to})? courseGroupDateWindow(
    List<CourseGroupModel> courseGroups,
  ) {
    final visible = courseGroups
        .where((g) => g.shownOnCalendar != false)
        .toList();
    if (visible.isEmpty) return null;
    return (
      from: visible
          .map((g) => g.startDate)
          .reduce((a, b) => a.isBefore(b) ? a : b),
      to: visible
          .map((g) => g.endDate)
          .reduce((a, b) => a.isAfter(b) ? a : b),
    );
  }

  /// Whether [item] is a repeating assignment or event. A class schedule's
  /// rule describes its meetings, not a repeat the student set.
  static bool isRepeatingItem(PlannerItemBaseModel item) =>
      (item is HomeworkModel || item is EventModel) && item.recurrenceRule != null;

  /// Whether dates from [start] to [end] fall entirely outside the window the
  /// Todos view shows, spanned by the visible groups in [courseGroups].
  static bool isOutsideTodosWindow(
    DateTime start,
    DateTime end,
    List<CourseGroupModel> courseGroups,
  ) {
    final window = courseGroupDateWindow(courseGroups);
    return window != null && isOutsideWindow(start, end, window);
  }

  /// Whether dates from [start] to [end] fall entirely outside [window].
  static bool isOutsideWindow(
    DateTime start,
    DateTime end,
    ({DateTime from, DateTime to}) window,
  ) =>
      end.isBefore(window.from) || start.isAfter(window.to);

  /// Rounds [minute] to the nearest 30-minute boundary (0 or 30).
  /// Used when snapping drag-and-drop and resize times on the calendar.
  /// A result of 60 is valid; DateTime/TZDateTime constructors overflow it
  /// to minute 0 of the next hour.
  static int roundMinute(int minute) => ((minute + 15) ~/ 30) * 30;

  static (DateTime, DateTime) droppedTimeRange({
    required PlannerItemBaseModel plannerItem,
    required DateTime currentStart,
    required DateTime currentEnd,
    required AppointmentDragEndDetails dropDetails,
    required UserSettingsModel userSettings,
    required PlannerView currentView,
  }) {
    final timeZone = userSettings.timeZone;
    final startDateTime = tz.TZDateTime.from(currentStart, timeZone);
    final endDateTime = tz.TZDateTime.from(currentEnd, timeZone);
    final Duration duration = endDateTime.difference(startDateTime);

    final roundedMinute = PlannerHelper.roundMinute(
      dropDetails.droppingTime!.minute,
    );

    final DateTime start = tz.TZDateTime(
      userSettings.timeZone,
      dropDetails.droppingTime!.year,
      dropDetails.droppingTime!.month,
      dropDetails.droppingTime!.day,
      currentView == PlannerView.month
          ? startDateTime.hour
          : dropDetails.droppingTime!.hour,
      currentView == PlannerView.month
          ? startDateTime.minute
          : roundedMinute,
    );
    final DateTime end = plannerItem.allDay
        ? HeliumDateTime.allDayEndAfterMove(start, startDateTime, endDateTime)
        : start.add(duration);

    return (start, end);
  }

  static (DateTime, DateTime) resizedTimeRange({
    required PlannerItemBaseModel plannerItem,
    required AppointmentResizeEndDetails resizeDetails,
    required UserSettingsModel userSettings,
  }) {
    DateTime start = tz.TZDateTime(
      userSettings.timeZone,
      resizeDetails.startTime!.year,
      resizeDetails.startTime!.month,
      resizeDetails.startTime!.day,
      resizeDetails.startTime!.hour,
      PlannerHelper.roundMinute(resizeDetails.startTime!.minute),
    );

    DateTime end = tz.TZDateTime(
      userSettings.timeZone,
      resizeDetails.endTime!.year,
      resizeDetails.endTime!.month,
      resizeDetails.endTime!.day,
      resizeDetails.endTime!.hour,
      PlannerHelper.roundMinute(resizeDetails.endTime!.minute),
    );
    if (plannerItem.allDay) {
      (start, end) = HeliumDateTime.dayRangeIn(
        resizeDetails.startTime!,
        resizeDetails.endTime!,
        userSettings.timeZone,
      );
    }

    return (start, end);
  }

  static String occurrenceWhenLabel({
    required PlannerItemBaseModel occurrence,
    required DateTime occurrenceDate,
    required UserSettingsModel userSettings,
  }) {
    final localStart = HeliumDateTime.toLocal(
      occurrence.start,
      userSettings.timeZone,
    );
    if (!DateUtils.isSameDay(localStart, occurrenceDate)) {
      return HeliumDateTime.formatDateForTodos(occurrenceDate);
    }
    return occurrence.allDay
        ? HeliumDateTime.formatDateForTodos(localStart)
        : HeliumDateTime.formatDateAndTimeForTodos(localStart);
  }

  /// Whether an assignment counts as overdue at [now]: not [completed], and due ([start]) before then. The Planner's
  /// Overdue filter and the widgets' Overdue section all use this rule.
  static bool isOverdue({required bool completed, required DateTime start, required DateTime now}) =>
      !completed && start.isBefore(now);

  /// The assignments an agenda shows at [now]: due from [daysBack] days before today through the end of the day
  /// [daysAhead] days after today, repeating ones expanded into occurrences in [timeZone]. Completed assignments
  /// are left out once they are due. Each day's items are in the Planner's own order. [olderOverdueCount] counts
  /// the incomplete one-time assignments due before that window.
  static ({List<HomeworkModel> items, int olderOverdueCount}) agendaItems({
    required List<HomeworkModel> homeworks,
    required tz.Location timeZone,
    required DateTime now,
    required int daysBack,
    required int daysAhead,
  }) {
    final today = HeliumDateTime.midnightIn(now, timeZone);
    final from = HeliumDateTime.addDays(today, -daysBack);
    final to = HeliumDateTime.addDays(today, daysAhead + 1);
    final items = <HomeworkModel>[];
    var olderOverdueCount = 0;

    for (final homework in homeworks) {
      if (homework.recurrenceRule == null) {
        if (homework.completed && homework.start.isBefore(now)) continue;
        if (homework.start.isBefore(from)) {
          olderOverdueCount++;
        } else if (homework.start.isBefore(to)) {
          items.add(homework);
        }
        continue;
      }
      for (final start in _agendaOccurrenceStarts(homework, timeZone, from, to)) {
        if (homework.completed && start.isBefore(now)) continue;
        final (_, end) = HeliumDateTime.occurrenceBounds(homework.start, homework.end, start,
            allDay: homework.allDay, timeZone: timeZone);
        items.add(homework.copyWith(start: start, end: end));
      }
    }

    return (items: _inPlannerDayOrder(items, timeZone), olderOverdueCount: olderOverdueCount);
  }

  static List<HomeworkModel> _inPlannerDayOrder(List<HomeworkModel> items, tz.Location timeZone) {
    final itemsByDay = <tz.TZDateTime, List<HomeworkModel>>{};
    for (final item in items) {
      itemsByDay.putIfAbsent(HeliumDateTime.midnightIn(item.start, timeZone), () => []).add(item);
    }
    final ordered = <HomeworkModel>[];
    for (final day in itemsByDay.keys.toList()..sort()) {
      final dayItems = itemsByDay[day]!;
      Sort.byStartThenTitleForDay(dayItems, day);
      ordered.addAll(dayItems);
    }
    return ordered;
  }

  static Iterable<tz.TZDateTime> _agendaOccurrenceStarts(
    PlannerItemBaseModel item,
    tz.Location timeZone,
    DateTime from,
    DateTime to,
  ) sync* {
    for (final occurrence in occurrencesIn(item.recurrenceRule!, item.start, timeZone, from: from, to: to)) {
      final start = HeliumDateTime.wallClockIn(occurrence, timeZone);
      if (!start.isBefore(from) && start.isBefore(to) && !isExceptionOn(item, start, timeZone)) yield start;
    }
  }

  /// The color the Planner draws [item] in: events in the events color; assignments in their [category]'s color
  /// when the user colors by category, otherwise their [course]'s.
  static Color itemColor(
    PlannerItemBaseModel item,
    UserSettingsModel settings, {
    CourseModel? course,
    CategoryModel? category,
  }) {
    if (item is EventModel) return settings.eventsColor;
    if (item is HomeworkModel) {
      if (settings.colorByCategory && category != null) return category.color;
      return course?.color ?? FallbackConstants.fallbackColor;
    }
    return item.color ?? FallbackConstants.fallbackColor;
  }

  /// `exceptionDates` mixes forms: course-schedule exceptions are naive local
  /// midnight, API EXDATEs are UTC instants, and an all-day series' date-only
  /// EXDATE can be UTC midnight naming a calendar date.
  static bool hasDateOnlyExceptions(PlannerItemBaseModel item) =>
      item.allDay && item is! CourseScheduleEventModel;

  static bool isExceptionOn(PlannerItemBaseModel item, tz.TZDateTime occurrence, tz.Location timeZone) {
    return item.exceptionDates.any((e) {
      final local = hasDateOnlyExceptions(item)
          ? HeliumDateTime.allDayExceptionIn(e, timeZone)
          : HeliumDateTime.wallClockIn(e, timeZone);
      return local.year == occurrence.year &&
          local.month == occurrence.month &&
          local.day == occurrence.day;
    });
  }

  /// The end of the meeting starting exactly at [meetingStart] across all
  /// schedules' recurrence groups, or null.
  /// The starts of [rule]'s occurrences from [from] to [to], for a series
  /// starting at [start], expanded in [timeZone].
  static List<DateTime> occurrencesIn(
    String rule,
    DateTime start,
    tz.Location timeZone, {
    required DateTime from,
    required DateTime to,
  }) {
    return SfCalendar.getRecurrenceDateTimeCollection(
      HeliumDateTime.recurrenceRuleWithLocalUntil(rule, timeZone),
      tz.TZDateTime.from(start, timeZone),
      specificStartDate: from,
      specificEndDate: to,
    );
  }

  static tz.TZDateTime? courseMeetingEnd({
    required List<CourseScheduleModel> schedules,
    required DateTime meetingStart,
    required tz.Location timeZone,
  }) {
    final local = tz.TZDateTime.from(meetingStart, timeZone);
    final expandFrom = DateTime(local.year, local.month, local.day - 1);
    final expandTo = DateTime(local.year, local.month, local.day + 2);
    for (final schedule in schedules) {
      for (final group in schedule.recurrenceGroups) {
        final occurrences = occurrencesIn(group.recurrenceRule, group.start, timeZone, from: expandFrom, to: expandTo);
        for (final occurrence in occurrences) {
          final occurrenceStart = HeliumDateTime.wallClockIn(occurrence, timeZone);
          if (occurrenceStart.isAtSameMomentAs(meetingStart)) {
            return occurrenceStart.add(group.end.difference(group.start));
          }
        }
      }
    }
    return null;
  }
}

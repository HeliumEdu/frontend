import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_event_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_recurrence_group_model.dart';
import 'package:logging/logging.dart';

final _log = Logger('data.sources');

/// Builds course schedule events from the server-resolved recurrence groups on
/// each schedule. The backend computes the RRULE, time-slot grouping, and
/// exception dates (see `coursescheduleservice.course_schedule_to_recurrence_groups`);
/// this source only hydrates them into [CourseScheduleEventModel]s with the
/// parent course's display fields, letting SfCalendar expand the recurrences.
///
/// If [search] is provided, only events whose title contains the search string
/// (case-insensitive) are returned.
class CourseScheduleBuilderSource {
  List<CourseScheduleEventModel> buildCourseScheduleEvents({
    required List<CourseModel> courses,
    required DateTime from,
    required DateTime to,
    Map<int, CourseGroupModel>? courseGroupsById,
    String? search,
    bool? shownOnCalendar,
  }) {
    _log.info('Building CourseScheduleEvents for ${courses.length} course(s)');

    final List<CourseScheduleEventModel> events = [];

    for (final course in courses) {
      if (from.isAfter(course.endDate) || to.isBefore(course.startDate)) {
        continue;
      }

      for (final schedule in course.schedules) {
        int slotIndex = 0;
        for (final group in schedule.recurrenceGroups) {
          events.add(
            _buildEvent(
              course: course,
              schedule: schedule,
              group: group,
              slotIndex: slotIndex,
            ),
          );
          slotIndex++;
        }
      }
    }

    List<CourseScheduleEventModel> filteredEvents = events;
    if (search != null && search.isNotEmpty) {
      final searchLower = search.toLowerCase();
      filteredEvents = events
          .where((event) => event.title.toLowerCase().contains(searchLower))
          .toList();
    }

    filteredEvents.sort((a, b) => a.start.compareTo(b.start));

    _log.info('... built ${filteredEvents.length} CourseScheduleEvent(s)');
    return filteredEvents;
  }

  CourseScheduleEventModel _buildEvent({
    required CourseModel course,
    required CourseScheduleModel schedule,
    required CourseScheduleRecurrenceGroupModel group,
    required int slotIndex,
  }) {
    return CourseScheduleEventModel(
      id: schedule.id * 100 + slotIndex,
      title: course.title,
      allDay: false,
      showEndTime: true,
      start: group.start,
      end: group.end,
      priority: 50,
      url: null,
      comments: '',
      attachments: [],
      reminders: [],
      color: course.color,
      ownerId: '${course.id}',
      recurrenceRule: group.recurrenceRule,
      exceptionDates: group.exceptionDates,
    );
  }
}

import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_event_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/data/models/planner/request/course_schedule_request_model.dart';

abstract class CourseScheduleRepository {
  Future<List<CourseScheduleEventModel>> getCourseScheduleEvents({
    required List<CourseModel> courses,
    required DateTime from,
    required DateTime to,
    Map<int, CourseGroupModel>? courseGroupsById,
    String? search,
    bool? shownOnCalendar,
    bool forceRefresh = false,
  });

  Future<List<CourseScheduleModel>> getCourseSchedules({
    bool? shownOnCalendar,
    bool forceRefresh = false,
  });

  Future<CourseScheduleModel> getCourseScheduleForCourse(
    int groupId,
    int courseId, {
    bool forceRefresh = false,
  });

  Future<CourseScheduleModel> createCourseSchedule(
    int groupId,
    int courseId,
    CourseScheduleRequestModel request,
  );

  Future<CourseScheduleModel> updateCourseSchedule(
    int groupId,
    int courseId,
    int scheduleId,
    CourseScheduleRequestModel request,
  );

  Future<List<CourseScheduleModel>> getCourseSchedulesForCourse(
    int groupId,
    int courseId, {
    bool forceRefresh = false,
  });

  Future<void> deleteCourseSchedule(int groupId, int courseId, int scheduleId);
}

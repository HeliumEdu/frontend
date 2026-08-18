import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_event_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/data/models/planner/request/course_schedule_request_model.dart';
import 'package:heliumapp/data/sources/course_schedule_builder_source.dart';
import 'package:heliumapp/data/sources/course_schedule_remote_data_source.dart';
import 'package:heliumapp/domain/repositories/course_schedule_event_repository.dart';

class CourseScheduleRepositoryImpl implements CourseScheduleRepository {
  final CourseScheduleRemoteDataSource remoteDataSource;
  final CourseScheduleBuilderSource builderSource;

  CourseScheduleRepositoryImpl({
    required this.remoteDataSource,
    required this.builderSource,
  });

  @override
  Future<List<CourseScheduleEventModel>> getCourseScheduleEvents({
    required List<CourseModel> courses,
    required DateTime from,
    required DateTime to,
    Map<int, CourseGroupModel>? courseGroupsById,
    String? search,
    bool? shownOnCalendar,
    bool forceRefresh = false,
  }) async {
    return builderSource.buildCourseScheduleEvents(
      courses: courses,
      from: from,
      to: to,
      courseGroupsById: courseGroupsById,
      search: search,
      shownOnCalendar: shownOnCalendar,
    );
  }

  @override
  Future<List<CourseScheduleModel>> getCourseSchedules({
    bool? shownOnCalendar,
    bool forceRefresh = false,
  }) async {
    return remoteDataSource.getCourseSchedules(
      shownOnCalendar: shownOnCalendar,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Future<CourseScheduleModel> getCourseScheduleForCourse(
    int groupId,
    int courseId, {
    bool forceRefresh = false,
  }) async {
    return remoteDataSource.getCourseScheduleForCourse(
      groupId,
      courseId,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Future<CourseScheduleModel> createCourseSchedule(
    int groupId,
    int courseId,
    CourseScheduleRequestModel request,
  ) async {
    return remoteDataSource.createCourseSchedule(
      groupId,
      courseId,
      request,
    );
  }

  @override
  Future<CourseScheduleModel> updateCourseSchedule(
    int groupId,
    int courseId,
    int scheduleId,
    CourseScheduleRequestModel request,
  ) async {
    return remoteDataSource.updateCourseSchedule(
      groupId,
      courseId,
      scheduleId,
      request,
    );
  }

  @override
  Future<List<CourseScheduleModel>> getCourseSchedulesForCourse(
    int groupId,
    int courseId, {
    bool forceRefresh = false,
  }) async {
    return remoteDataSource.getCourseSchedulesForCourse(
      groupId,
      courseId,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Future<void> deleteCourseSchedule(
    int groupId,
    int courseId,
    int scheduleId,
  ) async {
    return remoteDataSource.deleteCourseSchedule(groupId, courseId, scheduleId);
  }
}

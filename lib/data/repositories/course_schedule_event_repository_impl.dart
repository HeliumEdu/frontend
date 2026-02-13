// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

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
    String? search,
    bool? shownOnCalendar,
  }) async {
    return builderSource.buildCourseScheduleEvents(
      courses: courses,
      from: from,
      to: to,
      search: search,
      shownOnCalendar: shownOnCalendar,
    );
  }

  @override
  Future<List<CourseScheduleModel>> getCourseSchedules({
    bool? shownOnCalendar,
  }) async {
    return await remoteDataSource.getCourseSchedules(
      shownOnCalendar: shownOnCalendar,
    );
  }

  @override
  Future<CourseScheduleModel> getCourseScheduleForCourse(
    int groupId,
    int courseId,
  ) async {
    return await remoteDataSource.getCourseScheduleForCourse(groupId, courseId);
  }

  @override
  Future<CourseScheduleModel> createCourseSchedule(
    int groupId,
    int courseId,
    CourseScheduleRequestModel request,
  ) async {
    return await remoteDataSource.createCourseSchedule(
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
    return await remoteDataSource.updateCourseSchedule(
      groupId,
      courseId,
      scheduleId,
      request,
    );
  }
}

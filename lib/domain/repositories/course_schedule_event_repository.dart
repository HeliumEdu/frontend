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

abstract class CourseScheduleRepository {
  Future<List<CourseScheduleEventModel>> getCourseScheduleEvents({
    required List<CourseModel> courses,
    required DateTime from,
    required DateTime to,
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
}

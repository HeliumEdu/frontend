// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_group_request_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_request_model.dart';

abstract class CourseRepository {
  Future<List<CourseGroupModel>> getCourseGroups();

  Future<CourseGroupModel> getCourseGroup(int id);

  Future<CourseGroupModel> createCourseGroup(CourseGroupRequestModel request);

  Future<CourseGroupModel> updateCourseGroup(
    int groupId,
    CourseGroupRequestModel request,
  );

  Future<void> deleteCourseGroup(int groupId);

  Future<List<CourseModel>> getCourses({int? groupId, bool? shownOnCalendar});

  Future<CourseModel> getCourse(int groupId, int courseId);

  Future<CourseModel> createCourse(int groupId, CourseRequestModel request);

  Future<CourseModel> updateCourse(
    int groupId,
    int courseId,
    CourseRequestModel request,
  );

  Future<void> deleteCourse(int groupId, int courseId);
}

// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/request/course_group_request_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/request/course_request_model.dart';
import 'package:heliumapp/data/sources/course_remote_data_source.dart';
import 'package:heliumapp/domain/repositories/course_repository.dart';

class CourseRepositoryImpl implements CourseRepository {
  final CourseRemoteDataSource remoteDataSource;

  @override
  Future<List<CourseGroupModel>> getCourseGroups({
    bool? shownOnCalendar,
    bool forceRefresh = false,
  }) async {
    return remoteDataSource.getCourseGroups(
      shownOnCalendar: shownOnCalendar,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Future<CourseGroupModel> getCourseGroup(int id, {bool forceRefresh = false}) async {
    return remoteDataSource.getCourseGroup(id, forceRefresh: forceRefresh);
  }

  @override
  Future<CourseGroupModel> createCourseGroup(
    CourseGroupRequestModel request,
  ) async {
    return remoteDataSource.createCourseGroup(request);
  }

  @override
  Future<CourseGroupModel> updateCourseGroup(
    int groupId,
    CourseGroupRequestModel request,
  ) async {
    return remoteDataSource.updateCourseGroup(groupId, request);
  }

  @override
  Future<void> deleteCourseGroup(int groupId) async {
    return remoteDataSource.deleteCourseGroup(groupId);
  }

  CourseRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CourseModel>> getCourses({
    int? groupId,
    bool? shownOnCalendar,
    bool forceRefresh = false,
  }) async {
    return remoteDataSource.getCourses(
      groupId: groupId,
      shownOnCalendar: shownOnCalendar,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Future<CourseModel> getCourse(int groupId, int courseId, {bool forceRefresh = false}) async {
    return remoteDataSource.getCourse(groupId, courseId, forceRefresh: forceRefresh);
  }

  @override
  Future<CourseModel> createCourse(
    int groupId,
    CourseRequestModel request,
  ) async {
    return remoteDataSource.createCourse(groupId, request);
  }

  @override
  Future<CourseModel> updateCourse(
    int groupId,
    int courseId,
    CourseRequestModel request,
  ) async {
    return remoteDataSource.updateCourse(groupId, courseId, request);
  }

  @override
  Future<void> deleteCourse(int groupId, int courseId) async {
    return remoteDataSource.deleteCourse(groupId, courseId);
  }
}

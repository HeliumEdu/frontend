// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:io';

import 'package:heliumapp/data/sources/course_remote_data_source.dart';
import 'package:heliumapp/data/models/planner/attachment_model.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/category_request_model.dart';
import 'package:heliumapp/data/models/planner/course_group_request_model.dart';
import 'package:heliumapp/data/models/planner/course_group_response_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_request_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_request_model.dart';
import 'package:heliumapp/domain/repositories/course_repository.dart';

class CourseRepositoryImpl implements CourseRepository {
  final CourseRemoteDataSource remoteDataSource;

  CourseRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CourseModel>> getCourses() async {
    return await remoteDataSource.getCourses();
  }

  @override
  Future<List<CourseModel>> getCoursesByGroupId(int groupId) async {
    return await remoteDataSource.getCoursesByGroupId(groupId);
  }

  @override
  Future<CourseModel> getCourseById(int groupId, int courseId) async {
    return await remoteDataSource.getCourseById(groupId, courseId);
  }

  @override
  Future<CourseModel> createCourse(CourseRequestModel request) async {
    return await remoteDataSource.createCourse(request);
  }

  @override
  Future<CourseModel> updateCourse(
    int groupId,
    int courseId,
    CourseRequestModel request,
  ) async {
    return await remoteDataSource.updateCourse(groupId, courseId, request);
  }

  @override
  Future<void> deleteCourse(int groupId, int courseId) async {
    return await remoteDataSource.deleteCourse(groupId, courseId);
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

  @override
  Future<List<CategoryModel>> getCategoriesByCourse(
    int groupId,
    int courseId,
  ) async {
    return await remoteDataSource.getCategoriesByCourse(groupId, courseId);
  }

  @override
  Future<CategoryModel> createCategory(
    int groupId,
    int courseId,
    CategoryRequestModel request,
  ) async {
    return await remoteDataSource.createCategory(groupId, courseId, request);
  }

  @override
  Future<CategoryModel> updateCategory(
    int groupId,
    int courseId,
    int categoryId,
    CategoryRequestModel request,
  ) async {
    return await remoteDataSource.updateCategory(
      groupId,
      courseId,
      categoryId,
      request,
    );
  }

  @override
  Future<void> deleteCategory(int groupId, int courseId, int categoryId) async {
    return await remoteDataSource.deleteCategory(groupId, courseId, categoryId);
  }

  @override
  Future<List<AttachmentModel>> uploadAttachments({
    required List<File> files,
    int? courseId,
    int? eventId,
    int? homeworkId,
  }) async {
    return await remoteDataSource.uploadAttachments(
      files: files,
      courseId: courseId,
      eventId: eventId,
      homeworkId: homeworkId,
    );
  }

  @override
  Future<List<AttachmentModel>> getAttachments({
    int? courseId,
    int? eventId,
    int? homeworkId,
  }) async {
    return await remoteDataSource.getAttachments(
      courseId: courseId,
      eventId: eventId,
      homeworkId: homeworkId,
    );
  }

  @override
  Future<void> deleteAttachment(int attachmentId) async {
    return await remoteDataSource.deleteAttachment(attachmentId);
  }

  @override
  Future<List<CourseGroupResponseModel>> getCourseGroups() async {
    return await remoteDataSource.getCourseGroups();
  }

  @override
  Future<CourseGroupResponseModel> createCourseGroup(
    CourseGroupRequestModel request,
  ) async {
    return await remoteDataSource.createCourseGroup(request);
  }

  @override
  Future<CourseGroupResponseModel> updateCourseGroup(
    int groupId,
    CourseGroupRequestModel request,
  ) async {
    return await remoteDataSource.updateCourseGroup(groupId, request);
  }

  @override
  Future<void> deleteCourseGroup(int groupId) async {
    return await remoteDataSource.deleteCourseGroup(groupId);
  }
}

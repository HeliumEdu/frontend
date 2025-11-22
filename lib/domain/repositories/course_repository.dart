// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:io';

import 'package:helium_mobile/data/models/planner/attachment_model.dart';
import 'package:helium_mobile/data/models/planner/category_model.dart';
import 'package:helium_mobile/data/models/planner/category_request_model.dart';
import 'package:helium_mobile/data/models/planner/course_group_request_model.dart';
import 'package:helium_mobile/data/models/planner/course_group_response_model.dart';
import 'package:helium_mobile/data/models/planner/course_model.dart';
import 'package:helium_mobile/data/models/planner/course_request_model.dart';
import 'package:helium_mobile/data/models/planner/course_schedule_model.dart';
import 'package:helium_mobile/data/models/planner/course_schedule_request_model.dart';

abstract class CourseRepository {
  Future<List<CourseModel>> getCourses();

  Future<List<CourseModel>> getCoursesByGroupId(int groupId);

  Future<CourseModel> getCourseById(int groupId, int courseId);

  Future<CourseModel> createCourse(CourseRequestModel request);

  Future<CourseModel> updateCourse(
    int groupId,
    int courseId,
    CourseRequestModel request,
  );

  Future<void> deleteCourse(int groupId, int courseId);

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

  Future<List<CategoryModel>> getCategoriesByCourse(int groupId, int courseId);

  Future<CategoryModel> createCategory(
    int groupId,
    int courseId,
    CategoryRequestModel request,
  );

  Future<CategoryModel> updateCategory(
    int groupId,
    int courseId,
    int categoryId,
    CategoryRequestModel request,
  );

  Future<void> deleteCategory(int groupId, int courseId, int categoryId);

  Future<List<AttachmentModel>> uploadAttachments({
    required List<File> files,
    int? courseId,
    int? eventId,
    int? homeworkId,
  });

  Future<List<AttachmentModel>> getAttachments({
    int? courseId,
    int? eventId,
    int? homeworkId,
  });

  Future<void> deleteAttachment(int attachmentId);

  Future<List<CourseGroupResponseModel>> getCourseGroups();

  Future<CourseGroupResponseModel> createCourseGroup(
    CourseGroupRequestModel request,
  );

  Future<CourseGroupResponseModel> updateCourseGroup(
    int groupId,
    CourseGroupRequestModel request,
  );

  Future<void> deleteCourseGroup(int groupId);
}

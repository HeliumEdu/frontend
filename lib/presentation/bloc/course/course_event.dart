// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:io';

import 'package:heliumapp/data/models/planner/category_request_model.dart';
import 'package:heliumapp/data/models/planner/course_group_request_model.dart';
import 'package:heliumapp/data/models/planner/course_request_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_request_model.dart';

abstract class CourseEvent {}

class FetchCoursesEvent extends CourseEvent {}

class FetchCoursesByGroupEvent extends CourseEvent {
  final int groupId;

  FetchCoursesByGroupEvent({required this.groupId});
}

class FetchCourseByIdEvent extends CourseEvent {
  final int groupId;
  final int courseId;

  FetchCourseByIdEvent({required this.groupId, required this.courseId});
}

class CreateCourseEvent extends CourseEvent {
  final CourseRequestModel request;

  CreateCourseEvent({required this.request});
}

class UpdateCourseEvent extends CourseEvent {
  final int groupId;
  final int courseId;
  final CourseRequestModel request;

  UpdateCourseEvent({
    required this.groupId,
    required this.courseId,
    required this.request,
  });
}

class DeleteCourseEvent extends CourseEvent {
  final int groupId;
  final int courseId;

  DeleteCourseEvent({required this.groupId, required this.courseId});
}

class CreateCourseScheduleEvent extends CourseEvent {
  final int groupId;
  final int courseId;
  final CourseScheduleRequestModel request;

  CreateCourseScheduleEvent({
    required this.groupId,
    required this.courseId,
    required this.request,
  });
}

class UpdateCourseScheduleEvent extends CourseEvent {
  final int groupId;
  final int courseId;
  final int scheduleId;
  final CourseScheduleRequestModel request;

  UpdateCourseScheduleEvent({
    required this.groupId,
    required this.courseId,
    required this.scheduleId,
    required this.request,
  });
}

class FetchCategoriesEvent extends CourseEvent {
  final int groupId;
  final int courseId;

  FetchCategoriesEvent({required this.groupId, required this.courseId});
}

class CreateCategoryEvent extends CourseEvent {
  final int groupId;
  final int courseId;
  final CategoryRequestModel request;

  CreateCategoryEvent({
    required this.groupId,
    required this.courseId,
    required this.request,
  });
}

class UpdateCategoryEvent extends CourseEvent {
  final int groupId;
  final int courseId;
  final int categoryId;
  final CategoryRequestModel request;

  UpdateCategoryEvent({
    required this.groupId,
    required this.courseId,
    required this.categoryId,
    required this.request,
  });
}

class DeleteCategoryEvent extends CourseEvent {
  final int groupId;
  final int courseId;
  final int categoryId;

  DeleteCategoryEvent({
    required this.groupId,
    required this.courseId,
    required this.categoryId,
  });
}

class UploadAttachmentsEvent extends CourseEvent {
  final List<File> files;
  final int? courseId;
  final int? eventId;
  final int? homeworkId;

  UploadAttachmentsEvent({
    required this.files,
    this.courseId,
    this.eventId,
    this.homeworkId,
  });
}

class FetchAttachmentsEvent extends CourseEvent {
  final int? courseId;
  final int? eventId;
  final int? homeworkId;

  FetchAttachmentsEvent({this.courseId, this.eventId, this.homeworkId});
}

class DeleteAttachmentEvent extends CourseEvent {
  final int attachmentId;

  DeleteAttachmentEvent({required this.attachmentId});
}

class FetchCourseGroupsEvent extends CourseEvent {}

class CreateCourseGroupEvent extends CourseEvent {
  final CourseGroupRequestModel request;

  CreateCourseGroupEvent({required this.request});
}

class UpdateCourseGroupEvent extends CourseEvent {
  final int groupId;
  final CourseGroupRequestModel request;

  UpdateCourseGroupEvent({required this.groupId, required this.request});
}

class DeleteCourseGroupEvent extends CourseEvent {
  final int groupId;

  DeleteCourseGroupEvent({required this.groupId});
}

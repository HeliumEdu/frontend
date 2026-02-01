// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/course_group_request_model.dart';
import 'package:heliumapp/data/models/planner/course_request_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_request_model.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';

abstract class CourseEvent extends BaseEvent {
  CourseEvent({required super.origin});
}

class FetchCoursesScreenDataEvent extends CourseEvent {
  FetchCoursesScreenDataEvent({required super.origin});
}

class FetchCourseScreenDataEvent extends CourseEvent {
  final int courseGroupId;
  final int? courseId;

  FetchCourseScreenDataEvent({
    required super.origin,
    required this.courseGroupId,
    required this.courseId,
  });
}

class FetchCoursesEvent extends CourseEvent {
  final bool? shownOnCalendar;

  FetchCoursesEvent({required super.origin, this.shownOnCalendar});
}

class FetchCoursesByGroupEvent extends CourseEvent {
  final int courseGroupId;

  FetchCoursesByGroupEvent({
    required super.origin,
    required this.courseGroupId,
  });
}

class FetchCourseEvent extends CourseEvent {
  final int courseGroupId;
  final int courseId;

  FetchCourseEvent({
    required super.origin,
    required this.courseGroupId,
    required this.courseId,
  });
}

class CreateCourseGroupEvent extends CourseEvent {
  final CourseGroupRequestModel request;

  CreateCourseGroupEvent({required super.origin, required this.request});
}

class UpdateCourseGroupEvent extends CourseEvent {
  final int courseGroupId;
  final CourseGroupRequestModel request;

  UpdateCourseGroupEvent({
    required super.origin,
    required this.courseGroupId,
    required this.request,
  });
}

class DeleteCourseGroupEvent extends CourseEvent {
  final int courseGroupId;

  DeleteCourseGroupEvent({required super.origin, required this.courseGroupId});
}

class CreateCourseEvent extends CourseEvent {
  final int courseGroupId;
  final CourseRequestModel request;
  final bool advanceNavOnSuccess;

  CreateCourseEvent({
    required super.origin,
    required this.courseGroupId,
    required this.request,
    this.advanceNavOnSuccess = true,
  });
}

class UpdateCourseEvent extends CourseEvent {
  final int courseGroupId;
  final int courseId;
  final CourseRequestModel request;
  final bool advanceNavOnSuccess;

  UpdateCourseEvent({
    required super.origin,
    required this.courseGroupId,
    required this.courseId,
    required this.request,
    this.advanceNavOnSuccess = false,
  });
}

class DeleteCourseEvent extends CourseEvent {
  final int courseGroupId;
  final int courseId;

  DeleteCourseEvent({
    required super.origin,
    required this.courseGroupId,
    required this.courseId,
  });
}

class FetchAllCourseSchedulesEventsEvent extends CourseEvent {
  final DateTime from;
  final DateTime to;
  final String? search;

  FetchAllCourseSchedulesEventsEvent({
    required super.origin,
    required this.from,
    required this.to,
    this.search,
  });
}

class FetchCourseScheduleEvent extends CourseEvent {
  final int courseGroupId;
  final int courseId;

  FetchCourseScheduleEvent({
    required super.origin,
    required this.courseGroupId,
    required this.courseId,
  });
}

class UpdateCourseScheduleEvent extends CourseEvent {
  final int courseGroupId;
  final int courseId;
  final int scheduleId;
  final CourseScheduleRequestModel request;
  final bool advanceNavOnSuccess;

  UpdateCourseScheduleEvent({
    required super.origin,
    required this.courseGroupId,
    required this.courseId,
    required this.scheduleId,
    required this.request,
    this.advanceNavOnSuccess = false,
  });
}

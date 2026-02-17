// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_event_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_state.dart';

abstract class CourseState extends BaseState {
  CourseState({required super.origin, super.message});
}

abstract class CourseGroupEntityState extends CourseState {
  final CourseGroupModel courseGroup;

  CourseGroupEntityState({required super.origin, required this.courseGroup});
}

abstract class CourseEntityState extends CourseState {
  final CourseModel course;
  final bool advanceNavOnSuccess;

  CourseEntityState({
    required super.origin,
    required this.course,
    required this.advanceNavOnSuccess,
  });
}

class CourseInitial extends CourseState {
  CourseInitial({required super.origin});
}

class CoursesLoading extends CourseState {
  CoursesLoading({required super.origin});
}

class CoursesError extends CourseState {
  CoursesError({required super.origin, required super.message});
}

class CoursesScreenDataFetched extends CourseState {
  final List<CourseGroupModel> courseGroups;
  final List<CourseModel> courses;

  CoursesScreenDataFetched({
    required super.origin,
    super.message,
    required this.courseGroups,
    required this.courses,
  });
}

class CourseScreenDataFetched extends CourseState {
  final CourseGroupModel courseGroup;
  final CourseModel? course;

  CourseScreenDataFetched({
    required super.origin,
    required this.courseGroup,
    this.course,
  });
}

class CoursesFetched extends CourseState {
  final List<CourseModel> courses;

  CoursesFetched({required super.origin, required this.courses});
}

class CourseFetched extends CourseEntityState {
  CourseFetched({
    required super.origin,
    required super.course,
    super.advanceNavOnSuccess = false,
  });
}

class CourseGroupCreated extends CourseGroupEntityState {
  CourseGroupCreated({required super.origin, required super.courseGroup});
}

class CourseGroupUpdated extends CourseGroupEntityState {
  CourseGroupUpdated({required super.origin, required super.courseGroup});
}

class CourseGroupDeleted extends CourseState {
  final int id;

  CourseGroupDeleted({required super.origin, required this.id});
}

class CourseCreated extends CourseEntityState {
  CourseCreated({
    required super.origin,
    required super.course,
    required super.advanceNavOnSuccess,
  });
}

class CourseUpdated extends CourseEntityState {
  CourseUpdated({
    required super.origin,
    required super.course,
    required super.advanceNavOnSuccess,
  });
}

class CourseDeleted extends CourseState {
  final int id;

  CourseDeleted({required super.origin, required this.id});
}

class CourseScheduleFetched extends CourseState {
  final CourseScheduleModel schedule;

  CourseScheduleFetched({required super.origin, required this.schedule});
}

class CourseScheduleEventsFetched extends CourseState {
  final List<CourseScheduleEventModel> events;

  CourseScheduleEventsFetched({required super.origin, required this.events});
}

class CourseScheduleUpdated extends CourseState {
  final CourseScheduleModel schedule;
  final bool advanceNavOnSuccess;

  CourseScheduleUpdated({
    required super.origin,
    required this.schedule,
    required this.advanceNavOnSuccess,
  });
}

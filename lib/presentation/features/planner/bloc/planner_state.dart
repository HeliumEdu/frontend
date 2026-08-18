// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/resource_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_state.dart';

abstract class PlannerState extends BaseState {
  PlannerState({required super.origin, super.message});
}

class PlannerInitial extends PlannerState {
  PlannerInitial({required super.origin});
}

class PlannerLoading extends PlannerState {
  PlannerLoading({required super.origin});
}

class PlannerError extends PlannerState {
  PlannerError({required super.origin, required super.message});
}

class PlannerScreenDataFetched extends PlannerState {
  final List<CourseGroupModel> courseGroups;
  final List<CourseModel> courses;
  final List<CategoryModel> categories;
  final List<ResourceModel> resources;

  PlannerScreenDataFetched({
    required super.origin,
    super.message,
    required this.courseGroups,
    required this.courses,
    required this.categories,
    required this.resources
  });
}

class CourseOccurrenceSkipped extends PlannerState {
  final CourseModel updatedCourse;

  CourseOccurrenceSkipped({required super.origin, required this.updatedCourse});
}

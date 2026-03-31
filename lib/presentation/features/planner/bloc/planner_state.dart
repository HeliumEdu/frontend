// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
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

  PlannerScreenDataFetched({
    required super.origin,
    super.message,
    required this.courseGroups,
    required this.courses,
    required this.categories,
  });
}

class CourseOccurrenceSkipped extends PlannerState {
  CourseOccurrenceSkipped({required super.origin});
}

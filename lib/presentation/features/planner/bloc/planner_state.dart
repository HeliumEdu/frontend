// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';

abstract class PlannerState {
  final String? message;

  PlannerState({this.message});
}

class PlannerInitial extends PlannerState {}

class PlannerLoading extends PlannerState {}

class PlannerError extends PlannerState {
  PlannerError({required super.message});
}

class PlannerScreenDataFetched extends PlannerState {
  final List<CourseGroupModel> courseGroups;
  final List<CourseModel> courses;
  final List<CategoryModel> categories;

  PlannerScreenDataFetched({
    super.message,
    required this.courseGroups,
    required this.courses,
    required this.categories,
  });
}

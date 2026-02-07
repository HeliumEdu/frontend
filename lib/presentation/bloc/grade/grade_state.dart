// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/grade_course_group_model.dart';

abstract class GradeState {
  final String? message;

  GradeState({this.message});
}

class GradeInitial extends GradeState {}

class GradesLoading extends GradeState {}

class GradesError extends GradeState {
  GradesError({required super.message});
}

class GradeScreenDataFetched extends GradeState {
  final List<CourseGroupModel> courseGroups;
  final List<GradeCourseGroupModel> grades;

  GradeScreenDataFetched({required this.courseGroups, required this.grades});
}

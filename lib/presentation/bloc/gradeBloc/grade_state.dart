import 'package:helium_student_flutter/data/models/planner/grade_course_group_model.dart';

abstract class GradeState {}

class GradeInitial extends GradeState {}

class GradeLoading extends GradeState {}

class GradeLoaded extends GradeState {
  final List<GradeCourseGroupModel> courseGroups;

  GradeLoaded({required this.courseGroups});
}

class GradeError extends GradeState {
  final String message;

  GradeError({required this.message});
}

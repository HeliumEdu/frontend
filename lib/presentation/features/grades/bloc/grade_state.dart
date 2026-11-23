import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/grade_course_group_model.dart';
import 'package:heliumapp/data/models/planner/needed_grade_model.dart';

abstract class GradeState {
  final String? message;

  GradeState({this.message});
}

class GradeInitial extends GradeState {}

class GradesLoading extends GradeState {}

class GradesError extends GradeState {
  final bool background;

  GradesError({required super.message, this.background = false});
}

class GradeScreenDataFetched extends GradeState {
  final List<CourseGroupModel> courseGroups;
  final List<GradeCourseGroupModel> grades;
  final double? cumulativeGpa;

  GradeScreenDataFetched({
    required this.courseGroups,
    required this.grades,
    this.cumulativeGpa,
  });
}

class NeededGradeCalculating extends GradeState {}

class NeededGradeCalculated extends GradeState {
  final int courseId;
  final int targetId;
  final double? desiredGrade;
  final double? desiredGpa;
  final NeededGradeModel result;

  NeededGradeCalculated({
    required this.courseId,
    required this.targetId,
    this.desiredGrade,
    this.desiredGpa,
    required this.result,
  });
}

class NeededGradeError extends GradeState {
  final int courseId;
  final int targetId;
  final double? desiredGrade;
  final double? desiredGpa;

  NeededGradeError({
    required this.courseId,
    required this.targetId,
    this.desiredGrade,
    this.desiredGpa,
    required super.message,
  });
}

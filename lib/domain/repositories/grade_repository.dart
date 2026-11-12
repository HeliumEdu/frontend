import 'package:heliumapp/data/models/planner/grades_model.dart';
import 'package:heliumapp/data/models/planner/needed_grade_model.dart';

abstract class GradeRepository {
  Future<GradesModel> getGrades({bool forceRefresh = false});

  Future<NeededGradeModel> getNeededGrade({
    required int courseId,
    required int targetId,
    required double desiredGrade,
  });
}

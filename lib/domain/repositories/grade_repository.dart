import 'package:heliumapp/data/models/planner/grade_course_group_model.dart';
import 'package:heliumapp/data/models/planner/needed_grade_model.dart';

abstract class GradeRepository {
  Future<List<GradeCourseGroupModel>> getGrades({bool forceRefresh = false});

  Future<NeededGradeModel> getNeededGrade({
    required int courseId,
    required int targetId,
    required double desiredGrade,
  });
}

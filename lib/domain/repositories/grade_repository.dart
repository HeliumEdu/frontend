import 'package:heliumapp/data/models/planner/grade_course_group_model.dart';

abstract class GradeRepository {
  Future<List<GradeCourseGroupModel>> getGrades({bool forceRefresh = false});
}

import 'package:heliumedu/data/models/planner/grade_course_group_model.dart';

abstract class GradeRepository {
  Future<List<GradeCourseGroupModel>> getGrades();
}

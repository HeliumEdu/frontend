import 'package:heliumapp/data/models/planner/grade_course_group_model.dart';
import 'package:heliumapp/data/models/planner/needed_grade_model.dart';
import 'package:heliumapp/data/sources/grade_remote_data_source.dart';
import 'package:heliumapp/domain/repositories/grade_repository.dart';

class GradeRepositoryImpl implements GradeRepository {
  final GradeRemoteDataSource remoteDataSource;

  GradeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<GradeCourseGroupModel>> getGrades({bool forceRefresh = false}) async {
    return remoteDataSource.getGrades(forceRefresh: forceRefresh);
  }

  @override
  Future<NeededGradeModel> getNeededGrade({
    required int courseId,
    required int targetId,
    required double desiredGrade,
  }) async {
    return remoteDataSource.getNeededGrade(
      courseId: courseId,
      targetId: targetId,
      desiredGrade: desiredGrade,
    );
  }
}

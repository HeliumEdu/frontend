import 'package:helium_student_flutter/data/datasources/grade_remote_data_source.dart';
import 'package:helium_student_flutter/data/models/planner/grade_course_group_model.dart';
import 'package:helium_student_flutter/domain/repositories/grade_repository.dart';

class GradeRepositoryImpl implements GradeRepository {
  final GradeRemoteDataSource remoteDataSource;

  GradeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<GradeCourseGroupModel>> getGrades() async {
    return await remoteDataSource.getGrades();
  }
}

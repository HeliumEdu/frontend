// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:helium_mobile/data/datasources/grade_remote_data_source.dart';
import 'package:helium_mobile/data/models/planner/grade_course_group_model.dart';
import 'package:helium_mobile/domain/repositories/grade_repository.dart';

class GradeRepositoryImpl implements GradeRepository {
  final GradeRemoteDataSource remoteDataSource;

  GradeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<GradeCourseGroupModel>> getGrades() async {
    return await remoteDataSource.getGrades();
  }
}

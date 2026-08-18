// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:heliumapp/data/models/planner/grade_course_group_model.dart';
import 'package:heliumapp/data/sources/grade_remote_data_source.dart';
import 'package:heliumapp/domain/repositories/grade_repository.dart';

class GradeRepositoryImpl implements GradeRepository {
  final GradeRemoteDataSource remoteDataSource;

  GradeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<GradeCourseGroupModel>> getGrades({bool forceRefresh = false}) async {
    return remoteDataSource.getGrades(forceRefresh: forceRefresh);
  }
}

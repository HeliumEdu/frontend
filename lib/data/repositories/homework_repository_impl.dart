// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumedu/data/datasources/homework_remote_data_source.dart';
import 'package:heliumedu/data/models/planner/homework_request_model.dart';
import 'package:heliumedu/data/models/planner/homework_response_model.dart';
import 'package:heliumedu/domain/repositories/homework_repository.dart';

class HomeworkRepositoryImpl implements HomeworkRepository {
  final HomeworkRemoteDataSource remoteDataSource;

  HomeworkRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<HomeworkResponseModel>> getAllHomework({
    List<String>? categoryTitles,
  }) async {
    return await remoteDataSource.getAllHomework(
      categoryTitles: categoryTitles,
    );
  }

  @override
  Future<HomeworkResponseModel> createHomework({
    required int groupId,
    required int courseId,
    required HomeworkRequestModel request,
  }) async {
    return await remoteDataSource.createHomework(
      groupId: groupId,
      courseId: courseId,
      request: request,
    );
  }

  @override
  Future<List<HomeworkResponseModel>> getHomework({
    required int groupId,
    required int courseId,
  }) async {
    return await remoteDataSource.getHomework(
      groupId: groupId,
      courseId: courseId,
    );
  }

  @override
  Future<HomeworkResponseModel> getHomeworkById({
    required int groupId,
    required int courseId,
    required int homeworkId,
  }) async {
    return await remoteDataSource.getHomeworkById(
      groupId: groupId,
      courseId: courseId,
      homeworkId: homeworkId,
    );
  }

  @override
  Future<HomeworkResponseModel> updateHomework({
    required int groupId,
    required int courseId,
    required int homeworkId,
    required HomeworkRequestModel request,
  }) async {
    return await remoteDataSource.updateHomework(
      groupId: groupId,
      courseId: courseId,
      homeworkId: homeworkId,
      request: request,
    );
  }

  @override
  Future<void> deleteHomework({
    required int groupId,
    required int courseId,
    required int homeworkId,
  }) async {
    return await remoteDataSource.deleteHomework(
      groupId: groupId,
      courseId: courseId,
      homeworkId: homeworkId,
    );
  }
}

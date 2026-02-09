// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/request/homework_request_model.dart';
import 'package:heliumapp/data/sources/homework_remote_data_source.dart';
import 'package:heliumapp/domain/repositories/homework_repository.dart';

class HomeworkRepositoryImpl implements HomeworkRepository {
  final HomeworkRemoteDataSource remoteDataSource;

  HomeworkRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<HomeworkModel>> getHomeworks({
    required DateTime from,
    required DateTime to,
    List<String>? categoryTitles,
    String? search,
    String? title,
    bool? shownOnCalendar,
  }) async {
    return await remoteDataSource.getHomeworks(
      categoryTitles: categoryTitles,
      from: from,
      to: to,
      search: search,
      title: title,
      shownOnCalendar: shownOnCalendar,
    );
  }

  @override
  Future<HomeworkModel> getHomework({required int id}) async {
    return await remoteDataSource.getHomework(id: id);
  }

  @override
  Future<HomeworkModel> createHomework({
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
  Future<HomeworkModel> updateHomework({
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

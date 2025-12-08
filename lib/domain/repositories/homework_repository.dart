// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/homework_request_model.dart';
import 'package:heliumapp/data/models/planner/homework_response_model.dart';

abstract class HomeworkRepository {
  Future<List<HomeworkResponseModel>> getAllHomework({
    List<String>? categoryTitles,
    String? from,
    String? to,
    String? ordering,
    String? search,
    String? title,
  });

  Future<HomeworkResponseModel> createHomework({
    required int groupId,
    required int courseId,
    required HomeworkRequestModel request,
  });

  Future<List<HomeworkResponseModel>> getHomework({
    required int groupId,
    required int courseId,
  });

  Future<HomeworkResponseModel> getHomeworkById({
    required int groupId,
    required int courseId,
    required int homeworkId,
  });

  Future<HomeworkResponseModel> updateHomework({
    required int groupId,
    required int courseId,
    required int homeworkId,
    required HomeworkRequestModel request,
  });

  Future<void> deleteHomework({
    required int groupId,
    required int courseId,
    required int homeworkId,
  });
}

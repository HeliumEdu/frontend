// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/request/homework_request_model.dart';

abstract class HomeworkRepository {
  Future<List<HomeworkModel>> getHomeworks({
    required DateTime from,
    required DateTime to,
    List<String>? categoryTitles,
    String? search,
    String? title,
    bool? shownOnCalendar,
  });

  Future<HomeworkModel> getHomework({required int id});

  Future<HomeworkModel> createHomework({
    required int groupId,
    required int courseId,
    required HomeworkRequestModel request,
  });

  Future<HomeworkModel> updateHomework({
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

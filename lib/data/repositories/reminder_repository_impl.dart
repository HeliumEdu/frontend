// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/data/models/planner/reminder_request_model.dart';
import 'package:heliumapp/data/sources/reminder_remote_data_source.dart';
import 'package:heliumapp/domain/repositories/reminder_repository.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  final ReminderRemoteDataSource remoteDataSource;

  ReminderRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ReminderModel>> getReminders({
    int? homeworkId,
    int? eventId,
    bool? sent,
    bool? dismissed,
    int? type,
  }) async {
    return await remoteDataSource.getReminders(
      homeworkId: homeworkId,
      eventId: eventId,
      sent: sent,
      dismissed: dismissed,
      type: type,
    );
  }

  @override
  Future<ReminderModel> createReminder(ReminderRequestModel request) async {
    return await remoteDataSource.createReminder(request);
  }

  @override
  Future<ReminderModel> updateReminder(
    int id,
    ReminderRequestModel request,
  ) async {
    return await remoteDataSource.updateReminder(id, request);
  }

  @override
  Future<void> deleteReminder(int id) async {
    return await remoteDataSource.deleteReminder(id);
  }
}

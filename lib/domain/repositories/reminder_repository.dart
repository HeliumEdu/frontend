// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/data/models/planner/request/reminder_request_model.dart';

abstract class ReminderRepository {
  Future<List<ReminderModel>> getReminders({
    int? homeworkId,
    int? eventId,
    int? courseId,
    bool? sent,
    bool? dismissed,
    int? type,
    DateTime? startOfRange,
    bool forceRefresh = false,
  });

  Future<int> getRemindersCount({
    bool? sent,
    bool? dismissed,
    int? type,
    DateTime? startOfRange,
  });

  Future<ReminderModel> createReminder(ReminderRequestModel request);

  Future<ReminderModel> updateReminder(int id, ReminderRequestModel request);

  Future<void> deleteReminder(int id);

  Future<void> dismissAllReminders({
    bool? sent,
    int? type,
    DateTime? startOfRange,
  });
}

// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/data/models/planner/reminder_request_model.dart';

abstract class ReminderRepository {
  Future<List<ReminderModel>> getReminders({
    int? homeworkId,
    int? eventId,
    bool? sent,
    bool? dismissed,
    int? type,
  });

  Future<ReminderModel> createReminder(ReminderRequestModel request);

  Future<ReminderModel> updateReminder(int id, ReminderRequestModel request);

  Future<void> deleteReminder(int id);
}

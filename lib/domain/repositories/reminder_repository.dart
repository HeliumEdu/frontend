// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumedu/data/models/planner/reminder_request_model.dart';
import 'package:heliumedu/data/models/planner/reminder_response_model.dart';

abstract class ReminderRepository {
  Future<ReminderResponseModel> createReminder(ReminderRequestModel request);

  Future<List<ReminderResponseModel>> getReminders();

  Future<ReminderResponseModel> getReminderById(int reminderId);

  Future<ReminderResponseModel> updateReminder(
    int reminderId,
    ReminderRequestModel request,
  );

  Future<void> deleteReminder(int reminderId);
}

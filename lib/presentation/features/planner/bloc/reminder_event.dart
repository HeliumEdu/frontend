// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/request/reminder_request_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';

abstract class ReminderEvent extends BaseEvent {
  ReminderEvent({required super.origin});
}

class FetchRemindersEvent extends ReminderEvent {
  bool? sent;
  bool? dismissed;
  int? type;
  int? eventId;
  int? homeworkId;
  DateTime? startOfRange;

  FetchRemindersEvent({
    required super.origin,
    this.sent,
    this.dismissed,
    this.type,
    this.eventId,
    this.homeworkId,
    this.startOfRange,
  });
}

class CreateReminderEvent extends ReminderEvent {
  final ReminderRequestModel request;

  CreateReminderEvent({required super.origin, required this.request});
}

class UpdateReminderEvent extends ReminderEvent {
  final int id;
  final ReminderRequestModel request;

  UpdateReminderEvent({
    required super.origin,
    required this.id,
    required this.request,
  });
}

class DeleteReminderEvent extends ReminderEvent {
  final int id;

  DeleteReminderEvent({required super.origin, required this.id});
}

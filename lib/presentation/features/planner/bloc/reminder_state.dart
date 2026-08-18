// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_state.dart';

abstract class ReminderState extends BaseState {
  ReminderState({required super.origin, super.message});
}

class ReminderInitial extends ReminderState {
  ReminderInitial({required super.origin});
}

class RemindersLoading extends ReminderState {
  RemindersLoading({required super.origin});
}

class RemindersError extends ReminderState {
  RemindersError({required super.origin, required super.message});
}

class ReminderCreated extends ReminderState {
  final ReminderModel reminder;

  ReminderCreated({required super.origin, required this.reminder});
}

class RemindersFetched extends ReminderState {
  final List<ReminderModel> reminders;

  RemindersFetched({required super.origin, required this.reminders});
}

class ReminderUpdated extends ReminderState {
  final ReminderModel reminder;

  ReminderUpdated({required super.origin, required this.reminder});
}

class ReminderDeleted extends ReminderState {
  final int id;

  ReminderDeleted({required super.origin, required this.id});
}

class AllRemindersDismissed extends ReminderState {
  AllRemindersDismissed({required super.origin});
}

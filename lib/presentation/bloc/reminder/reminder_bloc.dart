// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:bloc/bloc.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/domain/repositories/reminder_repository.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/bloc/reminder/reminder_event.dart';
import 'package:heliumapp/presentation/bloc/reminder/reminder_state.dart';

class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  final ReminderRepository reminderRepository;

  ReminderBloc({required this.reminderRepository})
    : super(ReminderInitial(origin: EventOrigin.bloc)) {
    on<FetchRemindersEvent>(_onFetchReminders);
    on<CreateReminderEvent>(_onCreateReminders);
    on<UpdateReminderEvent>(_onUpdateReminders);
    on<DeleteReminderEvent>(_onDeleteReminders);
  }

  Future<void> _onFetchReminders(
    FetchRemindersEvent event,
    Emitter<ReminderState> emit,
  ) async {
    emit(RemindersLoading(origin: event.origin));
    try {
      final reminders = await reminderRepository.getReminders(
        sent: event.sent,
        dismissed: event.dismissed,
        type: event.type,
        eventId: event.eventId,
        homeworkId: event.homeworkId,
      );
      emit(RemindersFetched(origin: event.origin, reminders: reminders));
    } on HeliumException catch (e) {
      emit(RemindersError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        RemindersError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onCreateReminders(
    CreateReminderEvent event,
    Emitter<ReminderState> emit,
  ) async {
    emit(RemindersLoading(origin: event.origin));

    try {
      final reminder = await reminderRepository.createReminder(event.request);
      emit(ReminderCreated(origin: event.origin, reminder: reminder));
    } on HeliumException catch (e) {
      emit(RemindersError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        RemindersError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateReminders(
    UpdateReminderEvent event,
    Emitter<ReminderState> emit,
  ) async {
    emit(RemindersLoading(origin: event.origin));

    try {
      final reminder = await reminderRepository.updateReminder(
        event.id,
        event.request,
      );
      emit(ReminderUpdated(origin: event.origin, reminder: reminder));
    } on HeliumException catch (e) {
      emit(RemindersError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        RemindersError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteReminders(
    DeleteReminderEvent event,
    Emitter<ReminderState> emit,
  ) async {
    emit(RemindersLoading(origin: event.origin));

    try {
      await reminderRepository.deleteReminder(event.id);
      emit(ReminderDeleted(origin: event.origin, id: event.id));
    } on HeliumException catch (e) {
      emit(RemindersError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        RemindersError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }
}

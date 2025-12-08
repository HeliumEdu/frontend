// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helium_mobile/core/helium_exception.dart';
import 'package:helium_mobile/domain/repositories/external_calendar_repository.dart';
import 'package:helium_mobile/presentation/bloc/settings/external_calendar_event.dart';
import 'package:helium_mobile/presentation/bloc/settings/external_calendar_state.dart';
import 'package:logging/logging.dart';

final log = Logger('HeliumLogger');

class ExternalCalendarBloc
    extends Bloc<ExternalCalendarEvent, ExternalCalendarState> {
  final ExternalCalendarRepository externalCalendarRepository;

  ExternalCalendarBloc({required this.externalCalendarRepository})
    : super(ExternalCalendarInitial()) {
    on<FetchAllExternalCalendarsEvent>(_onFetchAllExternalCalendars);
    on<FetchExternalCalendarEventsEvent>(_onFetchExternalCalendarEvents);
    on<CreateExternalCalendarEvent>(_onCreateExternalCalendar);
    on<UpdateExternalCalendarEvent>(_onUpdateExternalCalendar);
    on<DeleteExternalCalendarEvent>(_onDeleteExternalCalendar);
  }

  Future<void> _onFetchAllExternalCalendars(
    FetchAllExternalCalendarsEvent event,
    Emitter<ExternalCalendarState> emit,
  ) async {
    emit(ExternalCalendarsLoading());
    try {
      log.info('🎯 Fetching all external calendars from repository...');
      final calendars = await externalCalendarRepository
          .getAllExternalCalendars();
      log.info(
        '✅ External calendars fetched successfully: ${calendars.length} calendar(s)',
      );
      emit(ExternalCalendarsLoaded(calendars: calendars));
    } on HeliumException catch (e) {
      log.info('❌ App error: ${e.message}');
      emit(ExternalCalendarsError(message: e.message));
    } catch (e) {
      log.info('❌ Unexpected error: $e');
      emit(ExternalCalendarsError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onFetchExternalCalendarEvents(
    FetchExternalCalendarEventsEvent event,
    Emitter<ExternalCalendarState> emit,
  ) async {
    emit(ExternalCalendarEventsLoading());
    try {
      log.info('🎯 Fetching all events for external calendars ...');
      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 365));
      final to = now.add(const Duration(days: 730));
      final events = await externalCalendarRepository.getExternalCalendarEvents(
        from: from,
        to: to,
        search: null,
      );
      log.info(
        '✅ External calendar events fetched successfully: ${events.length} event(s)',
      );
      emit(ExternalCalendarEventsLoaded(events: events));
    } on HeliumException catch (e) {
      log.info('❌ App error: ${e.message}');
      emit(ExternalCalendarEventsError(message: e.message));
    } catch (e) {
      log.info('❌ Unexpected error: $e');
      emit(
        ExternalCalendarEventsError(
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onCreateExternalCalendar(
    CreateExternalCalendarEvent event,
    Emitter<ExternalCalendarState> emit,
  ) async {
    emit(ExternalCalendarActionInProgress());
    try {
      final created = await externalCalendarRepository.addExternalCalendar(
        payload: event.payload,
      );

      final calendars = await externalCalendarRepository
          .getAllExternalCalendars();

      emit(
        ExternalCalendarActionSuccess(
          message: 'External calendar added successfully.',
          calendars: calendars,
        ),
      );

      emit(ExternalCalendarsLoaded(calendars: calendars));
      log.info('✅ External calendar created: ${created.title}');
      add(FetchExternalCalendarEventsEvent());
    } on HeliumException catch (e) {
      log.info('❌ App error while creating external calendar: ${e.message}');
      emit(ExternalCalendarActionError(message: e.message));
    } catch (e) {
      log.info('❌ Unexpected error while creating external calendar: $e');
      emit(
        ExternalCalendarActionError(
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateExternalCalendar(
    UpdateExternalCalendarEvent event,
    Emitter<ExternalCalendarState> emit,
  ) async {
    emit(ExternalCalendarActionInProgress());
    try {
      final updated = await externalCalendarRepository.updateExternalCalendar(
        calendarId: event.calendarId,
        payload: event.payload,
      );

      final calendars = await externalCalendarRepository
          .getAllExternalCalendars();

      emit(
        ExternalCalendarActionSuccess(
          message: 'External calendar updated successfully.',
          calendars: calendars,
        ),
      );

      emit(ExternalCalendarsLoaded(calendars: calendars));
      log.info('✅ External calendar updated: ${updated.title}');
      add(FetchExternalCalendarEventsEvent());
    } on HeliumException catch (e) {
      log.info('❌ App error while updating external calendar: ${e.message}');
      emit(ExternalCalendarActionError(message: e.message));
    } catch (e) {
      log.info('❌ Unexpected error while updating external calendar: $e');
      emit(
        ExternalCalendarActionError(
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteExternalCalendar(
    DeleteExternalCalendarEvent event,
    Emitter<ExternalCalendarState> emit,
  ) async {
    emit(ExternalCalendarActionInProgress());
    try {
      await externalCalendarRepository.deleteExternalCalendar(
        calendarId: event.calendarId,
      );

      final calendars = await externalCalendarRepository
          .getAllExternalCalendars();

      emit(
        ExternalCalendarActionSuccess(
          message: 'External calendar deleted successfully.',
          calendars: calendars,
        ),
      );

      emit(ExternalCalendarsLoaded(calendars: calendars));
      log.info('✅ External calendar deleted: ${event.calendarId}');
      add(FetchExternalCalendarEventsEvent());
    } on HeliumException catch (e) {
      log.info('❌ App error while deleting external calendar: ${e.message}');
      emit(ExternalCalendarActionError(message: e.message));
    } catch (e) {
      log.info('❌ Unexpected error while deleting external calendar: $e');
      emit(
        ExternalCalendarActionError(
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }
}

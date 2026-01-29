// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/domain/repositories/external_calendar_repository.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/bloc/externalcalendar/external_calendar_event.dart';
import 'package:heliumapp/presentation/bloc/externalcalendar/external_calendar_state.dart';

class ExternalCalendarBloc
    extends Bloc<ExternalCalendarEvent, ExternalCalendarState> {
  final ExternalCalendarRepository externalCalendarRepository;

  ExternalCalendarBloc({required this.externalCalendarRepository})
    : super(ExternalCalendarInitial(origin: EventOrigin.bloc)) {
    on<FetchExternalCalendarsEvent>(_onFetchExternalCalendars);
    on<FetchExternalCalendarEventsEvent>(_onFetchExternalCalendarEvents);
    on<CreateExternalCalendarEvent>(_onCreateExternalCalendar);
    on<UpdateExternalCalendarEvent>(_onUpdateExternalCalendar);
    on<DeleteExternalCalendarEvent>(_onDeleteExternalCalendar);
  }

  Future<void> _onFetchExternalCalendars(
    FetchExternalCalendarsEvent event,
    Emitter<ExternalCalendarState> emit,
  ) async {
    emit(ExternalCalendarsLoading(origin: event.origin));
    try {
      final calendars = await externalCalendarRepository.getExternalCalendars();
      emit(
        ExternalCalendarsFetched(
          origin: event.origin,
          externalCalendars: calendars,
        ),
      );
    } on HeliumException catch (e) {
      emit(ExternalCalendarsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        ExternalCalendarsError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onFetchExternalCalendarEvents(
    FetchExternalCalendarEventsEvent event,
    Emitter<ExternalCalendarState> emit,
  ) async {
    emit(ExternalCalendarsLoading(origin: event.origin));
    try {
      final events = await externalCalendarRepository.getExternalCalendarEvents(
        from: event.from,
        to: event.to,
        search: event.search,
      );
      emit(ExternalCalendarEventsFetched(origin: event.origin, events: events));
    } on HeliumException catch (e) {
      emit(ExternalCalendarsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        ExternalCalendarsError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onCreateExternalCalendar(
    CreateExternalCalendarEvent event,
    Emitter<ExternalCalendarState> emit,
  ) async {
    emit(ExternalCalendarsLoading(origin: event.origin));
    try {
      final externalCalendar = await externalCalendarRepository
          .createExternalCalendar(payload: event.request);

      emit(
        ExternalCalendarCreated(
          origin: event.origin,
          externalCalendar: externalCalendar,
        ),
      );
    } on HeliumException catch (e) {
      emit(ExternalCalendarsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        ExternalCalendarsError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateExternalCalendar(
    UpdateExternalCalendarEvent event,
    Emitter<ExternalCalendarState> emit,
  ) async {
    emit(ExternalCalendarsLoading(origin: event.origin));
    try {
      final externalCalendar = await externalCalendarRepository
          .updateExternalCalendar(calendarId: event.id, payload: event.request);

      emit(
        ExternalCalendarUpdated(
          origin: event.origin,
          externalCalendar: externalCalendar,
        ),
      );
    } on HeliumException catch (e) {
      emit(ExternalCalendarsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        ExternalCalendarsError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteExternalCalendar(
    DeleteExternalCalendarEvent event,
    Emitter<ExternalCalendarState> emit,
  ) async {
    emit(ExternalCalendarsLoading(origin: event.origin));
    try {
      await externalCalendarRepository.deleteExternalCalendar(
        calendarId: event.id,
      );

      emit(ExternalCalendarDeleted(origin: event.origin, id: event.id));
    } on HeliumException catch (e) {
      emit(ExternalCalendarsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        ExternalCalendarsError(
          origin: event.origin,
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helium_student_flutter/core/app_exception.dart';
import 'package:helium_student_flutter/data/models/planner/external_calendar_event_model.dart';
import 'package:helium_student_flutter/data/models/planner/external_calendar_request_model.dart';
import 'package:helium_student_flutter/domain/repositories/external_calendar_repository.dart';
import 'package:helium_student_flutter/presentation/bloc/externalCalendarBloc/external_calendar_event.dart';
import 'package:helium_student_flutter/presentation/bloc/externalCalendarBloc/external_calendar_state.dart';

class ExternalCalendarBloc
    extends Bloc<ExternalCalendarEvent, ExternalCalendarState> {
  final ExternalCalendarRepository externalCalendarRepository;

  ExternalCalendarBloc({required this.externalCalendarRepository})
    : super(ExternalCalendarInitial()) {
    on<FetchAllExternalCalendarsEvent>(_onFetchAllExternalCalendars);
    on<FetchExternalCalendarEventsEvent>(_onFetchExternalCalendarEvents);
    on<FetchAllExternalCalendarEventsEvent>(_onFetchAllExternalCalendarEvents);
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
      print('🎯 Fetching all external calendars from repository...');
      final calendars = await externalCalendarRepository
          .getAllExternalCalendars();
      print(
        '✅ External calendars fetched successfully: ${calendars.length} calendar(s)',
      );
      emit(ExternalCalendarsLoaded(calendars: calendars));
    } on AppException catch (e) {
      print('❌ App error: ${e.message}');
      emit(ExternalCalendarsError(message: e.message));
    } catch (e) {
      print('❌ Unexpected error: $e');
      emit(ExternalCalendarsError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onFetchExternalCalendarEvents(
    FetchExternalCalendarEventsEvent event,
    Emitter<ExternalCalendarState> emit,
  ) async {
    emit(ExternalCalendarEventsLoading());
    try {
      print('🎯 Fetching events for external calendar ${event.calendarId}...');
      final now = DateTime.now().toUtc();
      final startRange = now.subtract(const Duration(days: 365));
      final endRange = now.add(const Duration(days: 730));
      final events = await externalCalendarRepository.getExternalCalendarEvents(
        calendarId: event.calendarId,
        start: startRange,
        end: endRange,
      );
      print(
        '✅ External calendar events fetched successfully: ${events.length} event(s)',
      );
      emit(ExternalCalendarEventsLoaded(events: events));
    } on AppException catch (e) {
      print('❌ App error: ${e.message}');
      emit(ExternalCalendarEventsError(message: e.message));
    } catch (e) {
      print('❌ Unexpected error: $e');
      emit(
        ExternalCalendarEventsError(
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  Future<void> _onFetchAllExternalCalendarEvents(
    FetchAllExternalCalendarEventsEvent event,
    Emitter<ExternalCalendarState> emit,
  ) async {
    emit(AllExternalCalendarEventsLoading());
    try {
      print('🎯 Fetching all external calendar events...');

      // First, fetch all external calendars
      final calendars =
          await externalCalendarRepository.getAllExternalCalendars();
      print('📅 Found ${calendars.length} external calendars');

      final Map<int, List<ExternalCalendarEventModel>> eventsByCalendar = {
        for (final calendar in calendars) calendar.id: <ExternalCalendarEventModel>[],
      };

      final now = DateTime.now().toUtc();
      final startRange = now.subtract(const Duration(days: 365));
      final endRange = now.add(const Duration(days: 730));
      print(
        '🗓️ Fetching events between ${startRange.toIso8601String()} and ${endRange.toIso8601String()}',
      );

      // Fetch events from all enabled calendars
      List<ExternalCalendarEventModel> allEvents = [];
      for (var calendar in calendars) {
        try {
          final events = await externalCalendarRepository
              .getExternalCalendarEvents(
            calendarId: calendar.id,
            start: startRange,
            end: endRange,
          );
          allEvents.addAll(events);
          eventsByCalendar[calendar.id] = events;
          print(
            '✅ Fetched ${events.length} events from calendar "${calendar.title}"',
          );
        } catch (e) {
          print(
            '⚠️ Failed to fetch events from calendar "${calendar.title}": $e',
          );
          // Continue with other calendars even if one fails
        }
      }

      print(
        '✅ Total external calendar events fetched: ${allEvents.length} event(s)',
      );
      allEvents.sort((a, b) {
        DateTime? parseSafe(String value) {
          try {
            return DateTime.parse(value);
          } catch (_) {
            return null;
          }
        }

        final aStart = parseSafe(a.start);
        final bStart = parseSafe(b.start);
        if (aStart == null && bStart == null) return 0;
        if (aStart == null) return 1;
        if (bStart == null) return -1;
        return aStart.compareTo(bStart);
      });

      emit(
        AllExternalCalendarEventsLoaded(
          events: allEvents,
          calendars: calendars,
          eventsByCalendar: eventsByCalendar,
        ),
      );
    } on AppException catch (e) {
      print('❌ App error: ${e.message}');
      emit(AllExternalCalendarEventsError(message: e.message));
    } catch (e) {
      print('❌ Unexpected error: $e');
      emit(
        AllExternalCalendarEventsError(
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

      final calendars =
          await externalCalendarRepository.getAllExternalCalendars();

      emit(
        ExternalCalendarActionSuccess(
          message: 'External calendar added successfully.',
          calendars: calendars,
        ),
      );

      emit(ExternalCalendarsLoaded(calendars: calendars));
      print('✅ External calendar created: ${created.title}');
      add(FetchAllExternalCalendarEventsEvent());
    } on AppException catch (e) {
      print('❌ App error while creating external calendar: ${e.message}');
      emit(ExternalCalendarActionError(message: e.message));
    } catch (e) {
      print('❌ Unexpected error while creating external calendar: $e');
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

      final calendars =
          await externalCalendarRepository.getAllExternalCalendars();

      emit(
        ExternalCalendarActionSuccess(
          message: 'External calendar updated successfully.',
          calendars: calendars,
        ),
      );

      emit(ExternalCalendarsLoaded(calendars: calendars));
      print('✅ External calendar updated: ${updated.title}');
      add(FetchAllExternalCalendarEventsEvent());
    } on AppException catch (e) {
      print('❌ App error while updating external calendar: ${e.message}');
      emit(ExternalCalendarActionError(message: e.message));
    } catch (e) {
      print('❌ Unexpected error while updating external calendar: $e');
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

      final calendars =
          await externalCalendarRepository.getAllExternalCalendars();

      emit(
        ExternalCalendarActionSuccess(
          message: 'External calendar deleted successfully.',
          calendars: calendars,
        ),
      );

      emit(ExternalCalendarsLoaded(calendars: calendars));
      print('✅ External calendar deleted: ${event.calendarId}');
      add(FetchAllExternalCalendarEventsEvent());
    } on AppException catch (e) {
      print('❌ App error while deleting external calendar: ${e.message}');
      emit(ExternalCalendarActionError(message: e.message));
    } catch (e) {
      print('❌ Unexpected error while deleting external calendar: $e');
      emit(
        ExternalCalendarActionError(
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }
}

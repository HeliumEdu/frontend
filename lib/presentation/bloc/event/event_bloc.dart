// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helium_mobile/core/helium_exception.dart';
import 'package:helium_mobile/domain/repositories/event_repository.dart';
import 'package:helium_mobile/presentation/bloc/event/event_event.dart';
import 'package:helium_mobile/presentation/bloc/event/event_state.dart';
import 'package:logging/logging.dart';

final log = Logger('HeliumLogger');

class EventBloc extends Bloc<EventEvent, EventState> {
  final EventRepository eventRepository;

  EventBloc({required this.eventRepository}) : super(EventInitial()) {
    on<FetchAllEventsEvent>(_onFetchAllEvents);
    on<CreateEventEvent>(_onCreateEvent);
    on<FetchEventByIdEvent>(_onFetchEventById);
    on<UpdateEventEvent>(_onUpdateEvent);
    on<DeleteEventEvent>(_onDeleteEvent);
  }

  Future<void> _onFetchAllEvents(
    FetchAllEventsEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(EventLoading());
    try {
      log.info('🎯 Fetching all events from repository...');
      final events = await eventRepository.getAllEvents(
        from: event.from,
        to: event.to,
        ordering: event.ordering,
        search: event.search,
        title: event.title,
      );
      log.info('✅ Events fetched successfully: ${events.length} event(s)');
      emit(EventLoaded(events: events));
    } on HeliumException catch (e) {
      log.info('❌ App error: ${e.message}');
      emit(EventError(message: e.message));
    } catch (e) {
      log.info('❌ Unexpected error: $e');
      emit(EventError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onCreateEvent(
    CreateEventEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(EventCreating());
    try {
      log.info('🎯 Creating event...');
      final createdEvent = await eventRepository.createEvent(
        request: event.request,
      );
      log.info('✅ Event created successfully');
      emit(EventCreated(event: createdEvent));

      // Refresh events list after creation
      add(FetchAllEventsEvent());
    } on HeliumException catch (e) {
      log.info('❌ App error: ${e.message}');
      emit(EventCreateError(message: e.message));
    } catch (e) {
      log.info('❌ Unexpected error: $e');
      emit(EventCreateError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onFetchEventById(
    FetchEventByIdEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(EventByIdLoading());
    try {
      log.info('🎯 Fetching event by ID: ${event.eventId}');
      final fetchedEvent = await eventRepository.getEventById(
        eventId: event.eventId,
      );
      log.info('✅ Event fetched successfully');
      emit(EventByIdLoaded(event: fetchedEvent));
    } on HeliumException catch (e) {
      log.info('❌ App error: ${e.message}');
      emit(EventByIdError(message: e.message));
    } catch (e) {
      log.info('❌ Unexpected error: $e');
      emit(EventByIdError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onUpdateEvent(
    UpdateEventEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(EventUpdating());
    try {
      log.info('🎯 Updating event: ${event.eventId}');
      final updatedEvent = await eventRepository.updateEvent(
        eventId: event.eventId,
        request: event.request,
      );
      log.info('✅ Event updated successfully');
      emit(EventUpdated(event: updatedEvent));

      // Refresh events list after update
      add(FetchAllEventsEvent());
    } on HeliumException catch (e) {
      log.info('❌ App error: ${e.message}');
      emit(EventUpdateError(message: e.message));
    } catch (e) {
      log.info('❌ Unexpected error: $e');
      emit(EventUpdateError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onDeleteEvent(
    DeleteEventEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(EventDeleting());
    try {
      log.info('🎯 Deleting event: ${event.eventId}');
      await eventRepository.deleteEvent(eventId: event.eventId);
      log.info('✅ Event deleted successfully');
      emit(EventDeleted());

      // Refresh events list after deletion
      add(FetchAllEventsEvent());
    } on HeliumException catch (e) {
      log.info('❌ App error: ${e.message}');
      emit(EventDeleteError(message: e.message));
    } catch (e) {
      log.info('❌ Unexpected error: $e');
      emit(EventDeleteError(message: 'An unexpected error occurred: $e'));
    }
  }
}

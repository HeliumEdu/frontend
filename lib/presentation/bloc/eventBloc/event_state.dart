import 'package:helium_student_flutter/data/models/planner/event_response_model.dart';

abstract class EventState {}

class EventInitial extends EventState {}

// Create Event States
class EventCreating extends EventState {}

class EventCreated extends EventState {
  final EventResponseModel event;
  EventCreated({required this.event});
}

class EventCreateError extends EventState {
  final String message;
  EventCreateError({required this.message});
}

// Fetch Events States
class EventLoading extends EventState {}

class EventLoaded extends EventState {
  final List<EventResponseModel> events;
  EventLoaded({required this.events});
}

class EventError extends EventState {
  final String message;
  EventError({required this.message});
}

// Fetch Single Event States
class EventByIdLoading extends EventState {}

class EventByIdLoaded extends EventState {
  final EventResponseModel event;
  EventByIdLoaded({required this.event});
}

class EventByIdError extends EventState {
  final String message;
  EventByIdError({required this.message});
}

// Update Event States
class EventUpdating extends EventState {}

class EventUpdated extends EventState {
  final EventResponseModel event;
  EventUpdated({required this.event});
}

class EventUpdateError extends EventState {
  final String message;
  EventUpdateError({required this.message});
}

// Delete Event States
class EventDeleting extends EventState {}

class EventDeleted extends EventState {}

class EventDeleteError extends EventState {
  final String message;
  EventDeleteError({required this.message});
}

import 'package:heliumapp/data/models/planner/request/external_calendar_request_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';

abstract class ExternalCalendarEvent extends BaseEvent {
  ExternalCalendarEvent({required super.origin});
}

/// Clears all external calendar state. Dispatched on logout so per-user data
/// does not carry into the next session.
class ResetExternalCalendarsEvent extends ExternalCalendarEvent {
  ResetExternalCalendarsEvent() : super(origin: EventOrigin.bloc);
}

class FetchExternalCalendarsEvent extends ExternalCalendarEvent {
  final bool forceRefresh;
  final bool passive;

  FetchExternalCalendarsEvent({
    required super.origin,
    this.forceRefresh = false,
    this.passive = false,
  });
}

class CreateExternalCalendarEvent extends ExternalCalendarEvent {
  final ExternalCalendarRequestModel request;

  CreateExternalCalendarEvent({required super.origin, required this.request});
}

class UpdateExternalCalendarEvent extends ExternalCalendarEvent {
  final int id;
  final ExternalCalendarRequestModel request;
  /// The item's version as last read; when set, a stale save emits a
  /// conflict state instead of overwriting.
  final String? version;

  UpdateExternalCalendarEvent({
    required super.origin,
    required this.id,
    required this.request,
    this.version,
  });
}

class DeleteExternalCalendarEvent extends ExternalCalendarEvent {
  final int id;

  DeleteExternalCalendarEvent({required super.origin, required this.id});
}

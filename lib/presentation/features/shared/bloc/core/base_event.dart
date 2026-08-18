enum EventOrigin { screen, subScreen, dialog, bloc }

abstract class BaseEvent {
  final EventOrigin origin;

  BaseEvent({required this.origin});
}

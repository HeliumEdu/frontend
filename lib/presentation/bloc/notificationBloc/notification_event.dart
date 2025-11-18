import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class InitializeNotificationEvent extends NotificationEvent {
  const InitializeNotificationEvent();
}

class GetFCMTokenEvent extends NotificationEvent {
  const GetFCMTokenEvent();
}

class SubscribeToTopicEvent extends NotificationEvent {
  final String topic;

  const SubscribeToTopicEvent({required this.topic});

  @override
  List<Object?> get props => [topic];
}

class UnsubscribeFromTopicEvent extends NotificationEvent {
  final String topic;

  const UnsubscribeFromTopicEvent({required this.topic});

  @override
  List<Object?> get props => [topic];
}

class ClearAllNotificationsEvent extends NotificationEvent {
  const ClearAllNotificationsEvent();
}

class ClearNotificationEvent extends NotificationEvent {
  final int notificationId;

  const ClearNotificationEvent({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

class TestNotificationEvent extends NotificationEvent {
  const TestNotificationEvent();
}

class NotificationReceivedEvent extends NotificationEvent {
  final String title;
  final String body;
  final Map<String, dynamic>? data;

  const NotificationReceivedEvent({
    required this.title,
    required this.body,
    this.data,
  });

  @override
  List<Object?> get props => [title, body, data];
}

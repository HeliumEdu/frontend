// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:equatable/equatable.dart';
import 'package:heliumapp/data/models/notification/fcm_token_model.dart';
import 'package:heliumapp/data/models/notification/notification_model.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationInitialized extends NotificationState {
  final FCMTokenModel fcmToken;
  final bool isSubscribed;

  const NotificationInitialized({
    required this.fcmToken,
    this.isSubscribed = false,
  });

  @override
  List<Object?> get props => [fcmToken, isSubscribed];
}

class NotificationTokenLoaded extends NotificationState {
  final FCMTokenModel fcmToken;

  const NotificationTokenLoaded({required this.fcmToken});

  @override
  List<Object?> get props => [fcmToken];
}

class NotificationReceived extends NotificationState {
  final NotificationModel notification;

  const NotificationReceived({required this.notification});

  @override
  List<Object?> get props => [notification];
}

class NotificationCleared extends NotificationState {
  const NotificationCleared();
}

class NotificationTestSent extends NotificationState {
  final String message;

  const NotificationTestSent({required this.message});

  @override
  List<Object?> get props => [message];
}

class NotificationTopicSubscribed extends NotificationState {
  final String topic;

  const NotificationTopicSubscribed({required this.topic});

  @override
  List<Object?> get props => [topic];
}

class NotificationTopicUnsubscribed extends NotificationState {
  final String topic;

  const NotificationTopicUnsubscribed({required this.topic});

  @override
  List<Object?> get props => [topic];
}

class NotificationError extends NotificationState {
  final String message;
  final String? code;

  const NotificationError({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

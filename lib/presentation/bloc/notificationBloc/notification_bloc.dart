// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:bloc/bloc.dart';
import 'package:helium_mobile/core/app_exception.dart';
import 'package:helium_mobile/core/fcm_service.dart';
import 'package:helium_mobile/data/models/notification/notification_model.dart';
import 'package:helium_mobile/presentation/bloc/notificationBloc/notification_event.dart';
import 'package:helium_mobile/presentation/bloc/notificationBloc/notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final FCMService fcmService = FCMService();

  NotificationBloc()
    : super(const NotificationInitial()) {
    on<InitializeNotificationEvent>(_onInitializeNotification);
    on<GetFCMTokenEvent>(_onGetFCMToken);

    on<ClearAllNotificationsEvent>(_onClearAllNotifications);
    on<ClearNotificationEvent>(_onClearNotification);
    on<TestNotificationEvent>(_onTestNotification);
    on<NotificationReceivedEvent>(_onNotificationReceived);
  }

  Future<void> _onInitializeNotification(
    InitializeNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(const NotificationLoading());

    try {
      await fcmService.init();

      final fcmToken = fcmService.getFCMTokenModel();

      emit(NotificationInitialized(fcmToken: fcmToken, isSubscribed: false));
    } on AppException catch (e) {
      emit(NotificationError(message: e.message, code: e.code));
    } catch (e) {
      emit(
        NotificationError(message: 'Failed to initialize notifications: $e'),
      );
    }
  }

  Future<void> _onGetFCMToken(
    GetFCMTokenEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(const NotificationLoading());

    try {
      final fcmToken = fcmService.getFCMTokenModel();

      emit(NotificationTokenLoaded(fcmToken: fcmToken));
    } on AppException catch (e) {
      emit(NotificationError(message: e.message, code: e.code));
    } catch (e) {
      emit(NotificationError(message: 'Failed to get FCM token: $e'));
    }
  }

  Future<void> _onClearAllNotifications(
    ClearAllNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await fcmService.clearAllNotifications();

      emit(const NotificationCleared());
    } on AppException catch (e) {
      emit(NotificationError(message: e.message, code: e.code));
    } catch (e) {
      emit(NotificationError(message: 'Failed to clear notifications: $e'));
    }
  }

  Future<void> _onClearNotification(
    ClearNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await fcmService.clearNotification(event.notificationId);

      emit(const NotificationCleared());
    } on AppException catch (e) {
      emit(NotificationError(message: e.message, code: e.code));
    } catch (e) {
      emit(NotificationError(message: 'Failed to clear notification: $e'));
    }
  }

  Future<void> _onTestNotification(
    TestNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      // Create a test notification
      final testNotification = NotificationModel(
        title: 'Test Notification',
        body: 'This is a test notification from Helium!',
        notificationId: 'test_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        isRead: false,
        type: 'test',
        action: 'test_action',
      );

      // Show the test notification
      await fcmService.showLocalNotification(testNotification);

      emit(
        const NotificationTestSent(
          message: 'Test notification sent successfully!',
        ),
      );
    } on AppException catch (e) {
      emit(NotificationError(message: e.message, code: e.code));
    } catch (e) {
      emit(NotificationError(message: 'Failed to send test notification: $e'));
    }
  }

  void _onNotificationReceived(
    NotificationReceivedEvent event,
    Emitter<NotificationState> emit,
  ) {
    final notification = NotificationModel(
      title: event.title,
      body: event.body,
      data: event.data,
      notificationId: 'received_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      isRead: false,
    );

    emit(NotificationReceived(notification: notification));
  }
}

// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:js_interop';

import 'package:heliumapp/data/models/notification/notification_model.dart';
import 'package:logging/logging.dart';
import 'package:web/web.dart' as web;

final _log = Logger('core');

Future<bool> requestWebNotificationPermission() async {
  try {
    final permission = web.Notification.permission;

    if (permission == 'granted') {
      return true;
    } else if (permission == 'default') {
      final resultPromise = web.Notification.requestPermission();
      final result = await resultPromise.toDart;
      return result.toDart == 'granted';
    }

    return false;
  } catch (e) {
    _log.warning('Failed to request web notification permission: $e');
    return false;
  }
}

void showWebNotification(
  NotificationModel notification,
  Function(Map<String, dynamic>) onTap,
) {
  try {
    final options = web.NotificationOptions(
      body: notification.body,
      icon: '/favicon.png',
      tag: notification.id.toString(),
    );

    final webNotification = web.Notification(notification.title, options);

    webNotification.onclick = (web.Event event) {
      onTap({});
      webNotification.close();
    }.toJS;

    _log.info('Web notification displayed: ${notification.title}');
  } catch (e) {
    _log.warning('Failed to show web notification: $e');
  }
}

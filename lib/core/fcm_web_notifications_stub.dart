// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/notification/notification_model.dart';

// Stub implementation for non-web platforms
bool isMessagingSupported() {
  return true; // Native platforms always support messaging
}

Future<bool> requestWebNotificationPermission() async {
  return false;
}

void showWebNotification(
  NotificationModel notification,
  Function(Map<String, dynamic>) onTap,
) {
  // No-op on non-web platforms
}

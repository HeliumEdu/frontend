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

void dismissWebNotification(String reminderId) {
  // No-op on non-web platforms
}

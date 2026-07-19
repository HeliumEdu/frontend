// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static let nativeChannelName = "com.heliumedu.heliumapp/native"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: AppDelegate.nativeChannelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "getDeliveredReminderIdentifiers":
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
          let identifiers = notifications.map { $0.request.identifier }
          result(identifiers)
        }
      case "removeDeliveredNotifications":
        let identifiers = (call.arguments as? [String: Any])?["identifiers"] as? [String] ?? []
        if !identifiers.isEmpty {
          UNUserNotificationCenter.current()
            .removeDeliveredNotifications(withIdentifiers: identifiers)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // Clears a reminder's notification when it is dismissed on another device.
  // APNs files the notification under "reminder_<id>" (from apns-collapse-id),
  // so the dismiss push's reminder_id addresses it directly. Handled natively
  // rather than in the Dart background handler, which is unreliable on iOS when
  // terminated (flutterfire #7407). FCM swizzling forwards the callback here.
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    if let action = userInfo["action"] as? String, action == "dismiss",
       let reminderId = userInfo["reminder_id"] as? String {
      let identifier = "reminder_\(reminderId)"
      UNUserNotificationCenter.current()
        .removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    super.application(
      application,
      didReceiveRemoteNotification: userInfo,
      fetchCompletionHandler: completionHandler
    )
  }
}

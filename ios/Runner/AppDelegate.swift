import CoreSpotlight
import Flutter
import UIKit
import UniformTypeIdentifiers
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
    indexPlannerSearch()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Lets home-screen search find Helium by "planner" (for anyone who remembers what it is, not its name): one entry
  /// that opens the app, which lands signed-in students on the planner. Re-indexing the same id each launch is a
  /// no-op, and iOS removes it with the app.
  private func indexPlannerSearch() {
    let attributes = CSSearchableItemAttributeSet(contentType: UTType.content)
    attributes.title = "Planner"
    attributes.contentDescription = "Helium"
    attributes.keywords = ["planner"]
    let item = CSSearchableItem(
      uniqueIdentifier: "planner",
      domainIdentifier: "com.heliumedu.heliumapp.search",
      attributeSet: attributes
    )
    CSSearchableIndex.default().indexSearchableItems([item]) { error in
      if let error = error {
        NSLog("Couldn't add Helium's planner search entry: \(error.localizedDescription)")
      }
    }
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    KeyboardFlickerFix.install()

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
      case "getSystemProxy":
        result(AppDelegate.systemProxy())
      case "isiOSAppOnMac":
        result(ProcessInfo.processInfo.isiOSAppOnMac)
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

  /// Manually configured Wi-Fi proxy, or nil when none is set.
  private static func systemProxy() -> [String: Any]? {
    guard let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue()
      as? [String: Any],
      (settings[kCFNetworkProxiesHTTPEnable as String] as? NSNumber)?.boolValue == true,
      let host = settings[kCFNetworkProxiesHTTPProxy as String] as? String,
      !host.isEmpty,
      let port = (settings[kCFNetworkProxiesHTTPPort as String] as? NSNumber)?.intValue,
      port > 0
    else {
      return nil
    }

    return ["host": host, "port": port]
  }
}

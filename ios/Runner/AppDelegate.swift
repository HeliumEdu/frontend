import CoreSpotlight
import Flutter
import UIKit
import UniformTypeIdentifiers
import FirebaseCore
import home_widget

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static let nativeChannelName = "com.heliumedu.heliumapp/native"

  private(set) static var hasStartedFlutterEngine = false

  private static let escapeKeyCommand: UIKeyCommand = {
    let command = UIKeyCommand(
      input: UIKeyCommand.inputEscape,
      modifierFlags: [],
      action: #selector(escapePressed)
    )
    command.wantsPriorityOverSystemBehavior = true
    return command
  }()

  private var nativeChannel: FlutterMethodChannel?

  /// On a Mac, the text system takes Escape in a text field to end editing,
  /// so Flutter never sees the key. This command claims it first and hands
  /// it to Flutter, except while an input method is composing, where Escape
  /// cancels the composition.
  override var keyCommands: [UIKeyCommand]? {
    guard ProcessInfo.processInfo.isiOSAppOnMac else { return super.keyCommands }
    return (super.keyCommands ?? []) + [AppDelegate.escapeKeyCommand]
  }

  override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    if action == #selector(escapePressed) {
      return AppDelegate.isEditingText()
    }
    return super.canPerformAction(action, withSender: sender)
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    indexPlannerSearch()
    if #available(iOS 17, *) {
      HomeWidgetBackgroundWorker.setPluginRegistrantCallback { registry in
        GeneratedPluginRegistrant.register(with: registry)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

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
    AppDelegate.hasStartedFlutterEngine = true
    KeyboardFlickerFix.install()

    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: AppDelegate.nativeChannelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    nativeChannel = channel
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "getDeliveredReminderIdentifiers":
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
          let identifiers = notifications.map { $0.request.identifier }
          DispatchQueue.main.async { result(identifiers) }
        }
      case "removeDeliveredNotifications":
        let identifiers = (call.arguments as! [String: Any])["identifiers"] as! [String]
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
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

  /// Clears a reminder's notification when it is dismissed on another device.
  /// APNs files the notification under "reminder_<id>" (from apns-collapse-id),
  /// so the dismiss push's reminder_id addresses it directly. Handled natively
  /// rather than in the Dart background handler, which is unreliable on iOS when
  /// terminated (flutterfire #7407).
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

  @objc private func escapePressed() {
    nativeChannel?.invokeMethod("escapePressed", arguments: nil)
  }

  private static func isEditingText() -> Bool {
    let window = UIApplication.shared.connectedScenes
      .compactMap { ($0 as? UIWindowScene)?.keyWindow }
      .first
    guard let input = window.flatMap(firstResponder(in:)) as? UITextInput else {
      return false
    }
    return input.markedTextRange == nil
  }

  private static func firstResponder(in view: UIView) -> UIView? {
    if view.isFirstResponder { return view }
    for subview in view.subviews {
      if let responder = firstResponder(in: subview) { return responder }
    }
    return nil
  }

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

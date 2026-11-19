import AppIntents
import Foundation

#if !WIDGET_EXTENSION
  import Flutter
  import UIKit
  import WidgetKit
  import home_widget
#endif

enum HeliumAppGroup {
  static let id = "group.com.heliumedu.heliumapp"
  static let agendaSnapshotKey = "agenda_snapshot"
  static let agendaWidgetKind = "HeliumAgendaWidget"
}

/// The Agenda widget's checkbox. It runs in the app: it flips the item in the snapshot and reloads the widget, then
/// returns, so the row redraws at once and the widget takes the next tap. home_widget hands the flipped value to the
/// Dart interactivity callback, which settles rapid taps and saves, after that. The flip reads the snapshot, not the
/// URL, since a second tap before the reload carries the first tap's URL. The widget extension only needs the type
/// to build the toggle.
@available(iOS 17, *)
struct BackgroundIntent: AppIntent {
  static var title: LocalizedStringResource = "Complete assignment"
  static var isDiscoverable = false

  @Parameter(title: "Widget URL")
  var url: URL?

  init() {}

  init(url: URL) {
    self.url = url
  }

  func perform() async throws -> some IntentResult {
    #if !WIDGET_EXTENSION
      guard let url, await HeadlessWidgetEngine.prepare(),
        let toggledURL = try await AgendaSnapshotEditor.toggleCompleted(from: url)
      else { return .result() }
      WidgetCenter.shared.reloadTimelines(ofKind: HeliumAppGroup.agendaWidgetKind)
      await CompletionHandoff.start(toggledURL)
    #endif
    return .result()
  }
}

@available(iOS 17, *)
@available(iOSApplicationExtension, unavailable)
extension BackgroundIntent: ForegroundContinuableIntent {}

#if !WIDGET_EXTENSION
  /// home_widget only starts its headless engine when Dart registers the callback, which needs a scene. A tap that
  /// launches the app in the background starts it from the handles saved on an earlier launch; false when there are
  /// none.
  @available(iOS 17, *)
  @MainActor
  private enum HeadlessWidgetEngine {
    private static let dispatcherKey = "home_widget.internal.background.dispatcher"
    private static let callbackKey = "home_widget.internal.background.callback"
    private static var started = false

    static func prepare() -> Bool {
      if started || AppDelegate.hasStartedFlutterEngine { return true }

      let defaults = UserDefaults(suiteName: HeliumAppGroup.id)
      guard let dispatcher = defaults?.object(forKey: dispatcherKey) as? Int64,
        let callback = defaults?.object(forKey: callbackKey) as? Int64
      else { return false }

      started = true
      let plugin = HomeWidgetPlugin()
      plugin.handle(FlutterMethodCall(methodName: "setAppGroupId", arguments: ["groupId": HeliumAppGroup.id])) { _ in }
      plugin.handle(
        FlutterMethodCall(methodName: "registerBackgroundCallback", arguments: [dispatcher, callback])
      ) { _ in }
      return true
    }
  }

  /// Runs the Dart callback after the intent returns. The callback waits for taps to settle and saves, so the app is
  /// held awake for it, as it may have been launched in the background for this tap.
  @available(iOS 17, *)
  @MainActor
  private enum CompletionHandoff {
    static func start(_ url: URL) {
      var backgroundTask = UIBackgroundTaskIdentifier.invalid
      backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "Save widget check-off") {
        UIApplication.shared.endBackgroundTask(backgroundTask)
      }
      Task {
        await HomeWidgetBackgroundWorker.run(url: url, appGroup: HeliumAppGroup.id)
        UIApplication.shared.endBackgroundTask(backgroundTask)
      }
    }
  }

  @MainActor
  private enum AgendaSnapshotEditor {
    static func toggleCompleted(from url: URL) throws -> URL? {
      var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
      let key = components.queryItems!.first { $0.name == "key" }!.value!

      let defaults = UserDefaults(suiteName: HeliumAppGroup.id)!
      guard let json = defaults.string(forKey: HeliumAppGroup.agendaSnapshotKey) else { return nil }
      var snapshot = try JSONSerialization.jsonObject(with: Data(json.utf8)) as! [String: Any]
      var items = snapshot["items"] as! [[String: Any]]
      guard let index = items.firstIndex(where: { $0["key"] as? String == key }) else { return nil }
      let wasCompleted = items[index]["completed"] as! Bool
      if wasCompleted && items[index]["repeating"] as! Bool { return nil }

      items[index]["completed"] = !wasCompleted
      snapshot["items"] = items
      let data = try JSONSerialization.data(withJSONObject: snapshot)
      defaults.set(String(decoding: data, as: UTF8.self), forKey: HeliumAppGroup.agendaSnapshotKey)

      components.queryItems = [
        URLQueryItem(name: "key", value: key),
        URLQueryItem(name: "completed", value: String(!wasCompleted)),
      ]
      return components.url!
    }
  }
#endif

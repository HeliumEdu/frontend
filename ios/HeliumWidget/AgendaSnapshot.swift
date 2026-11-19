import Foundation

/// What the app last wrote for the widget (contract v1, `AgendaWidgetService` in the app).
struct AgendaSnapshot: Decodable {
  let version: Int
  let signedIn: Bool
  let generatedAt: Date
  let timeZone: String
  let olderOverdueCount: Int
  let days: [String: AgendaDay]
  let items: [AgendaItem]
}

/// A day's names as the app formats them, keyed by its `yyyy-MM-dd` day string.
struct AgendaDay: Decodable {
  let weekday: String
  let date: String
}

struct AgendaItem: Decodable, Identifiable {
  let key: String
  let title: String
  let start: Date
  let day: String
  let timeLabel: String
  let className: String?
  let color: String
  let completed: Bool
  let repeating: Bool
  let url: URL

  var id: String { key }

  var canToggle: Bool { !(repeating && completed) }

  func dayPrefix(today: String, days: [String: AgendaDay]) -> String? {
    day < today ? days[day]!.date : nil
  }

  /// The time and class, led by the day for an assignment overdue from an earlier day.
  func secondaryParts(today: String, days: [String: AgendaDay]) -> [String] {
    [dayPrefix(today: today, days: days), timeLabel, className].compactMap { $0 }
  }

  func secondaryLine(today: String, days: [String: AgendaDay]) -> String {
    secondaryParts(today: today, days: days).joined(separator: " · ")
  }

  var completionURL: URL {
    var components = URLComponents()
    components.scheme = AgendaLinks.scheme
    components.host = "complete"
    components.queryItems = [URLQueryItem(name: "key", value: key)]
    return components.url!
  }
}

enum AgendaLinks {
  static let scheme = "heliumwidget"
  static let planner = URL(string: "\(scheme)://open/planner")!
  static let overdueTodos = URL(string: "\(scheme)://open/planner?view=todos&status=overdue")!
}

enum AgendaState {
  case missing
  case signedOut
  case loaded(AgendaSnapshot)
}

enum AgendaStore {
  private static let supportedVersion = 1

  static func load() -> AgendaState {
    guard let json = UserDefaults(suiteName: HeliumAppGroup.id)?.string(forKey: HeliumAppGroup.agendaSnapshotKey),
      let snapshot = decode(json),
      snapshot.version == supportedVersion
    else { return .missing }
    return snapshot.signedIn ? .loaded(snapshot) : .signedOut
  }

  private static func decode(_ json: String) -> AgendaSnapshot? {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let value = try container.decode(String.self)
      guard let date = parseDate(value) else {
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Not an ISO 8601 date: \(value)")
      }
      return date
    }
    do {
      return try decoder.decode(AgendaSnapshot.self, from: Data(json.utf8))
    } catch {
      NSLog("Couldn't read the agenda snapshot: \(error)")
      return nil
    }
  }

  private static func parseDate(_ value: String) -> Date? {
    let toMilliseconds = value.replacingOccurrences(
      of: #"(\.\d{3})\d+"#, with: "$1", options: .regularExpression)
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.date(from: toMilliseconds)
  }
}

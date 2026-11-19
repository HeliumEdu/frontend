import Foundation
import WidgetKit

struct AgendaGroup: Identifiable {
  let title: String
  let isOverdue: Bool
  let items: [AgendaItem]

  var id: String { title }
}

/// The snapshot's items grouped as of one moment.
struct AgendaContent {
  static let staleAfter: TimeInterval = 24 * 60 * 60

  let groups: [AgendaGroup]
  let olderOverdueCount: Int
  let staleDays: Int?
  let today: String
  let todayLabel: String?
  let days: [String: AgendaDay]

  var isEmpty: Bool { groups.isEmpty }

  var hasUpcoming: Bool { groups.contains { !$0.isOverdue } }

  var overdueCount: Int {
    (groups.first(where: \.isOverdue)?.items.count ?? 0) + olderOverdueCount
  }

  init(snapshot: AgendaSnapshot, at date: Date) {
    let calendar = AgendaCalendar(timeZoneIdentifier: snapshot.timeZone)
    let today = calendar.day(of: date)
    var overdue: [AgendaItem] = []
    var upcoming: [(title: String, items: [AgendaItem])] = []

    for item in snapshot.items {
      if item.completed && item.start < date { continue }

      if !item.completed && item.start < date {
        overdue.append(item)
        continue
      }
      let title = calendar.groupTitle(for: item, today: today, days: snapshot.days)
      if let index = upcoming.firstIndex(where: { $0.title == title }) {
        upcoming[index].items.append(item)
      } else {
        upcoming.append((title, [item]))
      }
    }

    groups =
      (overdue.isEmpty && snapshot.olderOverdueCount == 0
        ? [] : [AgendaGroup(title: "Overdue", isOverdue: true, items: overdue)])
      + upcoming.map { AgendaGroup(title: $0.title, isOverdue: false, items: $0.items) }
    olderOverdueCount = snapshot.olderOverdueCount
    self.today = today
    todayLabel = snapshot.days[today]?.date
    days = snapshot.days

    let age = date.timeIntervalSince(snapshot.generatedAt)
    staleDays = age > Self.staleAfter ? Int(age / Self.staleAfter) : nil
  }
}

/// Calendar days in the user's time zone (the snapshot's, not the device's), as the app's `yyyy-MM-dd` day strings.
struct AgendaCalendar {
  private let calendar: Calendar
  private let dayFormatter: DateFormatter

  init(timeZoneIdentifier: String) {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: timeZoneIdentifier)!
    self.calendar = calendar

    dayFormatter = DateFormatter()
    dayFormatter.calendar = calendar
    dayFormatter.timeZone = calendar.timeZone
    dayFormatter.locale = Locale(identifier: "en_US_POSIX")
    dayFormatter.dateFormat = "yyyy-MM-dd"
  }

  func day(of date: Date) -> String {
    dayFormatter.string(from: date)
  }

  func groupTitle(for item: AgendaItem, today: String, days: [String: AgendaDay]) -> String {
    let daysAhead = calendar.dateComponents(
      [.day], from: dayFormatter.date(from: today)!, to: dayFormatter.date(from: item.day)!
    ).day!
    switch daysAhead {
    case ...0: return "Today"
    case 1: return "Tomorrow"
    case 2...6: return days[item.day]!.weekday
    default: return days[item.day]!.date
    }
  }

  func midnights(after date: Date, count: Int) -> [Date] {
    let today = calendar.startOfDay(for: date)
    return (1...count).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
  }
}

struct AgendaEntry: TimelineEntry {
  let date: Date
  let state: AgendaState
  let content: AgendaContent?

  init(date: Date, state: AgendaState) {
    self.date = date
    self.state = state
    if case .loaded(let snapshot) = state {
      content = AgendaContent(snapshot: snapshot, at: date)
    } else {
      content = nil
    }
  }
}

struct AgendaProvider: TimelineProvider {
  private static let horizonDays = 14
  private static let maxEntries = 60

  func placeholder(in context: Context) -> AgendaEntry {
    .sample
  }

  func getSnapshot(in context: Context, completion: @escaping (AgendaEntry) -> Void) {
    completion(context.isPreview ? .sample : AgendaEntry(date: .now, state: AgendaStore.load()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<AgendaEntry>) -> Void) {
    let now = Date.now
    let state = AgendaStore.load()
    let dates: [Date]
    if case .loaded(let snapshot) = state {
      dates = Self.refreshDates(for: snapshot, from: now)
    } else {
      dates = [now]
    }
    completion(Timeline(entries: dates.map { AgendaEntry(date: $0, state: state) }, policy: .atEnd))
  }

  private static func refreshDates(for snapshot: AgendaSnapshot, from now: Date) -> [Date] {
    let horizon = now.addingTimeInterval(TimeInterval(horizonDays * 24 * 60 * 60))
    let calendar = AgendaCalendar(timeZoneIdentifier: snapshot.timeZone)
    var dates = calendar.midnights(after: now, count: horizonDays)
    for item in snapshot.items {
      dates.append(item.start)
    }
    for day in 1...horizonDays {
      dates.append(snapshot.generatedAt.addingTimeInterval(TimeInterval(day) * AgendaContent.staleAfter))
    }

    let upcoming = Set(dates.filter { $0 > now && $0 <= horizon }).sorted()
    return [now] + upcoming.prefix(maxEntries - 1)
  }
}

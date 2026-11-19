import Foundation

extension AgendaSnapshot {
  /// The example schedule students can import, relative to now, for the widget gallery, placeholders and previews.
  static func sample(at now: Date = .now, timeZone: TimeZone = .current) -> AgendaSnapshot {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    let today = calendar.startOfDay(for: now)

    func formatter(_ format: String) -> DateFormatter {
      let formatter = DateFormatter()
      formatter.calendar = calendar
      formatter.timeZone = timeZone
      formatter.locale = Locale(identifier: "en_US_POSIX")
      formatter.dateFormat = format
      return formatter
    }
    let dayKey = formatter("yyyy-MM-dd")
    let weekday = formatter("EEEE")
    let date = formatter("EEE, MMM d")

    func at(_ days: Int, _ hour: Int, _ minute: Int = 0) -> Date {
      let day = calendar.date(byAdding: .day, value: days, to: today)!
      return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
    }

    func item(
      _ id: Int, _ title: String, _ start: Date, allDay: Bool = false, className: String, color: String,
      completed: Bool = false
    ) -> AgendaItem {
      let time = formatter(calendar.component(.minute, from: start) == 0 ? "h a" : "h:mm a")
      return AgendaItem(
        key: "homework:\(id)", title: title, start: start, day: dayKey.string(from: start),
        timeLabel: allDay ? "All day" : time.string(from: start), className: className, color: color,
        completed: completed, repeating: false,
        url: URL(string: "\(AgendaLinks.scheme)://open/planner/assignment/\(id)/details")!)
    }

    let days = Dictionary(
      uniqueKeysWithValues: (-7...14).map { offset in
        let day = calendar.date(byAdding: .day, value: offset, to: today)!
        return (dayKey.string(from: day), AgendaDay(weekday: weekday.string(from: day), date: date.string(from: day)))
      })
    let creativeWriting = "Creative Writing ✍️"
    let programming = "Fundamentals of Programming 💻"
    let psychology = "Intro to Psychology 🧠"

    return AgendaSnapshot(
      version: 1, signedIn: true, generatedAt: now, timeZone: timeZone.identifier, olderOverdueCount: 2, days: days,
      items: [
        item(1, "Case Study 3", at(-1, 13), className: psychology, color: "#3033cf"),
        item(2, "Quiz 7", at(0, 11), className: programming, color: "#05cc90", completed: true),
        item(3, "Short Stories 4", at(0, 11), className: creativeWriting, color: "#bd42a4"),
        item(4, "Quiz 5", at(1, 13), className: psychology, color: "#3033cf"),
        item(5, "Essay 7", at(2, 11), className: creativeWriting, color: "#bd42a4"),
        item(6, "Homework 7", at(3, 11), className: programming, color: "#05cc90"),
        item(7, "Reading (Chapters 13-16)", at(4, 0), allDay: true, className: creativeWriting, color: "#bd42a4"),
      ])
  }
}

extension AgendaEntry {
  /// The sample drawn at 8 AM today, so its 11 AM and 1 PM items are still upcoming whenever it's shown.
  static var sample: AgendaEntry {
    let date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: .now)!
    return AgendaEntry(date: date, state: .loaded(.sample(at: date)))
  }
}

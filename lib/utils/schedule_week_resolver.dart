/// Client-side mirror of the backend `resolve_week_index` for "Week A/B"
/// rotations. The backend owns rendering; this exists only so the schedule
/// editor can preview which calendar weeks a rotation resolves to, catching a
/// mis-set anchor before save. Day math is done in UTC so DST can't shift a
/// week boundary, and only ever walks forward from the anchor so truncating
/// division matches the backend's floor division.
class ScheduleWeekResolver {
  ScheduleWeekResolver._();

  static DateTime _mondayOf(DateTime date) {
    final utc = DateTime.utc(date.year, date.month, date.day);
    return utc.subtract(Duration(days: utc.weekday - DateTime.monday));
  }

  /// The 0-based week-of-rotation index [date] falls in, counted from the Monday
  /// of [anchor]'s week, mod [interval] (0 = Week A, 1 = Week B, …).
  static int weekIndex({
    required DateTime anchor,
    required int interval,
    required DateTime date,
  }) {
    final anchorMonday = _mondayOf(anchor);
    final target = DateTime.utc(date.year, date.month, date.day);
    final weeksSince = target.difference(anchorMonday).inDays ~/ 7;
    return weeksSince % interval;
  }

  /// The Mondays of the next [count] weeks, on or after [from], on which a
  /// schedule with [offset] meets — the concrete weeks shown in the editor's
  /// anchor preview.
  static List<DateTime> upcomingMeetingWeeks({
    required DateTime anchor,
    required int interval,
    required int offset,
    required DateTime from,
    int count = 3,
  }) {
    final start = from.isBefore(anchor) ? anchor : from;
    var monday = _mondayOf(start);
    while (weekIndex(anchor: anchor, interval: interval, date: monday) !=
        offset) {
      monday = monday.add(const Duration(days: 7));
    }

    final weeks = <DateTime>[];
    for (var i = 0; i < count; i++) {
      weeks.add(monday);
      monday = monday.add(Duration(days: 7 * interval));
    }
    return weeks;
  }
}

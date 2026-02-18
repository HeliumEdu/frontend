// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

/// Utility class for building iCalendar RRULE strings.
///
/// SfCalendar uses the iCalendar RRULE format for recurring events.
/// This builder helps construct valid RRULE strings for course schedules.
class RRuleBuilder {
  /// Maps day index (0=Sunday, 6=Saturday) to iCalendar day code.
  static const dayIndexToCode = {
    0: 'SU',
    1: 'MO',
    2: 'TU',
    3: 'WE',
    4: 'TH',
    5: 'FR',
    6: 'SA',
  };

  /// Builds a weekly recurrence rule string.
  ///
  /// Parameters:
  /// - [dayIndices]: List of day indices (0=Sunday, 6=Saturday) when the event occurs
  /// - [until]: The end date for the recurrence (exclusive)
  ///
  /// Returns an RRULE string like "FREQ=WEEKLY;BYDAY=MO,WE,FR;UNTIL=20251215T235959Z"
  static String buildWeeklyRecurrence({
    required List<int> dayIndices,
    required DateTime until,
  }) {
    if (dayIndices.isEmpty) {
      throw ArgumentError('dayIndices must not be empty');
    }

    // Convert day indices to iCalendar day codes
    final dayCodes = dayIndices
        .map((index) => dayIndexToCode[index])
        .where((code) => code != null)
        .toList();

    if (dayCodes.isEmpty) {
      throw ArgumentError('No valid day indices provided');
    }

    // Format the UNTIL date in iCalendar format (UTC)
    // Add one day to make it inclusive, then set to end of day
    final untilDate = DateTime.utc(
      until.year,
      until.month,
      until.day,
      23,
      59,
      59,
    );
    final untilString = _formatDateTime(untilDate);

    return 'FREQ=WEEKLY;BYDAY=${dayCodes.join(',')};UNTIL=$untilString';
  }

  /// Formats a DateTime to iCalendar format: YYYYMMDDTHHMMSSZ
  static String _formatDateTime(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$year$month${day}T$hour$minute${second}Z';
  }
}

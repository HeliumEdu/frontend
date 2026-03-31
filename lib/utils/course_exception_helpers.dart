// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

/// Utility functions for course and course-group exception dates.
///
/// The backend stores exceptions as a comma-separated string of YYYYMMDD dates
/// (e.g. "20251107,20251128,20260101"). These helpers convert between that
/// wire format and typed [DateTime] lists used throughout the frontend.
class CourseExceptionHelpers {
  /// Parses a comma-separated YYYYMMDD exception string from the API into a
  /// list of local midnight [DateTime] values.
  ///
  /// Returns an empty list for a blank string.
  static List<DateTime> parseCsvExceptions(String csv) {
    if (csv.trim().isEmpty) return const [];

    final result = <DateTime>[];
    for (final part in csv.split(',')) {
      final s = part.trim();
      if (s.length != 8) continue;
      final year = int.tryParse(s.substring(0, 4));
      final month = int.tryParse(s.substring(4, 6));
      final day = int.tryParse(s.substring(6, 8));
      if (year == null || month == null || day == null) continue;
      result.add(DateTime(year, month, day));
    }
    return result;
  }

  /// Formats a list of [DateTime] values into a comma-separated YYYYMMDD
  /// string suitable for the API.
  ///
  /// Dates are sorted ascending before formatting. Returns an empty string for
  /// an empty list.
  static String formatExceptionsCsv(List<DateTime> exceptions) {
    if (exceptions.isEmpty) return '';
    final sorted = List<DateTime>.from(exceptions)..sort();
    return sorted.map(_formatDate).join(',');
  }

  /// Returns a deduplicated, sorted list of all exception dates that apply to
  /// a specific course: its own [courseExceptions] plus any
  /// [courseGroupExceptions] (semester holidays).
  ///
  /// Used by [CourseScheduleBuilderSource] to populate
  /// [CourseScheduleEventModel.exceptionDates].
  static List<DateTime> mergeExceptions(
    List<DateTime> courseExceptions,
    List<DateTime> courseGroupExceptions,
  ) {
    final seen = <String>{};
    final merged = <DateTime>[];

    for (final dt in [...courseExceptions, ...courseGroupExceptions]) {
      final key = _formatDate(dt);
      if (seen.add(key)) merged.add(dt);
    }

    merged.sort();
    return merged;
  }

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }
}

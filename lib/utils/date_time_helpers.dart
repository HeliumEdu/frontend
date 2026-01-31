// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:timezone/standalone.dart' as tz;

final log = Logger('HeliumLogger');

class HeliumTime {
  static TimeOfDay? parse(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String formatForDisplay(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    return DateFormat('h:mm a').format(dateTime);
  }

  static String formatForApi(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    return DateFormat('HH:mm:00').format(dateTime);
  }
}

class HeliumDateTime {
  static DateTime parse(String isoString, tz.Location timeZone) {
    return tz.TZDateTime.from(DateTime.parse(isoString), timeZone);
  }

  static String formatDayNameShort(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  static String formatDateForDisplay(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateAndTimeForDisplay(DateTime date) {
    return DateFormat(
      'MMM dd, yyyy • h:mm a',
    ).format(date).replaceAll(':00', '');
  }

  static String formatTimeForDisplay(DateTime date) {
    return DateFormat('h:mm a').format(date).replaceAll(':00', '');
  }

  static String formatDateTimeRangeForDisplay(
    DateTime startDate,
    DateTime endDate,
    bool showEndTime,
    bool isAllDay,
  ) {
    final String dateDisplay = HeliumDateTime.formatDateForDisplay(startDate);

    if (!isAllDay) {
      return '$dateDisplay • ${HeliumDateTime.formatTimeRangeForDisplay(startDate, endDate, showEndTime)}';
    } else {
      return dateDisplay;
    }
  }

  static String formatTimeRangeForDisplay(
    DateTime startDate,
    DateTime endDate,
    bool showEndTime,
  ) {
    final formattedTime = HeliumDateTime.formatTimeForDisplay(startDate);
    if (showEndTime && startDate != endDate) {
      final formattedEndTime = HeliumDateTime.formatTimeForDisplay(endDate);
      return '$formattedTime - $formattedEndTime';
    } else {
      return formattedTime;
    }
  }

  static String formatDateForApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatDateAndTimeForApi(
    DateTime date,
    TimeOfDay? time,
    tz.Location timeZone,
  ) {
    final dateTime = tz.TZDateTime(
      timeZone,
      date.year,
      date.month,
      date.day,
      time?.hour ?? 0,
      time?.minute ?? 0,
    );
    return dateTime.toIso8601String();
  }

  static int getDaysBetween(String startDate, String endDate) {
    if (startDate.isEmpty || endDate.isEmpty) {
      return 0;
    }

    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);
    final now = DateTime.now();

    // If before start date, return 0%
    if (now.isBefore(start)) {
      return 0;
    }

    // If after end date, return 100%
    if (now.isAfter(end)) {
      return 100;
    }

    // Calculate percentage
    final totalDays = end.difference(start).inDays;
    if (totalDays <= 0) {
      return 0;
    }

    return now.difference(start).inDays;
  }

  static int getPercentDiffBetween(String startDate, String endDate) {
    if (startDate.isEmpty || endDate.isEmpty) {
      return 0;
    }

    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);
    final now = DateTime.now();

    // If before start date, return 0%
    if (now.isBefore(start)) {
      return 0;
    }

    // If after end date, return 100%
    if (now.isAfter(end)) {
      return 100;
    }

    // Calculate percentage
    final totalDays = end.difference(start).inDays;
    if (totalDays <= 0) {
      return 0;
    }

    final daysElapsed = now.difference(start).inDays;
    final percentage = (daysElapsed / totalDays * 100).round();

    // Clamp between 0 and 100
    if (percentage < 0) return 0;
    if (percentage > 100) return 100;
    return percentage;
  }
}

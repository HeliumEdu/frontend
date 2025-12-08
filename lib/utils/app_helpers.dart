// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/data/models/planner/reminder_response_model.dart';
import 'package:heliumapp/utils/app_enums.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:timezone/standalone.dart' as tz;

final log = Logger('HeliumLogger');

extension PluralExtension on int {
  String plural(String singularWord, [String pluralLetters = 's']) {
    return (this == 0 || this > 1)
        ? '$singularWord$pluralLetters'
        : singularWord;
  }
}

TimeOfDay? parseTime(String timeString) {
  try {
    if (timeString == '00:00:00' || timeString.isEmpty) {
      return null;
    }
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  } catch (e) {
    log.info('Error parsing time: $e');
    return null;
  }
}

String formatTimeForDisplay(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

String formatTimeForApi(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
}

DateTime parseDateTime(String isoString, String timeZone) {
  return tz.TZDateTime.from(
    DateTime.parse(isoString),
    tz.getLocation(timeZone),
  );
}

String formatDateForDisplay(DateTime date) {
  return DateFormat('MMM dd, yyyy').format(date);
}

String formatDateForApi(DateTime date) {
  return date.toIso8601String().substring(0, 10);
}

String formatDateTimeToApi(DateTime date, TimeOfDay? time, String timeZone) {
  if (time != null) {
    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    return tz.TZDateTime.from(
      dateTime,
      tz.getLocation(timeZone),
    ).toIso8601String();
  }
  return date.toIso8601String();
}

String formatPercent(String value, bool? zeroAsNa) {
  try {
    final percentage = double.parse(value);
    if (percentage == 0 && zeroAsNa != null && zeroAsNa) {
      return 'N/A';
    } else if (percentage == percentage.roundToDouble()) {
      return '${percentage.toInt()}%';
    } else {
      return '${percentage.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')}%';
    }
  } catch (e) {
    return 'N/A';
  }
}

String formatReminderOffset(ReminderResponseModel reminder) {
  String units = reminderOffsetUnits[reminder.offsetType].toLowerCase();
  if (reminder.offset == 1) {
    units = units.substring(0, units.length - 1);
  }
  return '${reminder.offset.toString()} $units';
}

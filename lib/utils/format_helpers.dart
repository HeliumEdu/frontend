// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/utils/app_globals.dart';

extension PluralExtension on int {
  String plural(String singularWord, [String pluralLetters = 's']) {
    return (this == 0 || this > 1)
        ? '$singularWord$pluralLetters'
        : singularWord;
  }
}

class Format {
  static String percentForDisplay(String value, bool? zeroAsNa) {
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

  static String reminderOffset(ReminderModel reminder) {
    String units = ReminderConstants.offsetTypes[reminder.offsetType]
        .toLowerCase();
    if (reminder.offset == 1) {
      units = units.substring(0, units.length - 1);
    }
    return '${reminder.offset.toString()} $units';
  }

  static String gradeForDisplay(dynamic grade, [showNaAsBlank = false]) {
    if (grade == null ||
        grade == '' ||
        grade == '-1/100' ||
        grade == 0 ||
        grade == -1.0) {
      if (showNaAsBlank) {
        return '';
      } else {
        return 'N/A';
      }
    }

    final double gradeValue;
    if (grade is String) {
      final split = grade.split('/');
      gradeValue = (double.parse(split[0]) / double.parse(split[1])) * 100;
    } else {
      gradeValue = grade;
    }

    return '${gradeValue.toStringAsFixed(2)}%';
  }
}

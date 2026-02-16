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
  static String reminderOffset(ReminderModel reminder) {
    String units = ReminderConstants.offsetTypes[reminder.offsetType]
        .toLowerCase();
    if (reminder.offset == 1) {
      units = units.substring(0, units.length - 1);
    }
    return '${reminder.offset.toString()} $units';
  }
}

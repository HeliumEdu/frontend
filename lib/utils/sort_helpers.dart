// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';

class Sort {
  static void byTitle(List<BaseModel> list) {
    list.sort((a, b) => a.title.compareTo(b.title));
  }

  static void byStartDate(List<CourseGroupModel> list) {
    list.sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  static void byStartOfRange(List<ReminderModel> list, timeZone) {
    list.sort((a, b) {
      final aDate = HeliumDateTime.parse(a.startOfRange, timeZone);
      final bDate = HeliumDateTime.parse(b.startOfRange, timeZone);
      return bDate.compareTo(aDate);
    });
  }
}

// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/drop_down_item.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';

/// Schedule-template presets, mirroring the backend `enums.SCHEDULE_TEMPLATES`
/// (WEEKLY = 0 is the non-rotating default). Custom is a frontend-only sentinel.
class ScheduleTemplate {
  ScheduleTemplate._();

  static const int abDay = 1;
  static const int sixDayCycle = 2;
  static const int eightDayCycle = 3;
  static const int weekAb = 4;

  /// UI-only sentinel: a Custom rotation sends raw fields with no `template`.
  static const int custom = -1;

  /// UX caps for Custom rotations: generous headroom over real rotations while
  /// keeping the editor's day rows / week chips bounded.
  static const int maxCycleLength = 20;
  static const int maxWeekInterval = 8;

  /// Cycle length per day-cycle preset, to render the right number of day rows.
  static const Map<int, int> presetCycleLength = {
    abDay: 2,
    sixDayCycle: 6,
    eightDayCycle: 8,
  };

  static bool isDayCyclePreset(int template) =>
      presetCycleLength.containsKey(template);

  static bool isWeekBasedPreset(int template) => template == weekAb;

  /// A short label for a rotating schedule ("6-Day Cycle", "Week A"), or null
  /// for a plain weekly one.
  static String? summaryLabel(CourseScheduleModel schedule) {
    if (schedule.isDayCycle) {
      switch (schedule.template) {
        case abDay:
          return 'A/B Day';
        case sixDayCycle:
          return '6-Day Cycle';
        case eightDayCycle:
          return '8-Day Cycle';
        default:
          return '${schedule.cycleLength}-Day Cycle';
      }
    }
    if (schedule.isWeekBased) {
      final offset = schedule.weekOffset ?? 0;
      if (schedule.weekInterval == 2) {
        return offset == 0 ? 'Week A' : 'Week B';
      }
      return 'Week ${offset + 1} of ${schedule.weekInterval}';
    }
    return null;
  }

  /// Items for the "Rotating" template dropdown.
  static List<DropDownItem<int>> get items => [
        DropDownItem(id: abDay, value: abDay, label: 'A/B Day'),
        DropDownItem(id: sixDayCycle, value: sixDayCycle, label: '6-Day Cycle'),
        DropDownItem(
          id: eightDayCycle,
          value: eightDayCycle,
          label: '8-Day Cycle',
        ),
        DropDownItem(id: weekAb, value: weekAb, label: 'Week A/B'),
        DropDownItem(id: custom, value: custom, label: 'Custom'),
      ];
}

// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart' show seedColor;
import 'package:heliumapp/data/models/drop_down_item.dart';
import 'package:heliumapp/utils/dropdown_extensions.dart';
import 'package:heliumapp/utils/planner_helper.dart';

class AppConstants {
  static const appName = 'Helium';

  static const iosUrl = 'https://apps.apple.com/app/app-name/id6758323154';
  static const androidUrl = 'https://play.google.com/store/apps/details?id=com.heliumedu.heliumapp';
  static const patreonUrl = 'https://www.patreon.com/c/alexdlaird';

  static const assignmentIcon = Icons.assignment_outlined;
  static const eventIcon = Icons.event_outlined;
  static const courseScheduleIcon = Icons.school;
  static const externalCalendarIcon = Icons.hub;

  static const authContainerSize = 120.0;
  static const minHeightForTrailingNav = 500.0;
  static const leftPanelDialogWidth = 500.0;
  static const notificationsDialogWidth = 420.0;
  static const centeredDialogWidth = 550.0;
}

class FallbackConstants {
  static const fallbackColor = seedColor;

  static const defaultViewIndex = 2; // Day view
  static const defaultWeekStartsOn = 0; // Sunday
  static const defaultTimeZone = 'Etc/UTC';
  static const defaultReminderType = 3; // Push
  static const defaultReminderOffset = 30; // 30 minutes
  static const defaultReminderOffsetType = 0; // Minutes
  static const defaultColorByCategory = false;
  static const defaultColorSchemeTheme = 2; // System
  static const defaultAllDayOffset = 0;
  static const defaultWhatsNewVersionSeen = 0;
  static const defaultShowGettingStarted = false;
  static const defaultEventsColor = Color(0xffe74674);
  static const defaultResourceColor = Color(0xffdc7d50);
  static const defaultGradeColor = Color(0xff9d629d);
  static const defaultCalendarUseCategoryColors = false;
  static const defaultShowPlannerTooltips = true;
  static const defaultDragAndDropOnMobile = true;
  static const defaultRememberFilterState = false;
  static const defaultCollapseBusyDays = false;
}

/// Colors for planner item types (Events, Homework, Class Schedules, External Calendars).
/// Static colors chosen to work well in both light and dark modes.
class PlannerTypeColors {
  PlannerTypeColors._();

  /// Amber/orange for homework/assignments
  static const homework = Color(0xffE5A000);

  /// Blue for class schedules (matches app primary/seed color)
  static const classSchedules = seedColor;

  /// Purple/lavender for external calendars
  static const externalCalendars = Color(0xff9575CD);

  /// Events color - user configurable, falls back to default
  static Color events([Color? userColor]) =>
      userColor ?? FallbackConstants.defaultEventsColor;

  /// Rainbow gradient for multi-colored assignments indicator
  static const homeworkGradient = LinearGradient(
    colors: [
      Color(0xFFE57373), // red
      Color(0xFFFFB74D), // orange
      Color(0xFFAED581), // green
      Color(0xFF4FC3F7), // blue
      Color(0xFFBA68C8), // purple
    ],
  );

  /// Returns a rainbow-colored icon (indicates items are multi-colored)
  static Widget rainbowIcon(IconData icon, {double size = 18}) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => homeworkGradient.createShader(bounds),
      child: Icon(icon, size: size),
    );
  }
}

class CalendarConstants {
  static const List<String> colorSchemeThemes = ['Light', 'Dark', 'System'];

  static const List<String> dayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];
  static final List<DropDownItem<String>> dayNamesItems = dayNames
      .toDropDownItems();

  static const List<String> dayNamesAbbrev = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  static const List<String> defaultViews = [
    'Month',
    'Week',
    'Day',
    'Todos',
    'Agenda',
  ];
  static final List<DropDownItem<String>> defaultViewItems = PlannerView.values
      .map((view) {
        final apiIndex = PlannerHelper.mapHeliumViewToApiView(view);
        return DropDownItem(id: apiIndex, value: defaultViews[apiIndex]);
      })
      .toList();
}

// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart'
    show SemanticColors, seedColor;
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
/// Use [PlannerTypeColors.of] to get colors that respect the current theme.
class PlannerTypeColors {
  final Color events;
  final Color homework;
  final Color classSchedules;
  final Color externalCalendars;

  const PlannerTypeColors._({
    required this.events,
    required this.homework,
    required this.classSchedules,
    required this.externalCalendars,
  });

  /// External calendar color - purple/violet that works in both light and dark modes
  static const externalCalendarColorLight = Color(0xff7e57c2);
  static const externalCalendarColorDark = Color(0xffb39ddb);

  /// Get planner type colors for the current theme context.
  /// [eventsColor] should be passed from userSettings.eventsColor if available.
  static PlannerTypeColors of(
    BuildContext context, {
    Color? eventsColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final semanticColors =
        Theme.of(context).extension<SemanticColors>() ?? SemanticColors.light;

    return PlannerTypeColors._(
      events: eventsColor ?? FallbackConstants.defaultEventsColor,
      homework: semanticColors.warning,
      classSchedules: colorScheme.primary,
      externalCalendars:
          isDark ? externalCalendarColorDark : externalCalendarColorLight,
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

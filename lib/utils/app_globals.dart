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
  static const patreonUrl = 'https://www.patreon.com/alexdlaird/membership';
  static const githubUrl = 'https://github.com/HeliumEdu';

  static const assignmentIcon = Icons.assignment_outlined;
  static const eventIcon = Icons.event_outlined;
  static const courseScheduleIcon = Icons.school;
  static const externalCalendarIcon = Icons.hub;

  static const authContainerSize = 120.0;
  static const minHeightForTrailingNav = 575.0;
  static const leftPanelDialogWidth = 500.0;
  static const notificationsDialogWidth = 420.0;
  static const centeredDialogWidth = 550.0;
}

class FallbackConstants {
  static const fallbackColor = seedColor;

  static const defaultViewIndex = 2;
  static const defaultWeekStartsOn = 0;
  static const defaultTimeZone = 'Etc/UTC';
  static const defaultReminderType = 3;
  static const defaultReminderOffset = 30;
  static const defaultReminderOffsetType = 0;
  static const defaultColorByCategory = false;
  static const defaultColorSchemeTheme = 2;
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
  static const defaultAtRiskThreshold = 70;
  static const defaultOnTrackTolerance = 10;
  static const defaultShowWeekNumbers = true;
}

/// Colors for planner item types (Events, Homework, Class Schedules, External Calendars)
class PlannerTypeColors {
  static const homework = Color(0xffcfa25e);
  static const classSchedules = Color(0xff5658d7);
  static const externalCalendars = Color(0xff049f71);
  static Color events([Color? userColor]) =>
      userColor ?? FallbackConstants.defaultEventsColor;
  static const _rainbowGradient = LinearGradient(
    colors: [
      Color(0xffec6f92),
      Color(0xffdc7d50),
      Color(0xff049f71),
      Color(0xff5658d7),
      Color(0xffc964b5),
    ],
  );
  static Widget rainbowIcon(IconData icon, {double size = 18}) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => _rainbowGradient.createShader(bounds),
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

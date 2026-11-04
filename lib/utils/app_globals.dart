import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart' show seedColor;
import 'package:heliumapp/data/models/drop_down_item.dart';
import 'package:heliumapp/utils/dropdown_extensions.dart';
import 'package:heliumapp/utils/planner_helper.dart';

class AppConstants {
  static const appName = 'Helium';

  static const _heliumBaseUrl = 'https://www.heliumedu.com';

  static const iosUrl = 'https://apps.apple.com/app/app-name/id6758323154';
  static const androidUrl = 'https://play.google.com/store/apps/details?id=com.heliumedu.heliumapp';
  static const patreonUrl = 'https://www.patreon.com/alexdlaird/membership';
  static const githubUrl = 'https://github.com/HeliumEdu';
  static const termsUrl = '$_heliumBaseUrl/terms';
  static const privacyUrl = '$_heliumBaseUrl/privacy';
  static const supportPortalUrl = '$_heliumBaseUrl/support';
  static const supportWhereToStartUrl = '$_heliumBaseUrl/support/getting-started/where-to-start-with-helium';
  static const supportExternalCalendarsUrl = '$_heliumBaseUrl/support/sync-and-integration/how-to-sync-google-apple-or-other-calendars-into-helium-using-external-calendars';
  static const supportApiUrl = '$_heliumBaseUrl/support/sync-and-integration/using-the-helium-api';
  static const supportConnectedAppsUrl = '$supportWhereToStartUrl/#connect-your-ai-assistant';
  static const supportFeedsUrl = '$_heliumBaseUrl/support/sync-and-integration/how-to-sync-helium-out-to-google-apple-or-other-calendars-using-feeds';
  static const supportImportExportUrl = '$_heliumBaseUrl/support/import-export-and-backup/importing-and-exporting-your-data';
  static const supportGradesDashboardUrl = '$_heliumBaseUrl/support/grades-and-progress/understanding-the-grades-dashboard/';
  static const supportSchedulesUrl = '$_heliumBaseUrl/support/classes/class-meeting-schedules';

  static const assignmentIcon = Icons.assignment_outlined;
  static const eventIcon = Icons.event_outlined;
  static const courseScheduleIcon = Icons.school;
  static const externalCalendarIcon = Icons.hub;

  static const uiAnimationDuration = Duration(milliseconds: 300);
  static const bottomSheetMaxHeightFactor = 0.5;

  static const authContainerSize = 120.0;
  static const minHeightForTrailingNav = 620.0;
  static const leftPanelDialogWidth = 500.0;
  static const notificationsDialogWidth = 420.0;
  static const centeredDialogWidth = 550.0;

  static const pageHeaderPadding = EdgeInsets.fromLTRB(12, 6, 12, 2);
  static const dialogHeaderPadding = EdgeInsets.fromLTRB(12, 6, 12, 6);
  static const contentTopInset = 8.0;

  /// Screen edge to bordered containers.
  static const pageEdgeInset = 8.0;
  /// Border to content, inside bordered containers and cards.
  static const containerContentInset = 12.0;
  /// Screen edge to content that isn't in a bordered container, where content
  /// inside a container at [pageEdgeInset] also starts.
  static const unboxedContentInset = pageEdgeInset + containerContentInset;
  /// Screen edge to content on the centered sign-in screens.
  static const centerCardContentInset = 16.0;
  /// Border to content where space is tight, like the Planner's header.
  static const denseContainerContentInset = 6.0;
  /// Cell edge to content in every table column, so the first and last
  /// columns' content also sits this far from the table's border.
  static const tableCellInset = 8.0;

  static const dialogContentPadding = EdgeInsets.fromLTRB(
    unboxedContentInset,
    contentTopInset,
    unboxedContentInset,
    20,
  );
}

class RegionalFormatConstants {
  static const dateFormatMonthDayYear = 0;
  static const dateFormatDayMonthYear = 1;

  static const timeFormatTwelveHour = 0;
  static const timeFormatTwentyFourHour = 1;

  static const numberFormatPoint = 0;
  static const numberFormatComma = 1;

  static const weekStartsOnSunday = 0;

  static const dateFormats = [dateFormatMonthDayYear, dateFormatDayMonthYear];
  static const timeFormats = [timeFormatTwelveHour, timeFormatTwentyFourHour];
  static const numberFormats = [numberFormatPoint, numberFormatComma];
}

class FallbackConstants {
  static const fallbackColor = seedColor;
}

/// Colors for planner item types (Homework, Class Schedules, External Calendars); events
/// use the user's events color.
class PlannerTypeColors {
  static const homework = Color(0xffcfa25e);
  static const classSchedules = Color(0xff5658d7);
  static const externalCalendars = Color(0xff049f71);
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
    '3-Day',
  ];
  static final List<DropDownItem<String>> defaultViewItems = PlannerView.values
      .map((view) {
        final apiIndex = PlannerHelper.mapHeliumViewToApiView(view);
        return DropDownItem(id: apiIndex, value: defaultViews[apiIndex]);
      })
      .toList();
}

// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/notification/notification_model.dart';
import 'package:heliumapp/data/models/planner/calendar_item_base_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_event_model.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:logging/logging.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

final _log = Logger('utils');

class PlannerHelper {
  static final List<int> weekStartsOnRemap = [7, 1, 2, 3, 4, 5, 6];

  static NotificationModel mapPayloadToNotification(
    RemoteMessage message,
    dynamic payload,
  ) {
    final reminder = ReminderModel.fromJson(payload);

    final String start;
    if (reminder.homework != null) {
      start = reminder.homework!.entity!.start;
    } else if (reminder.event != null) {
      start = reminder.event!.entity!.start;
    } else {
      if (!kDebugMode) {
        throw ArgumentError.notNull(
          'Both homework and event are null on Reminder ${reminder.id}, which is not allowed',
        );
      } else {
        _log.warning(
          'Both homework and event are null on Reminder ${reminder.id}, using now as "start"',
        );
        start = DateTime.now().toString();
      }
    }

    return NotificationModel(
      id: reminder.id,
      title: message.notification!.title!,
      body: message.notification!.body!,
      reminder: reminder,
      timestamp: start,
      isRead: false,
    );
  }

  static CalendarView mapHeliumViewToSfCalendarView(HeliumView view) {
    switch (view) {
      case HeliumView.month:
        return CalendarView.month;
      case HeliumView.week:
        return CalendarView.week;
      case HeliumView.day:
        return CalendarView.day;
      case HeliumView.agenda:
        return CalendarView.schedule;
      case HeliumView.todos:
        // We default to day so SfCalendar does not query for more data than
        // necessary when we're on a non-calendar view
        return CalendarView.day;
    }
  }

  static HeliumView mapSfCalendarViewToHeliumView(CalendarView view) {
    switch (view) {
      case CalendarView.month:
        return HeliumView.month;
      case CalendarView.week:
        return HeliumView.week;
      case CalendarView.day:
        return HeliumView.day;
      case CalendarView.schedule:
        return HeliumView.agenda;
      default:
        // For any other SfCalendar views, default to day
        return HeliumView.day;
    }
  }

  static HeliumView mapApiViewToHeliumView(int view) {
    switch (view) {
      case 0:
        return HeliumView.month;
      case 1:
        return HeliumView.week;
      case 2:
        return HeliumView.day;
      case 3:
        return HeliumView.todos;
      case 4:
        return HeliumView.agenda;
      default:
        throw HeliumException(message: '$view is not a valid API view');
    }
  }

  static int mapHeliumViewToApiView(HeliumView view) {
    switch (view) {
      case HeliumView.month:
        return 0;
      case HeliumView.week:
        return 1;
      case HeliumView.day:
        return 2;
      case HeliumView.agenda:
        return 4;
      case HeliumView.todos:
        return 3;
    }
  }

  static AlignmentGeometry getAlignmentForView(
    BuildContext context,
    bool isInAgenda,
    HeliumView view,
  ) {
    if (Responsive.isMobile(context)) {
      return Alignment.topLeft;
    }

    if (view == HeliumView.month && isInAgenda) {
      return Alignment.topLeft;
    }

    return view != HeliumView.month ? Alignment.topLeft : Alignment.centerLeft;
  }

  static bool shouldShowCheckbox(
    BuildContext context,
    CalendarItemBaseModel calendarItem,
    HeliumView view,
  ) {
    if (calendarItem is! HomeworkModel) {
      return false;
    }

    if (Responsive.isMobile(context)) {
      if (view == HeliumView.week || view == HeliumView.day) {
        return false;
      }
    }

    return true;
  }

  static bool shouldShowSchoolIcon(
    BuildContext context,
    CalendarItemBaseModel calendarItem,
    HeliumView view,
  ) {
    if (calendarItem is! CourseScheduleEventModel) {
      return false;
    }

    return true;
  }

  static bool shouldShowTimeBeforeTitle(
    BuildContext context,
    calendarItem,
    bool isInAgenda,
    HeliumView view,
  ) {
    if (Responsive.isMobile(context) &&
        (view != HeliumView.agenda || view != HeliumView.todos)) {
      return false;
    }

    if (view == HeliumView.month && isInAgenda) {
      return false;
    }

    if (calendarItem.allDay) {
      return false;
    }

    if (view != HeliumView.month) {
      return false;
    }

    return true;
  }

  static bool shouldShowTimeBelowTitle(
    BuildContext context,
    calendarItem,
    bool isInAgenda,
    HeliumView view,
  ) {
    if (calendarItem.allDay) {
      return false;
    }

    if (Responsive.isMobile(context)) {
      if (view == HeliumView.week || view == HeliumView.day) {
        return false;
      }
    }

    if (!Responsive.isMobile(context) && view == HeliumView.month) {
      if (!isInAgenda) {
        return false;
      }
    }

    return true;
  }

  static bool shouldShowLocationBelowTitle(
    BuildContext context,
    calendarItem,
    bool isInAgenda,
    HeliumView view,
  ) {
    if (isInAgenda && calendarItem.allDay) {
      return true;
    }

    if (calendarItem.allDay) {
      return false;
    }

    if (!Responsive.isMobile(context) && view == HeliumView.month) {
      if (!isInAgenda) {
        return false;
      }
    }

    return true;
  }

  static bool shouldShowEditButton(BuildContext context) {
    return !Responsive.isMobile(context);
  }

  static bool shouldShowEditButtonForCalendarItem(
    BuildContext context,
    CalendarItemBaseModel calendarItem,
  ) {
    if (!shouldShowEditButton(context)) {
      return false;
    }

    return calendarItem is HomeworkModel || calendarItem is EventModel;
  }

  static bool shouldShowDeleteButton(CalendarItemBaseModel calendarItem) {
    return calendarItem is HomeworkModel || calendarItem is EventModel;
  }
}

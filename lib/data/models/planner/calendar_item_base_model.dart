// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:ui';

import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/id_or_entity.dart';
import 'package:heliumapp/data/models/planner/attachment_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:logging/logging.dart';

final log = Logger('HeliumLogger');

abstract class CalendarItemBaseModel extends BaseModel {
  final bool allDay;
  final bool showEndTime;
  final String start;
  final String end;
  final int priority;
  final String? url;
  final String comments;
  final Color? color;
  final String? location;
  final CalendarItemType calendarItemType;
  final List<IdOrEntity<AttachmentModel>> attachments;
  final List<IdOrEntity<ReminderModel>> reminders;

  CalendarItemBaseModel({
    required super.id,
    required super.title,
    required this.allDay,
    required this.showEndTime,
    required this.start,
    required this.end,
    required this.priority,
    this.url,
    required this.comments,
    this.color,
    this.location,
    required this.calendarItemType,
    required this.attachments,
    required this.reminders,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'all_day': allDay,
      'show_end_time': showEndTime,
      'start': start,
      'end': end,
      'priority': priority,
      'url': url,
      'comments': comments,
      'attachments': attachments,
      'reminders': reminders,
      'calendar_item_type': calendarItemType,
    };
  }
}

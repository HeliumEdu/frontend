// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:heliumapp/data/models/planner/attachment_model.dart';
import 'package:heliumapp/data/models/planner/event_base_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/conversion_helpers.dart';
import 'package:heliumapp/utils/planner_helper.dart';

class ExternalCalendarEventModel extends EventBaseModel {
  final String ownerId;

  ExternalCalendarEventModel({
    required super.id,
    required super.title,
    required super.allDay,
    required super.showEndTime,
    required super.start,
    required super.end,
    required super.priority,
    required super.url,
    required super.comments,
    required super.attachments,
    required super.reminders,
    required super.color,
    required this.ownerId,
    super.recurrenceRule,
    super.exceptionDates,
  }) : super(plannerItemType: PlannerItemType.external);

  factory ExternalCalendarEventModel.fromJson(Map<String, dynamic> json) {
    // The backend derives a stable id per external calendar event from its ICS UID,
    // so json['id'] is safe to use directly. This recomputes an equivalent id from
    // the same content fields instead, which is redundant but harmless.
    final ownerId = json['owner_id'] as String;
    final start = DateTime.parse(json['start'] as String);
    final title = json['title'] as String;
    final stableId = Object.hashAll([ownerId, start.millisecondsSinceEpoch, title]);

    return ExternalCalendarEventModel(
      id: stableId,
      title: title,
      allDay: json['all_day'],
      showEndTime: json['show_end_time'],
      start: start,
      end: DateTime.parse(json['end']),
      priority: json['priority'],
      url: toUri(json['url']),
      comments: json['comments'],
      attachments: json['attachments'] != null
          ? idOrEntityListFrom(json['attachments'], AttachmentModel.fromJson)
          : [],
      reminders: json['reminders'] != null
          ? idOrEntityListFrom(json['reminders'], ReminderModel.fromJson)
          : [],
      ownerId: ownerId,
      color: HeliumColors.hexToColor(json['color']),
      recurrenceRule: json['recurrence_rule'] as String?,
      exceptionDates: EventBaseModel.parseExceptionDatesJson(
        json['exception_dates'],
      ),
    );
  }

  @override
  ExternalCalendarEventModel copyAtOccurrence(DateTime start, DateTime end) {
    return ExternalCalendarEventModel(
      id: id,
      title: title,
      allDay: allDay,
      showEndTime: showEndTime,
      start: start,
      end: end,
      priority: priority,
      url: url,
      comments: comments,
      attachments: attachments,
      reminders: reminders,
      color: color,
      ownerId: ownerId,
      recurrenceRule: recurrenceRule,
      exceptionDates: exceptionDates,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();

    data['ownerId'] = ownerId;
    data['color'] = HeliumColors.colorToHex(color!);

    return data;
  }
}

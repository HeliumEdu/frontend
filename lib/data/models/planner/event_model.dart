// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/data/models/id_or_entity.dart';
import 'package:heliumapp/data/models/planner/attachment_model.dart';
import 'package:heliumapp/data/models/planner/planner_item_base_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/conversion_helpers.dart';

class EventModel extends PlannerItemBaseModel {
  final String? ownerId;

  EventModel({
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
    this.ownerId,
  }) : super(plannerItemType: PlannerItemType.event);

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      title: json['title'],
      allDay: json['all_day'],
      showEndTime: json['show_end_time'],
      start: DateTime.parse(json['start']),
      end: DateTime.parse(json['end']),
      priority: json['priority'],
      url: json['url'],
      comments: json['comments'],
      attachments: json['attachments'] != null
          ? HeliumConversion.idOrEntityListFrom(
              json['attachments'],
              AttachmentModel.fromJson,
            )
          : [],
      reminders: json['reminders'] != null
          ? HeliumConversion.idOrEntityListFrom(
              json['reminders'],
              ReminderModel.fromJson,
            )
          : [],
      ownerId: json['owner_id'],
      color: json['color'] != null
          ? HeliumColors.hexToColor(json['color'])
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();

    data['ownerId'] = ownerId;
    data['color'] = color != null ? HeliumColors.colorToHex(color!) : null;

    return data;
  }

  EventModel copyWith({
    int? id,
    String? title,
    bool? allDay,
    bool? showEndTime,
    DateTime? start,
    DateTime? end,
    int? priority,
    String? url,
    String? comments,
    List<IdOrEntity<AttachmentModel>>? attachments,
    List<IdOrEntity<ReminderModel>>? reminders,
    Color? color,
    String? ownerId,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      allDay: allDay ?? this.allDay,
      showEndTime: showEndTime ?? this.showEndTime,
      start: start ?? this.start,
      end: end ?? this.end,
      priority: priority ?? this.priority,
      url: url ?? this.url,
      comments: comments ?? this.comments,
      attachments: attachments ?? this.attachments,
      reminders: reminders ?? this.reminders,
      color: color ?? this.color,
      ownerId: ownerId ?? this.ownerId,
    );
  }
}

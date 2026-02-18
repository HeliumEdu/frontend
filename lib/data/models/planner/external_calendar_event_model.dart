// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/attachment_model.dart';
import 'package:heliumapp/data/models/planner/planner_item_base_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/conversion_helpers.dart';
import 'package:heliumapp/utils/planner_helper.dart';

class ExternalCalendarEventModel extends PlannerItemBaseModel {
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
  }) : super(plannerItemType: PlannerItemType.external);

  factory ExternalCalendarEventModel.fromJson(Map<String, dynamic> json) {
    return ExternalCalendarEventModel(
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
          ? idOrEntityListFrom(json['attachments'], AttachmentModel.fromJson)
          : [],
      reminders: json['reminders'] != null
          ? idOrEntityListFrom(json['reminders'], ReminderModel.fromJson)
          : [],
      ownerId: json['owner_id'],
      color: HeliumColors.hexToColor(json['color']),
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

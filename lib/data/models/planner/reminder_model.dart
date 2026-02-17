// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE fiimport 'package:heliumapp/utils/app_helpers.dartimport 'package:heliumapp/utils/app_helpers.darimport 'package:heliumapp/utils/app_helpers.dart';

import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/id_or_entity.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/utils/conversion_helpers.dart';

class ReminderModel extends BaseTitledModel {
  final String message;
  final DateTime startOfRange;
  final int offset;
  final int offsetType;
  final int type;
  final bool sent;
  final bool dismissed;
  final IdOrEntity<HomeworkModel>? homework;
  final IdOrEntity<EventModel>? event;

  ReminderModel({
    required super.id,
    required super.title,
    required this.message,
    required this.startOfRange,
    required this.offset,
    required this.offsetType,
    required this.type,
    required this.sent,
    required this.dismissed,
    this.homework,
    this.event,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      startOfRange: DateTime.parse(json['start_of_range']),
      offset: json['offset'],
      offsetType: json['offset_type'],
      type: json['type'],
      sent: json['sent'],
      dismissed: json['dismissed'],
      homework: json['homework'] != null
          ? HeliumConversion.idOrEntityFrom(
              json['homework'],
              HomeworkModel.fromJson,
            )
          : null,
      event: json['event'] != null
          ? HeliumConversion.idOrEntityFrom(json['event'], EventModel.fromJson)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'start_of_range': startOfRange.toIso8601String(),
      'offset': offset,
      'offset_type': offsetType,
      'type': type,
      'sent': sent,
      'dismissed': dismissed,
      'homework': homework,
      'event': event,
    };
  }
}

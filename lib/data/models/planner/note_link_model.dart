// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/utils/color_helpers.dart';

class NoteLinkModel {
  final int id;
  final int? homeworkId;
  final int? eventId;
  final int? resourceId;
  final String linkedEntityType;
  final String? linkedEntityTitle;
  final Color? linkedEntityColor;
  final Color? linkedEntityColorAlt;

  NoteLinkModel({
    required this.id,
    this.homeworkId,
    this.eventId,
    this.resourceId,
    required this.linkedEntityType,
    this.linkedEntityTitle,
    this.linkedEntityColor,
    this.linkedEntityColorAlt,
  });

  factory NoteLinkModel.fromJson(Map<String, dynamic> json) {
    return NoteLinkModel(
      id: json['id'],
      homeworkId: json['homework'],
      eventId: json['event'],
      resourceId: json['material'],
      linkedEntityType: json['linked_entity_type'] ?? '',
      linkedEntityTitle: json['linked_entity_title'],
      linkedEntityColor: json['linked_entity_color'] != null
          ? HeliumColors.hexToColor(json['linked_entity_color'])
          : null,
      linkedEntityColorAlt: json['linked_entity_color_alt'] != null
          ? HeliumColors.hexToColor(json['linked_entity_color_alt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'homework': homeworkId,
      'event': eventId,
      'material': resourceId,
      'linked_entity_type': linkedEntityType,
      'linked_entity_title': linkedEntityTitle,
      'linked_entity_color': linkedEntityColor != null
          ? HeliumColors.colorToHex(linkedEntityColor!)
          : null,
      'linked_entity_color_alt': linkedEntityColorAlt != null
          ? HeliumColors.colorToHex(linkedEntityColorAlt!)
          : null,
    };
  }

  NoteLinkModel copyWith({
    int? id,
    int? homeworkId,
    int? eventId,
    int? resourceId,
    String? linkedEntityType,
    String? linkedEntityTitle,
    Color? linkedEntityColor,
    Color? linkedEntityColorAlt,
  }) {
    return NoteLinkModel(
      id: id ?? this.id,
      homeworkId: homeworkId ?? this.homeworkId,
      eventId: eventId ?? this.eventId,
      resourceId: resourceId ?? this.resourceId,
      linkedEntityType: linkedEntityType ?? this.linkedEntityType,
      linkedEntityTitle: linkedEntityTitle ?? this.linkedEntityTitle,
      linkedEntityColor: linkedEntityColor ?? this.linkedEntityColor,
      linkedEntityColorAlt: linkedEntityColorAlt ?? this.linkedEntityColorAlt,
    );
  }
}

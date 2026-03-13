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
  final int? materialId;
  final String linkedEntityType;
  final String? linkedEntityTitle;
  final Color? linkedEntityColor;

  NoteLinkModel({
    required this.id,
    this.homeworkId,
    this.eventId,
    this.materialId,
    required this.linkedEntityType,
    this.linkedEntityTitle,
    this.linkedEntityColor,
  });

  factory NoteLinkModel.fromJson(Map<String, dynamic> json) {
    return NoteLinkModel(
      id: json['id'],
      homeworkId: json['homework'],
      eventId: json['event'],
      materialId: json['material'],
      linkedEntityType: json['linked_entity_type'] ?? '',
      linkedEntityTitle: json['linked_entity_title'],
      linkedEntityColor: json['linked_entity_color'] != null
          ? HeliumColors.hexToColor(json['linked_entity_color'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'homework': homeworkId,
      'event': eventId,
      'material': materialId,
      'linked_entity_type': linkedEntityType,
      'linked_entity_title': linkedEntityTitle,
      'linked_entity_color': linkedEntityColor != null
          ? HeliumColors.colorToHex(linkedEntityColor!)
          : null,
    };
  }

  NoteLinkModel copyWith({
    int? id,
    int? homeworkId,
    int? eventId,
    int? materialId,
    String? linkedEntityType,
    String? linkedEntityTitle,
    Color? linkedEntityColor,
  }) {
    return NoteLinkModel(
      id: id ?? this.id,
      homeworkId: homeworkId ?? this.homeworkId,
      eventId: eventId ?? this.eventId,
      materialId: materialId ?? this.materialId,
      linkedEntityType: linkedEntityType ?? this.linkedEntityType,
      linkedEntityTitle: linkedEntityTitle ?? this.linkedEntityTitle,
      linkedEntityColor: linkedEntityColor ?? this.linkedEntityColor,
    );
  }
}

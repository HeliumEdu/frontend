// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/utils/color_helpers.dart';

class NoteModel extends BaseTitledModel {
  final Map<String, dynamic>? content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<int> homework;
  final List<int> events;
  final List<int> resources;
  final String linkedEntityType;
  final String? linkedEntityTitle;
  final DateTime? linkedEntityDue;
  final bool? linkedEntityCompleted;
  final Color? courseColor;
  final Color? categoryColor;

  NoteModel({
    required super.id,
    required super.title,
    this.content,
    required this.createdAt,
    required this.updatedAt,
    this.homework = const [],
    this.events = const [],
    this.resources = const [],
    this.linkedEntityType = '',
    this.linkedEntityTitle,
    this.linkedEntityDue,
    this.linkedEntityCompleted,
    this.courseColor,
    this.categoryColor,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    // Parse M2M fields
    final homework = (json['homework'] as List<dynamic>?)?.cast<int>() ?? [];
    final events = (json['events'] as List<dynamic>?)?.cast<int>() ?? [];
    final resources = (json['resources'] as List<dynamic>?)?.cast<int>() ?? [];

    return NoteModel(
      id: json['id'],
      title: json['title'] ?? '',
      content: json['content'] != null
          ? Map<String, dynamic>.from(json['content'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      homework: homework,
      events: events,
      resources: resources,
      linkedEntityType: json['linked_entity_type'] ?? '',
      linkedEntityTitle: json['linked_entity_title'],
      linkedEntityDue: json['linked_entity_due_date'] != null
          ? DateTime.parse(json['linked_entity_due_date'])
          : null,
      linkedEntityCompleted: json['linked_entity_completed'] as bool?,
      courseColor: json['course_color'] != null
          ? HeliumColors.hexToColor(json['course_color'])
          : null,
      categoryColor: json['category_color'] != null
          ? HeliumColors.hexToColor(json['category_color'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'homework': homework,
      'events': events,
      'resources': resources,
    };
  }

  bool get isStandalone => linkedEntityType.isEmpty;

  bool get isLinkedToHomework => homework.isNotEmpty;

  bool get isLinkedToEvent => events.isNotEmpty;

  bool get isLinkedToMaterial => resources.isNotEmpty;

  bool get hasLinkedEntity => linkedEntityType.isNotEmpty;
}

import 'package:flutter/material.dart';
import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/resource_model.dart';
import 'package:heliumapp/utils/color_helpers.dart';

class NoteModel extends BaseTitledModel {
  final Map<String, dynamic>? content;
  final DateTime updatedAt;

  final List<int> homework;
  final List<int> events;
  final List<int> resources;
  final String linkedEntityType;
  final String? linkedEntityTitle;
  final DateTime? linkedEntityDue;
  final bool? linkedEntityCompleted;
  final int? courseId;
  final Color? courseColor;
  final Color? categoryColor;

  NoteModel({
    required super.id,
    required super.title,
    this.content,
    required this.updatedAt,
    super.version,
    this.homework = const [],
    this.events = const [],
    this.resources = const [],
    this.linkedEntityType = '',
    this.linkedEntityTitle,
    this.linkedEntityDue,
    this.linkedEntityCompleted,
    this.courseId,
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
      updatedAt: DateTime.parse(json['updated_at']),
      version: json['updated_at'],
      homework: homework,
      events: events,
      resources: resources,
      linkedEntityType: json['linked_entity_type'] ?? '',
      linkedEntityTitle: json['linked_entity_title'],
      linkedEntityDue: json['linked_entity_due'] != null
          ? DateTime.parse(json['linked_entity_due'])
          : null,
      linkedEntityCompleted: json['linked_entity_completed'] as bool?,
      courseId: json['course_id'] as int?,
      courseColor: json['course_color'] != null
          ? HeliumColors.hexToColor(json['course_color'])
          : null,
      categoryColor: json['category_color'] != null
          ? HeliumColors.hexToColor(json['category_color'])
          : null,
    );
  }

  NoteModel copyWith({
    int? id,
    String? title,
    Map<String, dynamic>? content,
    DateTime? updatedAt,
    String? version,
    List<int>? homework,
    List<int>? events,
    List<int>? resources,
    String? linkedEntityType,
    String? linkedEntityTitle,
    DateTime? linkedEntityDue,
    bool? linkedEntityCompleted,
    int? courseId,
    Color? courseColor,
    Color? categoryColor,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      homework: homework ?? this.homework,
      events: events ?? this.events,
      resources: resources ?? this.resources,
      linkedEntityType: linkedEntityType ?? this.linkedEntityType,
      linkedEntityTitle: linkedEntityTitle ?? this.linkedEntityTitle,
      linkedEntityDue: linkedEntityDue ?? this.linkedEntityDue,
      linkedEntityCompleted: linkedEntityCompleted ?? this.linkedEntityCompleted,
      courseId: courseId ?? this.courseId,
      courseColor: courseColor ?? this.courseColor,
      categoryColor: categoryColor ?? this.categoryColor,
    );
  }

  bool get isStandalone => linkedEntityType.isEmpty;

  /// Like the Planner's class filter, only notes tied to a class are narrowed;
  /// standalone and event notes, and those with no known class, pass.
  bool matchesCourseFilter(
    Set<int> courseIds,
    Map<int, ResourceModel> resourcesById,
  ) {
    if (linkedEntityType == 'homework') {
      return courseId == null || courseIds.contains(courseId);
    }
    if (linkedEntityType == 'resource') {
      final resourceCourseIds = resources
          .expand((id) => resourcesById[id]?.courses ?? const <int>[])
          .toSet();
      return resourceCourseIds.isEmpty ||
          resourceCourseIds.any(courseIds.contains);
    }
    return true;
  }
}

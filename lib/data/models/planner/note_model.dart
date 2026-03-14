// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/note_link_model.dart';

class NoteModel extends BaseTitledModel {
  final Map<String, dynamic>? content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final NoteLinkModel? link;

  NoteModel({
    required super.id,
    required super.title,
    this.content,
    required this.createdAt,
    required this.updatedAt,
    this.link,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'],
      title: json['title'] ?? '',
      content: json['content'] != null
          ? Map<String, dynamic>.from(json['content'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      link: json['link'] != null ? NoteLinkModel.fromJson(json['link']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'link': link?.toJson(),
    };
  }

  NoteModel copyWith({
    int? id,
    String? title,
    Map<String, dynamic>? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    NoteLinkModel? link,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      link: link ?? this.link,
    );
  }

  bool get isStandalone => link == null;

  bool get isLinkedToHomework => link?.homeworkId != null;

  bool get isLinkedToEvent => link?.eventId != null;

  bool get isLinkedToMaterial => link?.resourceId != null;
}

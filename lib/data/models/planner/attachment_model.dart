// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/base_model.dart';

class AttachmentModel extends BaseModel {
  final String attachment;
  final int size;
  final int user;
  final int? course;
  final int? event;
  final int? homework;

  AttachmentModel({
    required super.id,
    required super.title,
    required this.attachment,
    required this.size,
    required this.user,
    this.course,
    this.event,
    this.homework,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['id'],
      title: json['title'],
      attachment: json['attachment'],
      size: json['size'],
      user: json['user'],
      course: json['course'],
      event: json['event'],
      homework: json['homework'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'attachment': attachment,
      'size': size,
      'user': user,
      'course': course,
      'event': event,
      'homework': homework,
    };
  }
}

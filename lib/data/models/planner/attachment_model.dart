// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class AttachmentModel {
  final int id;
  final String title;
  final String attachment;
  final int size;
  final int? course;
  final int? event;
  final int? homework;
  final int? user;

  AttachmentModel({
    required this.id,
    required this.title,
    required this.attachment,
    required this.size,
    this.course,
    this.event,
    this.homework,
    this.user,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      attachment: json['attachment'] ?? '',
      size: json['size'] ?? 0,
      course: json['course'],
      event: json['event'],
      homework: json['homework'],
      user: json['user'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'attachment': attachment,
      'size': size,
      'course': course,
      'event': event,
      'homework': homework,
      'user': user,
    };
  }

  // Helper to get file size in readable format
  String getFormattedSize() {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }
}

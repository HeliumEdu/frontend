// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class NoteRequestModel {
  final String? title;
  final Map<String, dynamic>? content;
  final int? homeworkId;
  final int? eventId;
  final int? resourceId;
  final bool clearLinks;

  NoteRequestModel({
    this.title,
    this.content,
    this.homeworkId,
    this.eventId,
    this.resourceId,
    this.clearLinks = false,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (title != null) json['title'] = title;
    if (content != null) json['content'] = content;
    if (clearLinks || homeworkId != null || eventId != null || resourceId != null) {
      json['homework'] = homeworkId != null ? [homeworkId] : [];
      json['events'] = eventId != null ? [eventId] : [];
      json['resources'] = resourceId != null ? [resourceId] : [];
    }

    return json;
  }
}

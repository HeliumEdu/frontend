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
    if (clearLinks) {
      json['homework'] = [];
      json['events'] = [];
      json['resources'] = [];
    } else {
      if (homeworkId != null) json['homework'] = [homeworkId];
      if (eventId != null) json['events'] = [eventId];
      if (resourceId != null) json['resources'] = [resourceId];
    }

    return json;
  }
}

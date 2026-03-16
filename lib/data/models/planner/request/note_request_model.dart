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

  NoteRequestModel({
    this.title,
    this.content,
    this.homeworkId,
    this.eventId,
    this.resourceId,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (title != null) json['title'] = title;
    if (content != null) json['content'] = content;
    if (eventId != null) json['events'] = [eventId];
    if (resourceId != null) json['resources'] = [resourceId];

    return json;
  }
}

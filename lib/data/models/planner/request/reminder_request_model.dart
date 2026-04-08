// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class ReminderRequestModel {
  final String? title;
  final String? message;
  final int? offset;
  final int? offsetType;
  final int? type;
  final bool? sent;
  final bool? dismissed;
  final int? homework;
  final int? event;
  final int? course;

  ReminderRequestModel({
    this.title,
    this.message,
    this.offset,
    this.offsetType,
    this.type,
    this.sent,
    this.dismissed,
    this.homework,
    this.event,
    this.course,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};

    if (title != null) data['title'] = title;
    if (message != null) data['message'] = message;
    if (offset != null) data['offset'] = offset;
    if (offsetType != null) data['offset_type'] = offsetType;
    if (type != null) data['type'] = type;
    if (sent != null) data['sent'] = sent;
    if (dismissed != null) data['dismissed'] = dismissed;
    if (homework != null) data['homework'] = homework;
    if (event != null) data['event'] = event;
    if (course != null) data['course'] = course;

    return data;
  }
}

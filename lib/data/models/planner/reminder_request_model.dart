// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class ReminderRequestModel {
  final String title;
  final String message;
  final int offset;
  final int offsetType;
  final int type;
  final bool sent;
  final bool dismissed;
  final int? homework;
  final int? event;

  ReminderRequestModel({
    required this.title,
    required this.message,
    required this.offset,
    required this.offsetType,
    required this.type,
    required this.sent,
    required this.dismissed,
    this.homework,
    this.event,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'title': title,
      'message': message,
      'offset': offset,
      'offset_type': offsetType,
      'type': type,
      'sent': sent,
      'dismissed': dismissed,
    };

    if (homework != null) data['homework'] = homework;
    if (event != null) data['event'] = event;

    return data;
  }
}

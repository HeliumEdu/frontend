// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class ReminderResponseModel {
  final int id;
  final String title;
  final String message;
  final String startOfRange;
  final int offset;
  final int offsetType;
  final int type;
  final bool sent;
  final bool dismissed;
  final Map? homework;
  final Map? event;
  final int userId;

  ReminderResponseModel({
    required this.id,
    required this.title,
    required this.message,
    required this.startOfRange,
    required this.offset,
    required this.offsetType,
    required this.type,
    required this.sent,
    required this.dismissed,
    this.homework,
    this.event,
    required this.userId,
  });

  factory ReminderResponseModel.fromJson(Map<String, dynamic> json) {
    int? parseId(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is Map<String, dynamic>) {
        final idVal = value['id'];
        if (idVal is int) return idVal;
        if (idVal is String) {
          return int.tryParse(idVal);
        }
      }
      if (value is String) return int.tryParse(value);
      return null;
    }

    return ReminderResponseModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      startOfRange: json['start_of_range'],
      offset: json['offset'] ?? 0,
      offsetType: json['offset_type'] ?? 0,
      type: json['type'] ?? 0,
      sent: json['sent'] ?? false,
      dismissed: json['dismissed'] ?? false,
      homework: parseCalendarItem(json['homework']),
      event: parseCalendarItem(json['event']),
      userId: parseId(json['user']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'start_of_range': startOfRange,
      'offset': offset,
      'offset_type': offsetType,
      'type': type,
      'sent': sent,
      'dismissed': dismissed,
      'homework': homework,
      'event': event,
      'user': userId,
    };
  }

  static Map<dynamic, dynamic>? parseCalendarItem(value) {
    if (value is int) {
      return {'id': value};
    } else {
      return value;
    }
  }
}

// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class ExternalCalendarEventModel {
  final int id;
  final String title;
  final bool allDay;
  final String start;
  final String? end;
  final String? url;
  final String? comments;
  final int externalCalendar;
  final int userId;

  ExternalCalendarEventModel({
    required this.id,
    required this.title,
    required this.allDay,
    required this.start,
    this.end,
    this.url,
    this.comments,
    required this.externalCalendar,
    required this.userId,
  });

  factory ExternalCalendarEventModel.fromJson(Map<String, dynamic> json) {
    int _parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    int _extractId(dynamic value) {
      if (value is Map<String, dynamic>) {
        if (value.containsKey('id')) {
          return _parseInt(value['id']);
        }
        if (value.containsKey('pk')) {
          return _parseInt(value['pk']);
        }
      }
      return _parseInt(value);
    }

    int _extractExternalCalendarId(Map<String, dynamic> source) {
      if (source.containsKey('id')) {
        return _extractId(source['id']);
      } else if (source.containsKey('external_calendar')) {
        return _extractId(source['external_calendar']);
      }
      return 0;
    }

    int _extractUserId(Map<String, dynamic> source) {
      if (source.containsKey('user')) {
        return _extractId(source['user']);
      }
      if (source.containsKey('user_id')) {
        return _extractId(source['user_id']);
      }
      if (source.containsKey('owner')) {
        return _extractId(source['owner']);
      }
      return 0;
    }

    return ExternalCalendarEventModel(
      id: _parseInt(json['id']),
      title: json['title'] ?? '',
      allDay: json['all_day'] ?? json['allDay'] ?? false,
      start: json['start'] ?? '',
      end: json['end'],
      url: json['url'],
      comments: json['comments'],
      externalCalendar: _extractExternalCalendarId(json),
      userId: _extractUserId(json),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'title': title,
      'all_day': allDay,
      'start': start,
      'external_calendar': externalCalendar,
      'user': userId,
    };

    if (end != null) data['end'] = end;
    if (url != null) data['url'] = url;
    if (comments != null) data['comments'] = comments;

    return data;
  }
}

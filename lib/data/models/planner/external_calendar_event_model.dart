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
      if (source.containsKey('external_calendar')) {
        return _extractId(source['external_calendar']);
      }
      if (source.containsKey('calendar')) {
        return _extractId(source['calendar']);
      }
      if (source.containsKey('externalCalendar')) {
        return _extractId(source['externalCalendar']);
      }
      if (source.containsKey('calendar_id')) {
        return _extractId(source['calendar_id']);
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

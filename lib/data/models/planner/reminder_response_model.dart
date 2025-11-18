class ReminderResponseModel {
  final int id;
  final String title;
  final String message;
  final String? startOfRange;
  final int offset;
  final int offsetType;
  final int type;
  final bool sent;
  final int? homework;
  final int? event;
  final int userId;

  ReminderResponseModel({
    required this.id,
    required this.title,
    required this.message,
    this.startOfRange,
    required this.offset,
    required this.offsetType,
    required this.type,
    required this.sent,
    this.homework,
    this.event,
    required this.userId,
  });

  factory ReminderResponseModel.fromJson(Map<String, dynamic> json) {
    int? _parseId(dynamic value) {
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
      homework: _parseId(json['homework']),
      event: _parseId(json['event']),
      userId: _parseId(json['user']) ?? 0,
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
      'homework': homework,
      'event': event,
      'user': userId,
    };
  }
}

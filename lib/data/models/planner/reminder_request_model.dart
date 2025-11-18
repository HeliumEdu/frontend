class ReminderRequestModel {
  final String title;
  final String message;
  final int offset;
  final int offsetType;
  final int type;
  final bool sent;
  final int? homework;
  final int? event;

  ReminderRequestModel({
    required this.title,
    required this.message,
    required this.offset,
    required this.offsetType,
    required this.type,
    this.sent = false,
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
    };

    if (homework != null) data['homework'] = homework;
    if (event != null) data['event'] = event;

    return data;
  }
}

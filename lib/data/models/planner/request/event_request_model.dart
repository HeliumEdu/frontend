class EventRequestModel {
  final String? title;
  final bool? allDay;
  final bool? showEndTime;
  final String? start;
  final String? end;
  final int? priority;
  final String? recurrenceRule;
  final bool clearRecurrenceRule;

  EventRequestModel({
    this.title,
    this.allDay,
    this.showEndTime,
    this.start,
    this.end,
    this.priority,
    this.recurrenceRule,
    this.clearRecurrenceRule = false,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (title != null) json['title'] = title;
    if (allDay != null) json['all_day'] = allDay;
    if (showEndTime != null) json['show_end_time'] = showEndTime;
    if (start != null) json['start'] = start;
    if (end != null) json['end'] = end;
    if (priority != null) json['priority'] = priority;
    if (clearRecurrenceRule) {
      json['recurrence_rule'] = null;
      json['exception_dates'] = null;
    } else if (recurrenceRule != null) {
      json['recurrence_rule'] = recurrenceRule;
    }

    return json;
  }
}

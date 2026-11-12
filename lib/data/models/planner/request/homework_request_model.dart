class HomeworkRequestModel {
  final int? course;
  final String? title;
  final bool? allDay;
  final bool? showEndTime;
  final String? start;
  final String? end;
  final int? priority;
  final String? currentGrade;
  final bool? completed;
  final int? category;
  final List<int>? resources;
  final String? recurrenceRule;
  final bool clearRecurrenceRule;

  HomeworkRequestModel({
    this.course,
    this.title,
    this.allDay,
    this.showEndTime,
    this.start,
    this.end,
    this.priority,
    this.currentGrade,
    this.completed,
    this.category,
    this.resources,
    this.recurrenceRule,
    this.clearRecurrenceRule = false,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (course != null) json['course'] = course;
    if (title != null) json['title'] = title;
    if (allDay != null) json['all_day'] = allDay;
    if (showEndTime != null) json['show_end_time'] = showEndTime;
    if (start != null) json['start'] = start;
    if (end != null) json['end'] = end;
    if (priority != null) json['priority'] = priority;
    if (currentGrade != null) json['current_grade'] = currentGrade;
    if (completed != null) json['completed'] = completed;
    if (category != null) json['category'] = category;
    if (resources != null) json['resources'] = resources;
    if (clearRecurrenceRule) {
      json['recurrence_rule'] = null;
      json['exception_dates'] = null;
    } else if (recurrenceRule != null) {
      json['recurrence_rule'] = recurrenceRule;
    }

    return json;
  }
}

class HomeworkRequestModel {
  final String title;
  final bool allDay;
  final bool showEndTime;
  final String start; // ISO 8601 format
  final String? end; // ISO 8601 format
  final int priority;
  final String? url;
  final String? comments;
  final String? currentGrade;
  final bool completed;
  final int? category;
  final List<int>? materials;
  final int course;

  HomeworkRequestModel({
    required this.title,
    required this.allDay,
    required this.showEndTime,
    required this.start,
    this.end,
    required this.priority,
    this.url,
    this.comments,
    this.currentGrade,
    required this.completed,
    this.category,
    this.materials,
    required this.course,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'title': title,
      'all_day': allDay,
      'show_end_time': showEndTime,
      'start': start,
      'priority': priority,
      'completed': completed,
      'course': course,
    };

    // Only include optional fields when present to avoid sending explicit nulls
    if (end != null && end!.isNotEmpty) {
      data['end'] = end;
    }
    // current_grade is always required by backend: -1/100 when not completed, or user input when completed
    if (currentGrade != null && currentGrade!.isNotEmpty) {
      data['current_grade'] = currentGrade;
    }

    if (url != null && url!.isNotEmpty) data['url'] = url;
    if (comments != null && comments!.isNotEmpty) data['comments'] = comments;
    if (category != null) data['category'] = category;
    if (materials != null && materials!.isNotEmpty)
      data['materials'] = materials;

    return data;
  }
}

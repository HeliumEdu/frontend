class CourseGroupResponseModel {
  final int id;
  final String title;
  final String startDate;
  final String endDate;
  final bool shownOnCalendar;
  final double averageGrade;
  final int numDays;
  final int numDaysCompleted;

  CourseGroupResponseModel({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.shownOnCalendar,
    required this.averageGrade,
    required this.numDays,
    required this.numDaysCompleted,
  });

  factory CourseGroupResponseModel.fromJson(Map<String, dynamic> json) {
    // Parse average_grade safely (can be String or num)
    double parseAverageGrade(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          return 0.0;
        }
      }
      return 0.0;
    }

    return CourseGroupResponseModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      shownOnCalendar: json['shown_on_calendar'] ?? true,
      averageGrade: parseAverageGrade(json['average_grade']),
      numDays: json['num_days'] ?? 0,
      numDaysCompleted: json['num_days_completed'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'start_date': startDate,
      'end_date': endDate,
      'shown_on_calendar': shownOnCalendar,
      'average_grade': averageGrade,
      'num_days': numDays,
      'num_days_completed': numDaysCompleted,
    };
  }
}

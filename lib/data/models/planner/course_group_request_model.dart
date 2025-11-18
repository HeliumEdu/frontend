class CourseGroupRequestModel {
  final String title;
  final String startDate;
  final String endDate;
  final bool shownOnCalendar;

  CourseGroupRequestModel({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.shownOnCalendar,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'start_date': startDate,
      'end_date': endDate,
      'shown_on_calendar': shownOnCalendar,
    };
  }
}

class CourseGroupRequestModel {
  final String title;
  final String startDate;
  final String endDate;
  final bool shownOnCalendar;

  final int? gradeScaleTemplate;

  CourseGroupRequestModel({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.shownOnCalendar,
    this.gradeScaleTemplate,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'start_date': startDate,
      'end_date': endDate,
      'shown_on_calendar': shownOnCalendar,
      if (gradeScaleTemplate != null)
        'grade_scale_template': gradeScaleTemplate,
    };
  }
}

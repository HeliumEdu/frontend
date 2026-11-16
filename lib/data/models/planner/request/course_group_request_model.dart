import 'package:heliumapp/utils/course_exception_helpers.dart';

class CourseGroupRequestModel {
  final String title;
  final String startDate;
  final String endDate;
  final bool shownOnCalendar;

  final int? gradeScaleTemplate;
  final List<DateTime> exceptions;

  CourseGroupRequestModel({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.shownOnCalendar,
    this.gradeScaleTemplate,
    this.exceptions = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'start_date': startDate,
      'end_date': endDate,
      'shown_on_calendar': shownOnCalendar,
      'exceptions': CourseExceptionHelpers.formatExceptionsCsv(exceptions),
      if (gradeScaleTemplate != null)
        'grade_scale_template': gradeScaleTemplate,
    };
  }
}

import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/utils/conversion_helpers.dart';
import 'package:heliumapp/utils/course_exception_helpers.dart';

class CourseGroupModel extends BaseTitledModel {
  final DateTime startDate;
  final DateTime endDate;
  final List<DateTime> exceptions;
  final double? overallGrade;

  CourseGroupModel({
    required super.id,
    required super.title,
    required super.shownOnCalendar,
    required this.startDate,
    required this.endDate,
    required this.exceptions,
    super.version,
    this.overallGrade,
  });

  factory CourseGroupModel.fromJson(Map<String, dynamic> json) {
    return CourseGroupModel(
      id: json['id'],
      version: json['updated_at'],
      title: json['title'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      shownOnCalendar: json['shown_on_calendar'],
      exceptions: CourseExceptionHelpers.parseCsvExceptions(
        json['exceptions'] as String,
      ),
      overallGrade: toDouble(json['overall_grade']),
    );
  }
}

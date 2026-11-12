import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/grade_scale_band_model.dart';
import 'package:heliumapp/utils/conversion_helpers.dart';
import 'package:heliumapp/utils/course_exception_helpers.dart';

class CourseGroupModel extends BaseTitledModel {
  final DateTime startDate;
  final DateTime endDate;
  final List<DateTime> exceptions;
  final double? overallGrade;
  final List<GradeScaleBandModel> gradeScale;
  final int? gradeScaleTemplate;
  final bool exampleSchedule;

  CourseGroupModel({
    required super.id,
    required super.title,
    required super.shownOnCalendar,
    required this.startDate,
    required this.endDate,
    required this.exceptions,
    super.version,
    this.overallGrade,
    required this.gradeScale,
    this.gradeScaleTemplate,
    required this.exampleSchedule,
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
      gradeScale: GradeScaleBandModel.listFromJson(json['grade_scale']),
      gradeScaleTemplate: json['grade_scale_template'],
      exampleSchedule: json['example_schedule'],
    );
  }
}

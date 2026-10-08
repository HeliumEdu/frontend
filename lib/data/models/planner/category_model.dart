import 'dart:ui';

import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/conversion_helpers.dart';

class CategoryModel extends BaseTitledModel {
  final Color color;
  final int course;
  final int courseGroup;
  final double weight;
  final double? averageGrade;
  final double? gradeByWeight;
  final double? trend;
  final int? numHomework;

  /// The raw `updated_at`, sent back as `If-Match` so a stale full edit is
  /// rejected instead of overwriting a change made elsewhere.
  final String? version;

  CategoryModel({
    this.version,
    required super.id,
    required super.title,
    super.shownOnCalendar,
    required this.color,
    required this.course,
    required this.courseGroup,
    required this.weight,
    this.averageGrade,
    this.gradeByWeight,
    this.trend,
    this.numHomework,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      version: json['updated_at'],
      title: json['title'],
      shownOnCalendar: json['shown_on_calendar'],
      color: HeliumColors.hexToColor(json['color']),
      course: json['course'],
      courseGroup: json['course_group'],
      weight: toDouble(json['weight'])!,
      averageGrade: toDouble(json['average_grade']),
      gradeByWeight: toDouble(json['grade_by_weight']),
      trend: toDouble(json['trend']),
      numHomework: toInt(json['num_homework']),
    );
  }
}

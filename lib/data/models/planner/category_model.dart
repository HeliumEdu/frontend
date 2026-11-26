import 'dart:ui';

import 'package:heliumapp/config/locale_notifier.dart';
import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/conversion_helpers.dart';

class CategoryModel extends BaseTitledModel {
  static const uncategorizedTitle = 'Uncategorized';

  final Color color;
  final int course;
  final int courseGroup;
  final double weight;
  final double? averageGrade;
  final double? gradeByWeight;
  final double? trend;
  final int? numHomework;

  CategoryModel({
    required super.id,
    required super.title,
    super.shownOnCalendar,
    required this.color,
    required this.course,
    required this.courseGroup,
    required this.weight,
    super.version,
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

  /// Whether this is the class's built-in category for assignments without one, which keeps its stored title.
  bool get isUncategorized => title == uncategorizedTitle;

  String get displayTitle => displayTitleOf(title);

  /// [title] as shown: the built-in category's in the user's language, any other as stored.
  static String displayTitleOf(String title) =>
      title == uncategorizedTitle ? LocaleNotifier().localizations.categoryUncategorizedTitle : title;
}

import 'package:heliumedu/data/models/planner/grade_category_model.dart';

class GradeCourseModel {
  final int id;
  final String title;
  final double overallGrade;
  final String color;
  final double? trend;
  final int numHomework;
  final int numHomeworkGraded;
  final List<List<dynamic>>
  gradePoints; // [["2025-10-09T17:00:00Z", 90.0], ...]
  final List<GradeCategoryModel> categories;

  GradeCourseModel({
    required this.id,
    required this.title,
    required this.overallGrade,
    required this.color,
    this.trend,
    required this.numHomework,
    required this.numHomeworkGraded,
    required this.gradePoints,
    required this.categories,
  });

  factory GradeCourseModel.fromJson(Map<String, dynamic> json) {
    return GradeCourseModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      overallGrade: (json['overall_grade'] as num?)?.toDouble() ?? -1.0,
      color: json['color'] as String? ?? '#000000',
      trend: (json['trend'] as num?)?.toDouble(),
      numHomework: json['num_homework'] as int? ?? 0,
      numHomeworkGraded: json['num_homework_graded'] as int? ?? 0,
      gradePoints:
          (json['grade_points'] as List<dynamic>?)
              ?.map((point) => point as List<dynamic>)
              .toList() ??
          [],
      categories:
          (json['categories'] as List<dynamic>?)
              ?.map(
                (category) => GradeCategoryModel.fromJson(
                  category as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'overall_grade': overallGrade,
      'color': color,
      'trend': trend,
      'num_homework': numHomework,
      'num_homework_graded': numHomeworkGraded,
      'grade_points': gradePoints,
      'categories': categories.map((c) => c.toJson()).toList(),
    };
  }

  // Check if grade is recorded
  bool get hasGrade => overallGrade >= 0;

  // Format grade as percentage string
  String get formattedGrade {
    if (!hasGrade) return 'N/A';
    return '${overallGrade.toStringAsFixed(2)}%';
  }

  // Get trend indicator
  String get trendIndicator {
    if (trend == null) return '';
    if (trend! > 0) return '↑';
    if (trend! < 0) return '↓';
    return '→';
  }
}

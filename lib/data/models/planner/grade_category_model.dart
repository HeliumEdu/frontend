// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class GradeCategoryModel {
  final int id;
  final String title;
  final double overallGrade;
  final double weight;
  final String color;
  final double gradeByWeight;
  final double? trend;
  final int numHomework;
  final int numHomeworkGraded;

  GradeCategoryModel({
    required this.id,
    required this.title,
    required this.overallGrade,
    required this.weight,
    required this.color,
    required this.gradeByWeight,
    this.trend,
    required this.numHomework,
    required this.numHomeworkGraded,
  });

  factory GradeCategoryModel.fromJson(Map<String, dynamic> json) {
    return GradeCategoryModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      overallGrade: (json['overall_grade'] as num?)?.toDouble() ?? -1.0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      color: json['color'] as String? ?? '#000000',
      gradeByWeight: (json['grade_by_weight'] as num?)?.toDouble() ?? 0.0,
      trend: (json['trend'] as num?)?.toDouble(),
      numHomework: json['num_homework'] as int? ?? 0,
      numHomeworkGraded: json['num_homework_graded'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'overall_grade': overallGrade,
      'weight': weight,
      'color': color,
      'grade_by_weight': gradeByWeight,
      'trend': trend,
      'num_homework': numHomework,
      'num_homework_graded': numHomeworkGraded,
    };
  }

  // Check if grade is recorded (overall_grade > 0)
  bool get hasGrade => overallGrade >= 0;

  // Format grade as percentage string
  String get formattedGrade {
    if (!hasGrade) return 'N/A';
    return '${overallGrade.toStringAsFixed(2)}%';
  }
}

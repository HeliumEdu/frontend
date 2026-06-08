// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class HomeworkSeriesItemModel {
  final int id;
  final String title;
  final DateTime start;
  final int categoryId;
  final int courseId;
  final double? pointsPossible;
  final bool graded;
  final double? homeworkGrade;
  final double? cumulativeGrade;
  final double? impactScore;

  HomeworkSeriesItemModel({
    required this.id,
    required this.title,
    required this.start,
    required this.categoryId,
    required this.courseId,
    this.pointsPossible,
    required this.graded,
    this.homeworkGrade,
    this.cumulativeGrade,
    this.impactScore,
  });

  factory HomeworkSeriesItemModel.fromJson(Map<String, dynamic> json) {
    return HomeworkSeriesItemModel(
      id: json['id'],
      title: json['title'],
      start: DateTime.parse(json['start']),
      categoryId: json['category_id'],
      courseId: json['course_id'],
      pointsPossible: (json['points_possible'] as num?)?.toDouble(),
      graded: json['graded'],
      homeworkGrade: (json['homework_grade'] as num?)?.toDouble(),
      cumulativeGrade: (json['cumulative_grade'] as num?)?.toDouble(),
      impactScore: (json['impact_score'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'start': start.toIso8601String(),
      'category_id': categoryId,
      'course_id': courseId,
      'points_possible': pointsPossible,
      'graded': graded,
      'homework_grade': homeworkGrade,
      'cumulative_grade': cumulativeGrade,
      'impact_score': impactScore,
    };
  }
}

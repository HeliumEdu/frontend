// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:ui';

import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/grade_category_model.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/conversion_helpers.dart';

class GradeCourseModel extends BaseTitledModel {
  final double overallGrade;
  final Color color;
  final double? trend;
  final int numHomework;
  final int numHomeworkCompleted;
  final int numHomeworkGraded;
  final List<List<dynamic>> gradePoints;
  final List<GradeCategoryModel> categories;

  GradeCourseModel({
    required super.id,
    required super.title,
    required this.overallGrade,
    required this.color,
    this.trend,
    required this.numHomework,
    required this.numHomeworkCompleted,
    required this.numHomeworkGraded,
    required this.gradePoints,
    required this.categories,
  });

  factory GradeCourseModel.fromJson(Map<String, dynamic> json) {
    return GradeCourseModel(
      id: json['id'],
      title: json['title'],
      overallGrade: HeliumConversion.toDouble(json['overall_grade'])!,
      color: HeliumColors.hexToColor(json['color']),
      trend: (json['trend'] as num?)?.toDouble(),
      numHomework: json['num_homework'],
      numHomeworkCompleted: json['num_homework_completed'],
      numHomeworkGraded: json['num_homework_graded'],
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
      'num_homework_completed': numHomeworkCompleted,
      'num_homework_graded': numHomeworkGraded,
      'grade_points': gradePoints,
      'categories': categories.map((c) => c.toJson()).toList(),
    };
  }
}

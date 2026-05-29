// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:ui';

import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/homework_series_item_model.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/conversion_helpers.dart';

class GradeCategoryModel extends BaseTitledModel {
  final double overallGrade;
  final double weight;
  final Color color;
  final double? gradeByWeight;
  final double? trend;
  final int numHomework;
  final int numHomeworkGraded;
  final List<HomeworkSeriesItemModel> homeworkSeries;

  GradeCategoryModel({
    required super.id,
    required super.title,
    required this.overallGrade,
    required this.weight,
    required this.color,
    required this.gradeByWeight,
    this.trend,
    required this.numHomework,
    required this.numHomeworkGraded,
    required this.homeworkSeries,
  });

  factory GradeCategoryModel.fromJson(Map<String, dynamic> json) {
    return GradeCategoryModel(
      id: json['id'],
      title: json['title'],
      overallGrade: toDouble(json['overall_grade'])!,
      weight: toDouble(json['weight'])!,
      color: HeliumColors.hexToColor(json['color']),
      gradeByWeight: toDouble(json['grade_by_weight']),
      trend: toDouble(json['trend']),
      numHomework: json['num_homework'],
      numHomeworkGraded: json['num_homework_graded'],
      homeworkSeries:
          (json['homework_series'] as List<dynamic>?)
              ?.map(
                (item) => HomeworkSeriesItemModel.fromJson(
                  item as Map<String, dynamic>,
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
      'weight': weight,
      'color': color,
      'grade_by_weight': gradeByWeight,
      'trend': trend,
      'num_homework': numHomework,
      'num_homework_graded': numHomeworkGraded,
      'homework_series': homeworkSeries.map((item) => item.toJson()).toList(),
    };
  }
}

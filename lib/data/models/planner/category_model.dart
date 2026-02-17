// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:ui';

import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/conversion_helpers.dart';

class CategoryModel extends BaseTitledModel {
  final Color color;
  final int course;
  final double weight;
  final double? overallGrade;
  final double? gradeByWeight;
  final double? trend;
  final int? numHomework;

  CategoryModel({
    required super.id,
    required super.title,
    super.shownOnCalendar,
    required this.color,
    required this.course,
    required this.weight,
    this.overallGrade,
    this.gradeByWeight,
    this.trend,
    this.numHomework,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      title: json['title'],
      shownOnCalendar: json['shown_on_calendar'],
      color: HeliumColors.hexToColor(json['color']),
      course: json['course'],
      weight: HeliumConversion.toDouble(json['weight'])!,
      overallGrade: HeliumConversion.toDouble(json['overall_grade']),
      gradeByWeight: HeliumConversion.toDouble(json['grade_by_weight']),
      trend: HeliumConversion.toDouble(json['trend']),
      numHomework: HeliumConversion.toInt(json['num_homework']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'color': color,
      'course': course,
      'weight': weight,
      'overall_grade': overallGrade,
      'grade_by_weight': gradeByWeight,
      'trend': trend,
      'num_homework': numHomework,
    };
  }
}

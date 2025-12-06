// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';

class CategoryModel {
  final int id;
  final String title;
  final String color;
  final int course;
  final double? weight;
  final double? overallGrade;
  final double? gradeByWeight;
  final double? trend;
  final int numHomeworkGraded;

  CategoryModel({
    required this.id,
    required this.title,
    required this.color,
    required this.course,
    this.weight,
    this.overallGrade,
    this.gradeByWeight,
    this.trend,
    required this.numHomeworkGraded,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return CategoryModel(
      id: toInt(json['id']),
      title: json['title'] ?? '',
      color: json['color'] ?? '#3f51b5',
      course: toInt(json['course']),
      weight: toDouble(json['weight']),
      overallGrade: toDouble(json['overall_grade']),
      gradeByWeight: toDouble(json['grade_by_weight']),
      trend: toDouble(json['trend']),
      numHomeworkGraded: toInt(json['num_homework_graded']),
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
      'num_homework_graded': numHomeworkGraded,
    };
  }

  // Helper method to check if category has a valid grade
  bool hasGrade() {
    return overallGrade != null && overallGrade! >= 0;
  }

  // Helper method to get formatted grade
  String getFormattedGrade() {
    if (!hasGrade()) return 'N/A';
    return '${overallGrade!.toStringAsFixed(2)}%';
  }

  // Helper method to get color as Color object
  Color getColor() {
    try {
      final colorValue = int.parse(color.replaceFirst('#', 'ff'), radix: 16);
      return Color(colorValue);
    } catch (e) {
      return const Color(0xff3F51B5); // Default blue color
    }
  }
}

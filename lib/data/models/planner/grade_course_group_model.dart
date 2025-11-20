// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumedu/data/models/planner/grade_course_model.dart';

class GradeCourseGroupModel {
  final int id;
  final String title;
  final double overallGrade;
  final List<List<dynamic>>
  gradePoints; // [["2025-10-09T17:00:00Z", 90.0], ...]
  final List<GradeCourseModel> courses;
  final String startDate;
  final String endDate;

  GradeCourseGroupModel({
    required this.id,
    required this.title,
    required this.overallGrade,
    required this.gradePoints,
    required this.courses,
    required this.startDate,
    required this.endDate,
  });

  factory GradeCourseGroupModel.fromJson(Map<String, dynamic> json) {
    return GradeCourseGroupModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      overallGrade: (json['overall_grade'] as num?)?.toDouble() ?? -1.0,
      gradePoints:
          (json['grade_points'] as List<dynamic>?)
              ?.map((point) => point as List<dynamic>)
              .toList() ??
          [],
      courses:
          (json['courses'] as List<dynamic>?)
              ?.map(
                (course) =>
                    GradeCourseModel.fromJson(course as Map<String, dynamic>),
              )
              .toList() ??
          [],
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'overall_grade': overallGrade,
      'grade_points': gradePoints,
      'courses': courses.map((c) => c.toJson()).toList(),
      'start_date': startDate,
      'end_date': endDate,
    };
  }

  // Check if grade is recorded
  bool get hasGrade => overallGrade >= 0;

  // Format grade as percentage string
  String get formattedGrade {
    if (!hasGrade) return 'N/A';
    return '${overallGrade.toStringAsFixed(2)}%';
  }

  // Get total number of graded homework across all courses
  int get totalGradedHomework {
    return courses.fold(0, (sum, course) => sum + course.numHomeworkGraded);
  }

  // Calculate percentage of days completed through the term
  // Returns 0-100 representing how far through the term we are
  int getThruTermPercentage() {
    if (startDate.isEmpty || endDate.isEmpty) {
      return 0;
    }

    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      final now = DateTime.now();

      // If before start date, return 0%
      if (now.isBefore(start)) {
        return 0;
      }

      // If after end date, return 100%
      if (now.isAfter(end)) {
        return 100;
      }

      // Calculate percentage
      final totalDays = end.difference(start).inDays;
      if (totalDays <= 0) {
        return 0;
      }

      final daysElapsed = now.difference(start).inDays;
      final percentage = (daysElapsed / totalDays * 100).round();

      // Clamp between 0 and 100
      if (percentage < 0) return 0;
      if (percentage > 100) return 100;
      return percentage;
    } catch (e) {
      // If date parsing fails, return 0
      return 0;
    }
  }
}

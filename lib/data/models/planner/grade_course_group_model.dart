// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/grade_course_model.dart';
import 'package:heliumapp/utils/conversion_helpers.dart';

class GradeCourseGroupModel extends BaseTitledModel {
  final double overallGrade;
  final List<List<dynamic>> gradePoints;
  final List<GradeCourseModel> courses;
  final int numHomework;
  final int numHomeworkCompleted;
  final int numHomeworkGraded;

  GradeCourseGroupModel({
    required super.id,
    required super.title,
    required this.overallGrade,
    required this.gradePoints,
    required this.courses,
    required this.numHomework,
    required this.numHomeworkCompleted,
    required this.numHomeworkGraded,
  });

  factory GradeCourseGroupModel.fromJson(Map<String, dynamic> json) {
    return GradeCourseGroupModel(
      id: json['id'],
      title: json['title'],
      overallGrade: toDouble(json['overall_grade'])!,
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
      numHomework: json['num_homework'],
      numHomeworkCompleted: json['num_homework_completed'],
      numHomeworkGraded: json['num_homework_graded'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'overall_grade': overallGrade,
      'grade_points': gradePoints,
      'courses': courses.map((c) => c.toJson()).toList(),
      'num_homework': numHomework,
      'num_homework_completed': numHomeworkCompleted,
      'num_homework_graded': numHomeworkGraded,
    };
  }
}

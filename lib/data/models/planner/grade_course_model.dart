// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:ui';

import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/grade_category_model.dart';
import 'package:heliumapp/data/models/planner/homework_series_item_model.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/conversion_helpers.dart';

class GradeCourseModel extends BaseTitledModel {
  final double overallGrade;
  final Color color;
  final double? trend;
  final int numHomework;
  final int numHomeworkCompleted;
  final int numHomeworkGraded;
  final List<GradeCategoryModel> categories;
  final List<HomeworkSeriesItemModel> homeworkSeries;

  GradeCourseModel({
    required super.id,
    required super.title,
    required this.overallGrade,
    required this.color,
    this.trend,
    required this.numHomework,
    required this.numHomeworkCompleted,
    required this.numHomeworkGraded,
    required this.categories,
    required this.homeworkSeries,
  });

  List<HomeworkSeriesItemModel> get ungradedAssignments {
    final ungraded = homeworkSeries.where((item) => !item.graded).toList();
    ungraded.sort((a, b) {
      final aImpact = a.impactScore;
      final bImpact = b.impactScore;
      if (aImpact != null && bImpact != null) {
        final cmp = bImpact.compareTo(aImpact);
        if (cmp != 0) return cmp;
      } else if (aImpact != null) {
        return -1;
      } else if (bImpact != null) {
        return 1;
      }
      return a.start.compareTo(b.start);
    });
    return ungraded;
  }

  factory GradeCourseModel.fromJson(Map<String, dynamic> json) {
    return GradeCourseModel(
      id: json['id'],
      title: json['title'],
      overallGrade: toDouble(json['overall_grade'])!,
      color: HeliumColors.hexToColor(json['color']),
      trend: (json['trend'] as num?)?.toDouble(),
      numHomework: json['num_homework'],
      numHomeworkCompleted: json['num_homework_completed'],
      numHomeworkGraded: json['num_homework_graded'],
      categories:
          (json['categories'] as List<dynamic>?)
              ?.map(
                (category) => GradeCategoryModel.fromJson(
                  category as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
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
      'color': color,
      'trend': trend,
      'num_homework': numHomework,
      'num_homework_completed': numHomeworkCompleted,
      'num_homework_graded': numHomeworkGraded,
      'categories': categories.map((c) => c.toJson()).toList(),
      'homework_series': homeworkSeries.map((item) => item.toJson()).toList(),
    };
  }
}

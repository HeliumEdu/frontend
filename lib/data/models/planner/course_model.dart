// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:ui';

import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/conversion_helpers.dart';

class CourseModel extends BaseTitledModel {
  final DateTime startDate;
  final DateTime endDate;
  final String room;
  final double credits;
  final Color color;
  final String website;
  final bool isOnline;
  final int courseGroup;
  final String teacherName;
  final String teacherEmail;
  final double? currentGrade;
  final List<CourseScheduleModel> schedules;
  final double? trend;
  final int? numDays;
  final int? numDaysCompleted;
  final bool? hasWeightedGrading;
  final int? numHomework;
  final int? numHomeworkCompleted;
  final int? numHomeworkGraded;

  CourseModel({
    required super.id,
    required super.title,
    required this.startDate,
    required this.endDate,
    required this.room,
    required this.credits,
    required this.color,
    required this.website,
    required this.isOnline,
    required this.courseGroup,
    required this.teacherName,
    required this.teacherEmail,
    required this.currentGrade,
    required this.schedules,
    this.trend,
    this.numDays,
    this.numDaysCompleted,
    this.hasWeightedGrading,
    this.numHomework,
    this.numHomeworkCompleted,
    this.numHomeworkGraded,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'],
      title: json['title'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      room: json['room'],
      credits: HeliumConversion.toDouble(json['credits'])!,
      color: HeliumColors.hexToColor(json['color']),
      website: json['website'],
      isOnline: json['is_online'],
      courseGroup: json['course_group'],
      teacherName: json['teacher_name'],
      teacherEmail: json['teacher_email'],
      schedules:
          (json['schedules'] as List<dynamic>?)
              ?.map((schedule) => CourseScheduleModel.fromJson(schedule))
              .toList() ??
          [],
      currentGrade: HeliumConversion.toDouble(json['current_grade']),
      trend: HeliumConversion.toDouble(json['trend']),
      numDays: json['num_days'],
      numDaysCompleted: json['num_days_completed'],
      hasWeightedGrading: json['has_weighted_grading'],
      numHomework: json['num_homework'],
      numHomeworkCompleted: json['num_homework_completed'],
      numHomeworkGraded: json['num_homework_graded'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'room': room,
      'credits': credits,
      'color': color,
      'website': website,
      'is_online': isOnline,
      'course_group': courseGroup,
      'teacher_name': teacherName,
      'teacher_email': teacherEmail,
      'current_grade': currentGrade,
      'schedules': schedules.map((schedule) => schedule.toJson()).toList(),
      'trend': trend,
      'num_days': numDays,
      'num_days_completed': numDaysCompleted,
      'has_weighted_grading': hasWeightedGrading,
      'num_homework': numHomework,
      'num_homework_completed': numHomeworkCompleted,
      'num_homework_graded': numHomeworkGraded,
    };
  }
}

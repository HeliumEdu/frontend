// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumedu/data/models/planner/course_schedule_model.dart';

class CourseModel {
  final int id;
  final String title;
  final String room;
  final String credits;
  final String color;
  final String website;
  final bool isOnline;
  final String currentGrade;
  final double? trend;
  final String teacherName;
  final String teacherEmail;
  final String startDate;
  final String endDate;
  final List<CourseScheduleModel> schedules;
  final int courseGroup;
  final int numDays;
  final int numDaysCompleted;
  final bool hasWeightedGrading;
  final int numHomework;
  final int numHomeworkCompleted;
  final int numHomeworkGraded;

  CourseModel({
    required this.id,
    required this.title,
    required this.room,
    required this.credits,
    required this.color,
    required this.website,
    required this.isOnline,
    required this.currentGrade,
    this.trend,
    required this.teacherName,
    required this.teacherEmail,
    required this.startDate,
    required this.endDate,
    required this.schedules,
    required this.courseGroup,
    required this.numDays,
    required this.numDaysCompleted,
    required this.hasWeightedGrading,
    required this.numHomework,
    required this.numHomeworkCompleted,
    required this.numHomeworkGraded,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      room: json['room'] ?? '',
      credits: json['credits'] ?? '0.00',
      color: json['color'] ?? '#cabdbf',
      website: json['website'] ?? '',
      isOnline: json['is_online'] ?? false,
      currentGrade: json['current_grade'] ?? '-1.0000',
      trend: json['trend'] != null ? (json['trend'] as num).toDouble() : null,
      teacherName: json['teacher_name'] ?? '',
      teacherEmail: json['teacher_email'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      schedules:
          (json['schedules'] as List<dynamic>?)
              ?.map((schedule) => CourseScheduleModel.fromJson(schedule))
              .toList() ??
          [],
      courseGroup: json['course_group'] ?? 0,
      numDays: json['num_days'] ?? 0,
      numDaysCompleted: json['num_days_completed'] ?? 0,
      hasWeightedGrading: json['has_weighted_grading'] ?? false,
      numHomework: json['num_homework'] ?? 0,
      numHomeworkCompleted: json['num_homework_completed'] ?? 0,
      numHomeworkGraded: json['num_homework_graded'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'room': room,
      'credits': credits,
      'color': color,
      'website': website,
      'is_online': isOnline,
      'current_grade': currentGrade,
      'trend': trend,
      'teacher_name': teacherName,
      'teacher_email': teacherEmail,
      'start_date': startDate,
      'end_date': endDate,
      'schedules': schedules.map((schedule) => schedule.toJson()).toList(),
      'course_group': courseGroup,
      'num_days': numDays,
      'num_days_completed': numDaysCompleted,
      'has_weighted_grading': hasWeightedGrading,
      'num_homework': numHomework,
      'num_homework_completed': numHomeworkCompleted,
      'num_homework_graded': numHomeworkGraded,
    };
  }

  // Helper method to get formatted date range
  String getFormattedDateRange() {
    if (startDate.isEmpty || endDate.isEmpty) {
      return 'No dates set';
    }

    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);

      return '${_formatDate(start)} to ${_formatDate(end)}';
    } catch (e) {
      return '$startDate to $endDate';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // Helper to check if course has grade
  bool hasGrade() {
    return currentGrade != '-1.0000' && currentGrade.isNotEmpty;
  }

  // Helper to get formatted grade
  String getFormattedGrade() {
    if (!hasGrade()) {
      return '';
    }
    try {
      final grade = double.parse(currentGrade);
      return '${grade.toStringAsFixed(2)}%';
    } catch (e) {
      return '';
    }
  }
}

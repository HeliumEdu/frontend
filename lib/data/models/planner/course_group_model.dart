// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/utils/conversion_helpers.dart';

class CourseGroupModel extends BaseTitledModel {
  final String startDate;
  final String endDate;
  final double? averageGrade;
  final int? numDays;
  final int? numDaysCompleted;

  CourseGroupModel({
    required super.id,
    required super.title,
    required super.shownOnCalendar,
    required this.startDate,
    required this.endDate,
    this.averageGrade,
    this.numDays,
    this.numDaysCompleted,
  });

  factory CourseGroupModel.fromJson(Map<String, dynamic> json) {
    return CourseGroupModel(
      id: json['id'],
      title: json['title'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      shownOnCalendar: json['shown_on_calendar'],
      averageGrade: HeliumConversion.toDouble(json['average_grade']),
      numDays: json['num_days'],
      numDaysCompleted: json['num_days_completed'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'start_date': startDate,
      'end_date': endDate,
      'shown_on_calendar': shownOnCalendar,
      'average_grade': averageGrade,
      'num_days': numDays,
      'num_days_completed': numDaysCompleted,
    };
  }
}

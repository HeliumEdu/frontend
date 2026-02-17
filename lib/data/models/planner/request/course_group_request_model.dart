// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class CourseGroupRequestModel {
  final String title;
  final String startDate;
  final String endDate;
  final bool shownOnCalendar;

  CourseGroupRequestModel({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.shownOnCalendar,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'start_date': startDate,
      'end_date': endDate,
      'shown_on_calendar': shownOnCalendar,
    };
  }
}

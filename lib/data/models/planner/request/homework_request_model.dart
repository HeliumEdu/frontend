// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class HomeworkRequestModel {
  final int course;
  final String? title;
  final bool? allDay;
  final bool? showEndTime;
  final String? start;
  final String? end;
  final int? priority;
  final String? comments;
  final String? currentGrade;
  final bool? completed;
  final int? category;
  final List<int>? resources;

  HomeworkRequestModel({
    required this.course,
    this.title,
    this.allDay,
    this.showEndTime,
    this.start,
    this.end,
    this.priority,
    this.comments,
    this.currentGrade,
    this.completed,
    this.category,
    this.resources,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'course': course};

    if (title != null) json['title'] = title;
    if (allDay != null) json['all_day'] = allDay;
    if (showEndTime != null) json['show_end_time'] = showEndTime;
    if (start != null) json['start'] = start;
    if (end != null) json['end'] = end;
    if (priority != null) json['priority'] = priority;
    if (currentGrade != null) json['current_grade'] = currentGrade;
    if (completed != null) json['completed'] = completed;
    if (category != null) json['category'] = category;
    if (resources != null) json['materials'] = resources;

    return json;
  }
}

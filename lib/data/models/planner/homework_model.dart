// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/id_or_entity.dart';
import 'package:heliumapp/data/models/planner/attachment_model.dart';
import 'package:heliumapp/data/models/planner/calendar_item_base_model.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/resource_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/conversion_helpers.dart';

class HomeworkModel extends CalendarItemBaseModel {
  final bool completed;
  final IdOrEntity<CourseModel> course;
  final IdOrEntity<CategoryModel> category;
  final List<IdOrEntity<ResourceModel>> resources;
  final String? currentGrade;

  HomeworkModel({
    required super.id,
    required super.title,
    required super.allDay,
    required super.showEndTime,
    required super.start,
    required super.end,
    required super.priority,
    required super.comments,
    required super.attachments,
    required super.reminders,
    required this.completed,
    required this.course,
    required this.resources,
    required this.category,
    this.currentGrade,
  }) : super(calendarItemType: CalendarItemType.homework);

  factory HomeworkModel.fromJson(Map<String, dynamic> json) {
    return HomeworkModel(
      id: json['id'],
      title: json['title'],
      allDay: json['all_day'],
      showEndTime: json['show_end_time'],
      start: DateTime.parse(json['start']),
      end: DateTime.parse(json['end']),
      priority: json['priority'],
      comments: json['comments'],
      attachments: json['attachments'] != null
          ? HeliumConversion.idOrEntityListFrom(
              json['attachments'],
              AttachmentModel.fromJson,
            )
          : [],
      reminders: json['reminders'] != null
          ? HeliumConversion.idOrEntityListFrom(
              json['reminders'],
              ReminderModel.fromJson,
            )
          : [],
      currentGrade: json['current_grade'],
      completed: json['completed'],
      category: HeliumConversion.idOrEntityFrom(
        json['category'],
        CategoryModel.fromJson,
      ),
      resources: json['materials'] != null
          ? HeliumConversion.idOrEntityListFrom(
              json['materials'],
              ResourceModel.fromJson,
            )
          : [],
      course: HeliumConversion.idOrEntityFrom(
        json['course'],
        CourseModel.fromJson,
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();

    data['completed'] = completed;
    data['course'] = course;
    data['category'] = category;
    data['materials'] = resources;
    data['current_grade'] = currentGrade;

    return data;
  }

  HomeworkModel copyWith({
    int? id,
    String? title,
    bool? allDay,
    bool? showEndTime,
    DateTime? start,
    DateTime? end,
    int? priority,
    String? comments,
    List<IdOrEntity<AttachmentModel>>? attachments,
    List<IdOrEntity<ReminderModel>>? reminders,
    bool? completed,
    IdOrEntity<CourseModel>? course,
    IdOrEntity<CategoryModel>? category,
    List<IdOrEntity<ResourceModel>>? resources,
    String? currentGrade,
  }) {
    return HomeworkModel(
      id: id ?? this.id,
      title: title ?? this.title,
      allDay: allDay ?? this.allDay,
      showEndTime: showEndTime ?? this.showEndTime,
      start: start ?? this.start,
      end: end ?? this.end,
      priority: priority ?? this.priority,
      comments: comments ?? this.comments,
      attachments: attachments ?? this.attachments,
      reminders: reminders ?? this.reminders,
      completed: completed ?? this.completed,
      course: course ?? this.course,
      category: category ?? this.category,
      resources: resources ?? this.resources,
      currentGrade: currentGrade ?? this.currentGrade,
    );
  }
}

// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumedu/data/models/planner/attachment_model.dart';
import 'package:heliumedu/data/models/planner/reminder_response_model.dart';

class EventResponseModel {
  final int id;
  final String title;
  final bool allDay;
  final bool showEndTime;
  final String start;
  final String? end;
  final int priority;
  final String? url;
  final String? comments;
  final String? ownerId;
  final List<AttachmentModel> attachments;
  final List<ReminderResponseModel> reminders;
  final int userId;
  final int? calendarItemType;
  final String? colorHex;
  final int? courseId;
  final int? courseScheduleId;
  final String? courseTitle;

  EventResponseModel({
    required this.id,
    required this.title,
    required this.allDay,
    required this.showEndTime,
    required this.start,
    this.end,
    required this.priority,
    this.url,
    this.comments,
    this.ownerId,
    required this.attachments,
    required this.reminders,
    required this.userId,
    this.calendarItemType,
    this.colorHex,
    this.courseId,
    this.courseScheduleId,
    this.courseTitle,
  });

  factory EventResponseModel.fromJson(Map<String, dynamic> json) {
    // Parse attachments - handle both object array and ID array
    List<AttachmentModel> attachmentsList = [];
    if (json['attachments'] != null) {
      final attachmentsData = json['attachments'] as List;
      for (var item in attachmentsData) {
        // Check if it's an object (Map) or just an ID (int)
        if (item is Map<String, dynamic>) {
          attachmentsList.add(AttachmentModel.fromJson(item));
        } else if (item is int) {
          // API returned just IDs, skip parsing or create placeholder
          print('⚠️ Attachment returned as ID: $item (not full object)');
        }
      }
    }

    // Parse reminders - handle both object array and ID array
    List<ReminderResponseModel> remindersList = [];
    if (json['reminders'] != null) {
      final remindersData = json['reminders'] as List;
      for (var item in remindersData) {
        // Check if it's an object (Map) or just an ID (int)
        if (item is Map<String, dynamic>) {
          remindersList.add(ReminderResponseModel.fromJson(item));
        } else if (item is int) {
          // API returned just IDs, skip parsing or create placeholder
          print('⚠️ Reminder returned as ID: $item (not full object)');
        }
      }
    }

    final parsedCourse = _parseCourse(json['course']);
    final parsedSchedule = _parseCourseSchedule(json['course_schedule']);
    final effectiveCourseId = parsedCourse.id ?? parsedSchedule.courseId;
    final effectiveCourseTitle =
        parsedCourse.title ?? parsedSchedule.courseTitle;

    return EventResponseModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      allDay: json['all_day'] ?? false,
      showEndTime: json['show_end_time'] ?? false,
      start: json['start'] ?? '',
      end: json['end'],
      priority: json['priority'] ?? 0,
      url: json['url'],
      comments: json['comments'],
      ownerId: json['owner_id'],
      attachments: attachmentsList,
      reminders: remindersList,
      userId: json['user'] ?? 0,
      calendarItemType: json['calendar_item_type'],
      colorHex: json['color'],
      courseId: effectiveCourseId,
      courseScheduleId: parsedSchedule.id,
      courseTitle: effectiveCourseTitle,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'title': title,
      'all_day': allDay,
      'show_end_time': showEndTime,
      'start': start,
      'priority': priority,
      'user': userId,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'reminders': reminders.map((r) => r.toJson()).toList(),
    };

    if (end != null) data['end'] = end;
    if (url != null) data['url'] = url;
    if (comments != null) data['comments'] = comments;
    if (ownerId != null) data['owner_id'] = ownerId;
    if (calendarItemType != null) data['calendar_item_type'] = calendarItemType;
    if (colorHex != null) data['color_hex'] = colorHex;
    if (courseId != null) data['course'] = courseId;
    if (courseScheduleId != null) data['course_schedule'] = courseScheduleId;

    return data;
  }

  static _ParsedCourse _parseCourse(dynamic courseData) {
    if (courseData == null) {
      return const _ParsedCourse();
    }

    if (courseData is int) {
      return _ParsedCourse(id: courseData);
    }

    if (courseData is String) {
      final parsedId = int.tryParse(courseData);
      return _ParsedCourse(id: parsedId);
    }

    if (courseData is Map<String, dynamic>) {
      final idValue = courseData['id'];
      final nameValue = courseData['title'] ?? courseData['name'];
      final parsedId = idValue is int
          ? idValue
          : (idValue is String ? int.tryParse(idValue) : null);
      return _ParsedCourse(id: parsedId, title: nameValue?.toString());
    }

    return const _ParsedCourse();
  }

  static _ParsedCourseSchedule _parseCourseSchedule(dynamic scheduleData) {
    if (scheduleData == null) {
      return const _ParsedCourseSchedule();
    }

    if (scheduleData is int) {
      return _ParsedCourseSchedule(id: scheduleData);
    }

    if (scheduleData is String) {
      final parsedId = int.tryParse(scheduleData);
      return _ParsedCourseSchedule(id: parsedId);
    }

    if (scheduleData is Map<String, dynamic>) {
      final idValue = scheduleData['id'];
      final courseValue = scheduleData['course'];
      final courseTitle = scheduleData['course_title'] ?? scheduleData['title'];

      final parsedId = idValue is int
          ? idValue
          : (idValue is String ? int.tryParse(idValue) : null);

      final parsedCourseId = courseValue is int
          ? courseValue
          : (courseValue is String ? int.tryParse(courseValue) : null);

      return _ParsedCourseSchedule(
        id: parsedId,
        courseId: parsedCourseId,
        courseTitle: courseTitle?.toString(),
      );
    }

    return const _ParsedCourseSchedule();
  }
}

class _ParsedCourse {
  final int? id;
  final String? title;

  const _ParsedCourse({this.id, this.title});
}

class _ParsedCourseSchedule {
  final int? id;
  final int? courseId;
  final String? courseTitle;

  const _ParsedCourseSchedule({this.id, this.courseId, this.courseTitle});
}

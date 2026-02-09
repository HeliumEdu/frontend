// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/attachment_model.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/data/models/planner/request/course_schedule_request_model.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/request/external_calendar_request_model.dart';
import 'package:heliumapp/data/models/planner/grade_course_group_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/material_group_model.dart';
import 'package:heliumapp/data/models/planner/material_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/utils/color_helpers.dart';

// ============================================================================
// GIVEN: Course Group JSON Fixtures
// ============================================================================

/// Creates JSON data representing a course group.
Map<String, dynamic> givenCourseGroupJson({
  int id = 1,
  String title = '🍂 Fall 2025',
  String startDate = '2025-08-25',
  String endDate = '2025-12-15',
  bool shownOnCalendar = true,
  double? averageGrade,
  int? numDays = 112,
  int? numDaysCompleted = 50,
}) {
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

/// Verifies that a [CourseGroupModel] matches the expected JSON data.
void verifyCourseGroupMatchesJson(
  CourseGroupModel courseGroup,
  Map<String, dynamic> json,
) {
  expect(courseGroup.id, equals(json['id']));
  expect(courseGroup.title, equals(json['title']));
  expect(courseGroup.startDate, equals(DateTime.parse(json['start_date'] as String)));
  expect(courseGroup.endDate, equals(DateTime.parse(json['end_date'] as String)));
  expect(courseGroup.shownOnCalendar, equals(json['shown_on_calendar']));
  expect(courseGroup.averageGrade, equals(json['average_grade']));
  expect(courseGroup.numDays, equals(json['num_days']));
  expect(courseGroup.numDaysCompleted, equals(json['num_days_completed']));
}

// ============================================================================
// GIVEN: Course Schedule JSON Fixtures
// ============================================================================

/// Creates JSON data representing a course schedule.
Map<String, dynamic> givenCourseScheduleJson({
  int id = 1,
  String daysOfWeek = '0101010',
  String sunStartTime = '00:00:00',
  String sunEndTime = '00:00:00',
  String monStartTime = '09:00:00',
  String monEndTime = '10:30:00',
  String tueStartTime = '00:00:00',
  String tueEndTime = '00:00:00',
  String wedStartTime = '09:00:00',
  String wedEndTime = '10:30:00',
  String thuStartTime = '00:00:00',
  String thuEndTime = '00:00:00',
  String friStartTime = '09:00:00',
  String friEndTime = '10:30:00',
  String satStartTime = '00:00:00',
  String satEndTime = '00:00:00',
  int course = 1,
}) {
  return {
    'id': id,
    'days_of_week': daysOfWeek,
    'sun_start_time': sunStartTime,
    'sun_end_time': sunEndTime,
    'mon_start_time': monStartTime,
    'mon_end_time': monEndTime,
    'tue_start_time': tueStartTime,
    'tue_end_time': tueEndTime,
    'wed_start_time': wedStartTime,
    'wed_end_time': wedEndTime,
    'thu_start_time': thuStartTime,
    'thu_end_time': thuEndTime,
    'fri_start_time': friStartTime,
    'fri_end_time': friEndTime,
    'sat_start_time': satStartTime,
    'sat_end_time': satEndTime,
    'course': course,
  };
}

/// Verifies that a [CourseScheduleModel] matches the expected JSON data.
void verifyCourseScheduleMatchesJson(
  CourseScheduleModel schedule,
  Map<String, dynamic> json,
) {
  expect(schedule.id, equals(json['id']));
  expect(schedule.daysOfWeek, equals(json['days_of_week']));
  expect(schedule.sunStartTime, equals(HeliumTime.parse(json['sun_start_time'] as String)));
  expect(schedule.sunEndTime, equals(HeliumTime.parse(json['sun_end_time'] as String)));
  expect(schedule.monStartTime, equals(HeliumTime.parse(json['mon_start_time'] as String)));
  expect(schedule.monEndTime, equals(HeliumTime.parse(json['mon_end_time'] as String)));
  expect(schedule.tueStartTime, equals(HeliumTime.parse(json['tue_start_time'] as String)));
  expect(schedule.tueEndTime, equals(HeliumTime.parse(json['tue_end_time'] as String)));
  expect(schedule.wedStartTime, equals(HeliumTime.parse(json['wed_start_time'] as String)));
  expect(schedule.wedEndTime, equals(HeliumTime.parse(json['wed_end_time'] as String)));
  expect(schedule.thuStartTime, equals(HeliumTime.parse(json['thu_start_time'] as String)));
  expect(schedule.thuEndTime, equals(HeliumTime.parse(json['thu_end_time'] as String)));
  expect(schedule.friStartTime, equals(HeliumTime.parse(json['fri_start_time'] as String)));
  expect(schedule.friEndTime, equals(HeliumTime.parse(json['fri_end_time'] as String)));
  expect(schedule.satStartTime, equals(HeliumTime.parse(json['sat_start_time'] as String)));
  expect(schedule.satEndTime, equals(HeliumTime.parse(json['sat_end_time'] as String)));
  expect(schedule.course, equals(json['course']));
}

// ============================================================================
// GIVEN: Course JSON Fixtures
// ============================================================================

/// Creates JSON data representing a course.
Map<String, dynamic> givenCourseJson({
  int id = 1,
  String title = '📚 Intro to Computer Science',
  String startDate = '2025-08-25',
  String endDate = '2025-12-15',
  String room = 'Room 101',
  double credits = 3.0,
  String color = '#4CAF50',
  String website = 'https://example.com/course',
  bool isOnline = false,
  int courseGroup = 1,
  String teacherName = 'Dr. Smith',
  String teacherEmail = 'smith@university.edu',
  double? currentGrade = 85.5,
  List<Map<String, dynamic>>? schedules,
}) {
  return {
    'id': id,
    'title': title,
    'start_date': startDate,
    'end_date': endDate,
    'room': room,
    'credits': credits,
    'color': color,
    'website': website,
    'is_online': isOnline,
    'course_group': courseGroup,
    'teacher_name': teacherName,
    'teacher_email': teacherEmail,
    'current_grade': currentGrade,
    'schedules': schedules ?? [givenCourseScheduleJson(course: id)],
  };
}

/// Verifies that a [CourseModel] matches the expected JSON data.
void verifyCourseMatchesJson(CourseModel course, Map<String, dynamic> json) {
  expect(course.id, equals(json['id']));
  expect(course.title, equals(json['title']));
  expect(course.startDate, equals(DateTime.parse(json['start_date'] as String)));
  expect(course.endDate, equals(DateTime.parse(json['end_date'] as String)));
  expect(course.room, equals(json['room']));
  expect(course.credits, equals(json['credits']));
  expect(
    HeliumColors.colorToHex(course.color).toLowerCase(),
    equals((json['color'] as String).toLowerCase()),
  );
  expect(course.website, equals(json['website']));
  expect(course.isOnline, equals(json['is_online']));
  expect(course.courseGroup, equals(json['course_group']));
  expect(course.teacherName, equals(json['teacher_name']));
  expect(course.teacherEmail, equals(json['teacher_email']));
  expect(course.currentGrade, equals(json['current_grade']));

  if (json['schedules'] != null) {
    final schedules = json['schedules'] as List;
    expect(course.schedules.length, equals(schedules.length));
    for (var i = 0; i < schedules.length; i++) {
      verifyCourseScheduleMatchesJson(course.schedules[i], schedules[i]);
    }
  }
}

// ============================================================================
// GIVEN: Category JSON Fixtures
// ============================================================================

/// Creates JSON data representing a category.
Map<String, dynamic> givenCategoryJson({
  int id = 1,
  String title = '📝 Homework',
  String color = '#E21D55',
  int course = 1,
  double weight = 30.0,
  double? overallGrade,
  double? gradeByWeight,
  double? trend,
  int? numHomeworkGraded,
}) {
  return {
    'id': id,
    'title': title,
    'color': color,
    'course': course,
    'weight': weight,
    'overall_grade': overallGrade,
    'grade_by_weight': gradeByWeight,
    'trend': trend,
    'num_homework_graded': numHomeworkGraded,
  };
}

/// Verifies that a [CategoryModel] matches the expected JSON data.
void verifyCategoryMatchesJson(
  CategoryModel category,
  Map<String, dynamic> json,
) {
  expect(category.id, equals(json['id']));
  expect(category.title, equals(json['title']));
  expect(
    HeliumColors.colorToHex(category.color).toLowerCase(),
    equals((json['color'] as String).toLowerCase()),
  );
  expect(category.course, equals(json['course']));
  expect(category.weight, equals(json['weight']));
  expect(category.overallGrade, equals(json['overall_grade']));
  expect(category.gradeByWeight, equals(json['grade_by_weight']));
  expect(category.trend, equals(json['trend']));
  expect(category.numHomeworkGraded, equals(json['num_homework_graded']));
}

// ============================================================================
// GIVEN: Attachment JSON Fixtures
// ============================================================================

/// Creates JSON data representing an attachment.
Map<String, dynamic> givenAttachmentJson({
  int id = 1,
  String title = '📎 homework_solution.pdf',
  String attachment =
      'https://api.heliumedu.com/attachments/homework_solution.pdf',
  int size = 1024,
  int user = 1,
  int? course,
  int? event,
  int? homework,
}) {
  return {
    'id': id,
    'title': title,
    'attachment': attachment,
    'size': size,
    'user': user,
    'course': course,
    'event': event,
    'homework': homework,
  };
}

/// Verifies that an [AttachmentModel] matches the expected JSON data.
void verifyAttachmentMatchesJson(
  AttachmentModel attachment,
  Map<String, dynamic> json,
) {
  expect(attachment.id, equals(json['id']));
  expect(attachment.title, equals(json['title']));
  expect(attachment.attachment, equals(json['attachment']));
  expect(attachment.size, equals(json['size']));
  expect(attachment.user, equals(json['user']));
  expect(attachment.course, equals(json['course']));
  expect(attachment.event, equals(json['event']));
  expect(attachment.homework, equals(json['homework']));
}

// ============================================================================
// GIVEN: Reminder JSON Fixtures
// ============================================================================

/// Creates JSON data representing a reminder.
Map<String, dynamic> givenReminderJson({
  int id = 1,
  String title = '⏰ Homework Due',
  String message = 'Remember to submit your homework!',
  String startOfRange = '2025-08-25T09:00:00Z',
  int offset = 15,
  int offsetType = 0,
  int type = 0,
  bool sent = false,
  bool dismissed = false,
  int? homework,
  int? event,
}) {
  return {
    'id': id,
    'title': title,
    'message': message,
    'start_of_range': startOfRange,
    'offset': offset,
    'offset_type': offsetType,
    'type': type,
    'sent': sent,
    'dismissed': dismissed,
    'homework': homework,
    'event': event,
  };
}

/// Verifies that a [ReminderModel] matches the expected JSON data.
void verifyReminderMatchesJson(
  ReminderModel reminder,
  Map<String, dynamic> json,
) {
  expect(reminder.id, equals(json['id']));
  expect(reminder.title, equals(json['title']));
  expect(reminder.message, equals(json['message']));
  expect(reminder.startOfRange, equals(DateTime.parse(json['start_of_range'] as String)));
  expect(reminder.offset, equals(json['offset']));
  expect(reminder.offsetType, equals(json['offset_type']));
  expect(reminder.type, equals(json['type']));
  expect(reminder.sent, equals(json['sent']));
  expect(reminder.dismissed, equals(json['dismissed']));
}

// ============================================================================
// GIVEN: Event JSON Fixtures
// ============================================================================

/// Creates JSON data representing an event.
Map<String, dynamic> givenEventJson({
  int id = 1,
  String title = '📅 Study Group Meeting',
  bool allDay = false,
  bool showEndTime = true,
  String start = '2025-08-25T14:00:00Z',
  String end = '2025-08-25T16:00:00Z',
  int priority = 50,
  String? url,
  String comments = 'Meet at the library',
  String? ownerId,
  String? color,
  List<dynamic>? attachments,
  List<dynamic>? reminders,
}) {
  return {
    'id': id,
    'title': title,
    'all_day': allDay,
    'show_end_time': showEndTime,
    'start': start,
    'end': end,
    'priority': priority,
    'url': url,
    'comments': comments,
    'owner_id': ownerId,
    'color': color,
    'attachments': attachments ?? [],
    'reminders': reminders ?? [],
  };
}

/// Verifies that an [EventModel] matches the expected JSON data.
void verifyEventMatchesJson(EventModel event, Map<String, dynamic> json) {
  expect(event.id, equals(json['id']));
  expect(event.title, equals(json['title']));
  expect(event.allDay, equals(json['all_day']));
  expect(event.showEndTime, equals(json['show_end_time']));
  expect(event.start, equals(DateTime.parse(json['start'] as String)));
  expect(event.end, equals(DateTime.parse(json['end'] as String)));
  expect(event.priority, equals(json['priority']));
  expect(event.url, equals(json['url']));
  expect(event.comments, equals(json['comments']));
  expect(event.ownerId, equals(json['owner_id']));

  if (json['color'] != null && event.color != null) {
    expect(
      HeliumColors.colorToHex(event.color!).toLowerCase(),
      equals((json['color'] as String).toLowerCase()),
    );
  }
}

// ============================================================================
// GIVEN: Homework JSON Fixtures
// ============================================================================

/// Creates JSON data representing a homework item.
Map<String, dynamic> givenHomeworkJson({
  int id = 1,
  String title = '💻 Programming Assignment',
  bool allDay = false,
  bool showEndTime = true,
  String start = '2025-08-25T23:59:00Z',
  String end = '2025-08-26T23:59:00Z',
  int priority = 75,
  String? url,
  String comments = 'Complete all exercises from chapter 5',
  bool completed = false,
  int course = 1,
  int category = 1,
  List<int>? materials,
  String? currentGrade,
  List<dynamic>? attachments,
  List<dynamic>? reminders,
}) {
  return {
    'id': id,
    'title': title,
    'all_day': allDay,
    'show_end_time': showEndTime,
    'start': start,
    'end': end,
    'priority': priority,
    'url': url,
    'comments': comments,
    'completed': completed,
    'course': course,
    'category': category,
    'materials': materials ?? [],
    'current_grade': currentGrade,
    'attachments': attachments ?? [],
    'reminders': reminders ?? [],
  };
}

/// Verifies that a [HomeworkModel] matches the expected JSON data.
void verifyHomeworkMatchesJson(
  HomeworkModel homework,
  Map<String, dynamic> json,
) {
  expect(homework.id, equals(json['id']));
  expect(homework.title, equals(json['title']));
  expect(homework.allDay, equals(json['all_day']));
  expect(homework.showEndTime, equals(json['show_end_time']));
  expect(homework.start, equals(DateTime.parse(json['start'] as String)));
  expect(homework.end, equals(DateTime.parse(json['end'] as String)));
  expect(homework.priority, equals(json['priority']));
  expect(homework.comments, equals(json['comments']));
  expect(homework.completed, equals(json['completed']));
  expect(homework.currentGrade, equals(json['current_grade']));

  // Verify course ID (could be nested or just ID)
  if (json['course'] is int) {
    expect(homework.course.id, equals(json['course']));
  }

  // Verify category ID if present
  if (json['category'] != null) {
    if (json['category'] is int) {
      expect(homework.category.id, equals(json['category']));
    }
  }
}

// ============================================================================
// GIVEN: Material Group JSON Fixtures
// ============================================================================

/// Creates JSON data representing a material group.
Map<String, dynamic> givenMaterialGroupJson({
  int id = 1,
  String title = '📖 Textbooks',
  bool shownOnCalendar = true,
}) {
  return {'id': id, 'title': title, 'shown_on_calendar': shownOnCalendar};
}

/// Verifies that a [MaterialGroupModel] matches the expected JSON data.
void verifyMaterialGroupMatchesJson(
  MaterialGroupModel materialGroup,
  Map<String, dynamic> json,
) {
  expect(materialGroup.id, equals(json['id']));
  expect(materialGroup.title, equals(json['title']));
  expect(materialGroup.shownOnCalendar, equals(json['shown_on_calendar']));
}

// ============================================================================
// GIVEN: Material JSON Fixtures
// ============================================================================

/// Creates JSON data representing a material.
Map<String, dynamic> givenMaterialJson({
  int id = 1,
  String title = '📕 Introduction to Algorithms',
  int status = 0,
  int condition = 0,
  String? details,
  String website = 'https://example.com/course',
  String? price,
  int materialGroup = 1,
  List<int>? courses,
}) {
  return {
    'id': id,
    'title': title,
    'status': status,
    'condition': condition,
    'details': details,
    'website': website,
    'price': price,
    'material_group': materialGroup,
    'courses': courses ?? [],
  };
}

/// Verifies that a [MaterialModel] matches the expected JSON data.
void verifyMaterialMatchesJson(
  MaterialModel material,
  Map<String, dynamic> json,
) {
  expect(material.id, equals(json['id']));
  expect(material.title, equals(json['title']));
  expect(material.status, equals(json['status']));
  expect(material.condition, equals(json['condition']));
  expect(material.details, equals(json['details']));
  expect(material.website, equals(json['website']));
  expect(material.price, equals(json['price']));
  expect(material.materialGroup, equals(json['material_group']));
  expect(material.courses, equals(json['courses']));
}

// ============================================================================
// GIVEN: Grade Course Group JSON Fixtures
// ============================================================================

/// Creates JSON data representing a grade course group.
Map<String, dynamic> givenGradeCourseGroupJson({
  int id = 1,
  String title = '🍂 Fall 2025',
  double overallGrade = 88.5,
  List<List<dynamic>>? gradePoints,
  List<Map<String, dynamic>>? courses,
  int numHomework = 20,
  int numHomeworkCompleted = 15,
  int numHomeworkGraded = 12,
}) {
  return {
    'id': id,
    'title': title,
    'overall_grade': overallGrade,
    'grade_points': gradePoints ?? [],
    'courses': courses ?? [],
    'num_homework': numHomework,
    'num_homework_completed': numHomeworkCompleted,
    'num_homework_graded': numHomeworkGraded,
  };
}

/// Verifies that a [GradeCourseGroupModel] matches the expected JSON data.
void verifyGradeCourseGroupMatchesJson(
  GradeCourseGroupModel gradeCourseGroup,
  Map<String, dynamic> json,
) {
  expect(gradeCourseGroup.id, equals(json['id']));
  expect(gradeCourseGroup.title, equals(json['title']));
  expect(gradeCourseGroup.overallGrade, equals(json['overall_grade']));
  expect(gradeCourseGroup.numHomework, equals(json['num_homework']));
  expect(
    gradeCourseGroup.numHomeworkCompleted,
    equals(json['num_homework_completed']),
  );
  expect(
    gradeCourseGroup.numHomeworkGraded,
    equals(json['num_homework_graded']),
  );
}

// ============================================================================
// HELPER: Create lists of JSON fixtures
// ============================================================================

/// Creates a list of course group JSON objects.
List<Map<String, dynamic>> givenCourseGroupListJson({int count = 2}) {
  return List.generate(
    count,
    (index) =>
        givenCourseGroupJson(id: index + 1, title: '🍂 Semester ${index + 1}'),
  );
}

/// Creates a list of course JSON objects.
List<Map<String, dynamic>> givenCourseListJson({
  int count = 3,
  int courseGroup = 1,
}) {
  final titles = [
    '📚 Intro to Computer Science',
    '📐 Calculus I',
    '✏️ English Composition',
    '🔬 Physics 101',
    '⚗️ Chemistry 101',
  ];
  return List.generate(
    count,
    (index) => givenCourseJson(
      id: index + 1,
      title: titles[index % titles.length],
      courseGroup: courseGroup,
    ),
  );
}

/// Creates a list of category JSON objects.
List<Map<String, dynamic>> givenCategoryListJson({
  int count = 3,
  int course = 1,
}) {
  final titles = ['📝 Homework', '📊 Exams', '🎯 Quizzes'];
  final colors = ['#E21D55', '#4CAF50', '#2196F3'];
  final weights = [30.0, 50.0, 20.0];
  return List.generate(
    count,
    (index) => givenCategoryJson(
      id: index + 1,
      title: titles[index % titles.length],
      color: colors[index % colors.length],
      weight: weights[index % weights.length],
      course: course,
    ),
  );
}

// ============================================================================
// GIVEN: Course Schedule Event JSON Fixtures
// ============================================================================

/// Creates JSON data representing a course schedule event.
Map<String, dynamic> givenCourseScheduleEventJson({
  int id = 1,
  String title = 'Intro to CS - Lecture',
  bool allDay = false,
  bool showEndTime = true,
  String start = '2025-08-25T09:00:00Z',
  String end = '2025-08-25T10:30:00Z',
  int priority = 50,
  String? url,
  String comments = '',
  String ownerId = 'course-1',
  String color = '#4CAF50',
  List<dynamic>? attachments,
  List<dynamic>? reminders,
}) {
  return {
    'id': id,
    'title': title,
    'all_day': allDay,
    'show_end_time': showEndTime,
    'start': start,
    'end': end,
    'priority': priority,
    'url': url,
    'comments': comments,
    'owner_id': ownerId,
    'color': color,
    'attachments': attachments ?? [],
    'reminders': reminders ?? [],
  };
}

// ============================================================================
// GIVEN: Course Schedule Request Model Fixtures
// ============================================================================

/// Creates a CourseScheduleRequestModel for testing.
CourseScheduleRequestModel givenCourseScheduleRequestModel({
  String daysOfWeek = '0101010',
  TimeOfDay? sunStartTime,
  TimeOfDay? sunEndTime,
  TimeOfDay? monStartTime,
  TimeOfDay? monEndTime,
  TimeOfDay? tueStartTime,
  TimeOfDay? tueEndTime,
  TimeOfDay? wedStartTime,
  TimeOfDay? wedEndTime,
  TimeOfDay? thuStartTime,
  TimeOfDay? thuEndTime,
  TimeOfDay? friStartTime,
  TimeOfDay? friEndTime,
  TimeOfDay? satStartTime,
  TimeOfDay? satEndTime,
}) {
  return CourseScheduleRequestModel(
    daysOfWeek: daysOfWeek,
    sunStartTime: sunStartTime ?? const TimeOfDay(hour: 0, minute: 0),
    sunEndTime: sunEndTime ?? const TimeOfDay(hour: 0, minute: 0),
    monStartTime: monStartTime ?? const TimeOfDay(hour: 9, minute: 0),
    monEndTime: monEndTime ?? const TimeOfDay(hour: 10, minute: 30),
    tueStartTime: tueStartTime ?? const TimeOfDay(hour: 0, minute: 0),
    tueEndTime: tueEndTime ?? const TimeOfDay(hour: 0, minute: 0),
    wedStartTime: wedStartTime ?? const TimeOfDay(hour: 9, minute: 0),
    wedEndTime: wedEndTime ?? const TimeOfDay(hour: 10, minute: 30),
    thuStartTime: thuStartTime ?? const TimeOfDay(hour: 0, minute: 0),
    thuEndTime: thuEndTime ?? const TimeOfDay(hour: 0, minute: 0),
    friStartTime: friStartTime ?? const TimeOfDay(hour: 9, minute: 0),
    friEndTime: friEndTime ?? const TimeOfDay(hour: 10, minute: 30),
    satStartTime: satStartTime ?? const TimeOfDay(hour: 0, minute: 0),
    satEndTime: satEndTime ?? const TimeOfDay(hour: 0, minute: 0),
  );
}

// ============================================================================
// GIVEN: External Calendar JSON Fixtures
// ============================================================================

/// Creates JSON data representing an external calendar.
Map<String, dynamic> givenExternalCalendarJson({
  int id = 1,
  String title = 'Google Calendar',
  String url = 'https://calendar.google.com/ical/example.ics',
  String color = '#4285F4',
  bool shownOnCalendar = true,
}) {
  return {
    'id': id,
    'title': title,
    'url': url,
    'color': color,
    'shown_on_calendar': shownOnCalendar,
  };
}

// ============================================================================
// GIVEN: External Calendar Event JSON Fixtures
// ============================================================================

/// Creates JSON data representing an external calendar event.
Map<String, dynamic> givenExternalCalendarEventJson({
  int id = 1,
  String title = 'Meeting',
  bool allDay = false,
  bool showEndTime = true,
  String start = '2025-08-25T14:00:00Z',
  String end = '2025-08-25T15:00:00Z',
  int priority = 50,
  String? url,
  String comments = '',
  String ownerId = 'external-1',
  String color = '#4285F4',
  List<dynamic>? attachments,
  List<dynamic>? reminders,
}) {
  return {
    'id': id,
    'title': title,
    'all_day': allDay,
    'show_end_time': showEndTime,
    'start': start,
    'end': end,
    'priority': priority,
    'url': url,
    'comments': comments,
    'owner_id': ownerId,
    'color': color,
    'attachments': attachments ?? [],
    'reminders': reminders ?? [],
  };
}

// ============================================================================
// GIVEN: External Calendar Request Model Fixtures
// ============================================================================

/// Creates an ExternalCalendarRequestModel for testing.
ExternalCalendarRequestModel givenExternalCalendarRequestModel({
  String title = 'Google Calendar',
  String url = 'https://calendar.google.com/ical/example.ics',
  String color = '#4285F4',
  bool shownOnCalendar = true,
}) {
  return ExternalCalendarRequestModel(
    title: title,
    url: url,
    color: color,
    shownOnCalendar: shownOnCalendar,
  );
}

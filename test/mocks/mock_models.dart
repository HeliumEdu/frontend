// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:heliumapp/data/models/attachment_file.dart';
import 'package:heliumapp/data/models/auth/private_feed_model.dart';
import 'package:heliumapp/data/models/auth/token_response_model.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/data/models/id_or_entity.dart';
import 'package:heliumapp/data/models/no_content_response_model.dart';
import 'package:heliumapp/data/models/planner/attachment_model.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/external_calendar_event_model.dart';
import 'package:heliumapp/data/models/planner/external_calendar_model.dart';
import 'package:heliumapp/data/models/planner/grade_course_group_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/resource_group_model.dart';
import 'package:heliumapp/data/models/planner/resource_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/standalone.dart' as tz;

/// Test fixture factory for creating mock models.
class MockModels {
  static bool _tzInitialized = false;

  static void _ensureTzInitialized() {
    if (!_tzInitialized) {
      tz_data.initializeTimeZones();
      _tzInitialized = true;
    }
  }

  /// Creates a mock [UserModel] with default or custom values.
  static UserModel createUser({
    int id = 1,
    String email = 'test@example.com',
    String? emailChanging,
    UserSettingsModel? settings,
    bool hasUsablePassword = true,
  }) {
    _ensureTzInitialized();
    return UserModel(
      id: id,
      email: email,
      emailChanging: emailChanging,
      settings: settings ?? createUserSettings(),
      hasUsablePassword: hasUsablePassword,
    );
  }

  /// Creates a mock [UserSettingsModel] with default or custom values.
  static UserSettingsModel createUserSettings({
    String timeZone = 'America/New_York',
    int defaultView = 0,
    int colorSchemeTheme = 0,
    int weekStartsOn = 0,
    int allDayOffset = 0,
    int whatsNewVersionSeen = 0,
    bool showGettingStarted = false,
    bool isSetupComplete = true,
    Color eventsColor = const Color(0xFF4CAF50),
    Color resourceColor = const Color(0xFF2196F3),
    Color gradeColor = const Color(0xFFFF9800),
    int defaultReminderType = 3,
    int defaultReminderOffset = 15,
    int defaultReminderOffsetType = 0,
    bool colorByCategory = false,
    bool rememberFilterState = false,
    String? privateSlug,
  }) {
    _ensureTzInitialized();
    return UserSettingsModel(
      timeZone: tz.getLocation(timeZone),
      defaultView: defaultView,
      colorSchemeTheme: colorSchemeTheme,
      weekStartsOn: weekStartsOn,
      allDayOffset: allDayOffset,
      whatsNewVersionSeen: whatsNewVersionSeen,
      showGettingStarted: showGettingStarted,
      isSetupComplete: isSetupComplete,
      eventsColor: eventsColor,
      resourceColor: resourceColor,
      gradeColor: gradeColor,
      defaultReminderType: defaultReminderType,
      defaultReminderOffset: defaultReminderOffset,
      defaultReminderOffsetType: defaultReminderOffsetType,
      colorByCategory: colorByCategory,
      rememberFilterState: rememberFilterState,
      privateSlug: privateSlug,
    );
  }

  /// Creates a mock [TokenResponseModel] with default or custom values.
  static TokenResponseModel createTokenResponse({
    String access = 'mock_access_token',
    String refresh = 'mock_refresh_token',
  }) {
    return TokenResponseModel(access: access, refresh: refresh);
  }

  /// Creates a mock [NoContentResponseModel].
  static NoContentResponseModel createNoContentResponse({
    String message = 'Success',
  }) {
    return NoContentResponseModel(message: message);
  }

  /// Creates a mock [PrivateFeedModel] with default or custom values.
  static PrivateFeedModel createPrivateFeed({
    String eventsPrivateUrl = 'https://example.com/feeds/events/abc123',
    String homeworkPrivateUrl = 'https://example.com/feeds/homework/abc123',
    String courseSchedulesPrivateUrl =
        'https://example.com/feeds/schedules/abc123',
  }) {
    return PrivateFeedModel(
      eventsPrivateUrl: eventsPrivateUrl,
      homeworkPrivateUrl: homeworkPrivateUrl,
      courseSchedulesPrivateUrl: courseSchedulesPrivateUrl,
    );
  }

  /// Creates a mock [CourseGroupModel] with default or custom values.
  static CourseGroupModel createCourseGroup({
    int id = 1,
    String title = 'Fall 2025',
    DateTime? startDate,
    DateTime? endDate,
    bool shownOnCalendar = true,
    double? averageGrade,
    int? numDays = 112,
    int? numDaysCompleted = 50,
  }) {
    return CourseGroupModel(
      id: id,
      title: title,
      startDate: startDate ?? DateTime.parse('2025-08-25'),
      endDate: endDate ?? DateTime.parse('2025-12-15'),
      shownOnCalendar: shownOnCalendar,
      averageGrade: averageGrade,
      numDays: numDays,
      numDaysCompleted: numDaysCompleted,
    );
  }

  /// Creates a mock [CourseScheduleModel] with default or custom values.
  static CourseScheduleModel createCourseSchedule({
    int id = 1,
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
    int course = 1,
  }) {
    return CourseScheduleModel(
      id: id,
      daysOfWeek: daysOfWeek,
      sunStartTime: sunStartTime ?? const TimeOfDay(hour: 0, minute: 0),
      sunEndTime: sunEndTime ?? const TimeOfDay(hour: 0, minute: 0),
      monStartTime: monStartTime ?? const TimeOfDay(hour: 9, minute: 0),
      monEndTime: monEndTime ?? const TimeOfDay(hour: 10, minute: 0),
      tueStartTime: tueStartTime ?? const TimeOfDay(hour: 0, minute: 0),
      tueEndTime: tueEndTime ?? const TimeOfDay(hour: 0, minute: 0),
      wedStartTime: wedStartTime ?? const TimeOfDay(hour: 9, minute: 0),
      wedEndTime: wedEndTime ?? const TimeOfDay(hour: 10, minute: 0),
      thuStartTime: thuStartTime ?? const TimeOfDay(hour: 0, minute: 0),
      thuEndTime: thuEndTime ?? const TimeOfDay(hour: 0, minute: 0),
      friStartTime: friStartTime ?? const TimeOfDay(hour: 9, minute: 0),
      friEndTime: friEndTime ?? const TimeOfDay(hour: 10, minute: 0),
      satStartTime: satStartTime ?? const TimeOfDay(hour: 0, minute: 0),
      satEndTime: satEndTime ?? const TimeOfDay(hour: 0, minute: 0),
      course: course,
    );
  }

  /// Creates a mock [CourseModel] with default or custom values.
  static CourseModel createCourse({
    int id = 1,
    String title = 'Introduction to Computer Science',
    DateTime? startDate,
    DateTime? endDate,
    String room = 'Room 101',
    double credits = 3.0,
    Color color = const Color(0xFF4CAF50),
    String website = 'https://example.com/course',
    bool isOnline = false,
    int courseGroup = 1,
    String teacherName = 'Dr. Smith',
    String teacherEmail = 'smith@university.edu',
    double? currentGrade = 85.5,
    List<CourseScheduleModel>? schedules,
  }) {
    return CourseModel(
      id: id,
      title: title,
      startDate: startDate ?? DateTime.parse('2025-08-25'),
      endDate: endDate ?? DateTime.parse('2025-12-15'),
      room: room,
      credits: credits,
      color: color,
      website: website,
      isOnline: isOnline,
      courseGroup: courseGroup,
      teacherName: teacherName,
      teacherEmail: teacherEmail,
      currentGrade: currentGrade,
      schedules: schedules ?? [createCourseSchedule(course: id)],
    );
  }

  /// Creates a mock [CategoryModel] with default or custom values.
  static CategoryModel createCategory({
    int id = 1,
    String title = 'Homework',
    Color color = const Color(0xFFE21D55),
    int course = 1,
    double weight = 30.0,
    double? overallGrade,
    double? gradeByWeight,
  }) {
    return CategoryModel(
      id: id,
      title: title,
      color: color,
      course: course,
      weight: weight,
      overallGrade: overallGrade,
      gradeByWeight: gradeByWeight,
    );
  }

  /// Creates a list of mock [CourseGroupModel] instances.
  static List<CourseGroupModel> createCourseGroups({int count = 2}) {
    return List.generate(
      count,
      (index) =>
          createCourseGroup(id: index + 1, title: 'Semester ${index + 1}'),
    );
  }

  /// Creates a list of mock [CourseModel] instances.
  static List<CourseModel> createCourses({int count = 3, int courseGroup = 1}) {
    final titles = [
      'Introduction to Computer Science',
      'Calculus I',
      'English Composition',
      'Physics 101',
      'Chemistry 101',
    ];
    return List.generate(
      count,
      (index) => createCourse(
        id: index + 1,
        title: titles[index % titles.length],
        courseGroup: courseGroup,
      ),
    );
  }

  /// Creates a mock [GradeCourseGroupModel] with default or custom values.
  static GradeCourseGroupModel createGradeCourseGroup({
    int id = 1,
    String title = 'Fall 2025',
    double overallGrade = 88.5,
    List<List<dynamic>>? gradePoints,
    int numHomework = 20,
    int numHomeworkCompleted = 15,
    int numHomeworkGraded = 12,
  }) {
    return GradeCourseGroupModel(
      id: id,
      title: title,
      overallGrade: overallGrade,
      gradePoints: gradePoints ?? [],
      courses: [],
      numHomework: numHomework,
      numHomeworkCompleted: numHomeworkCompleted,
      numHomeworkGraded: numHomeworkGraded,
    );
  }

  /// Creates a list of mock [GradeCourseGroupModel] instances.
  static List<GradeCourseGroupModel> createGradeCourseGroups({int count = 2}) {
    return List.generate(
      count,
      (index) => createGradeCourseGroup(
        id: index + 1,
        title: 'Semester ${index + 1}',
        overallGrade: 85.0 + (index * 5),
      ),
    );
  }

  /// Creates a mock [ResourceGroupModel] with default or custom values.
  static ResourceGroupModel createResourceGroup({
    int id = 1,
    String title = 'Textbooks',
    bool shownOnCalendar = true,
  }) {
    return ResourceGroupModel(
      id: id,
      title: title,
      shownOnCalendar: shownOnCalendar,
    );
  }

  /// Creates a mock [ResourceModel] with default or custom values.
  static ResourceModel createResource({
    int id = 1,
    String title = 'Introduction to Algorithms',
    int status = 0,
    int condition = 0,
    String? details,
    String website = 'https://example.com/material',
    String? price,
    int resourceGroup = 1,
    List<int>? courses,
  }) {
    return ResourceModel(
      id: id,
      title: title,
      status: status,
      condition: condition,
      details: details,
      website: website,
      price: price,
      resourceGroup: resourceGroup,
      courses: courses ?? [],
    );
  }

  /// Creates a list of mock [ResourceGroupModel] instances.
  static List<ResourceGroupModel> createResourceGroups({int count = 2}) {
    final titles = ['Textbooks', 'Course Materials', 'Lab Equipment'];
    return List.generate(
      count,
      (index) => createResourceGroup(
        id: index + 1,
        title: titles[index % titles.length],
      ),
    );
  }

  /// Creates a list of mock [ResourceModel] instances.
  static List<ResourceModel> createResources({
    int count = 3,
    int resourceGroup = 1,
  }) {
    final titles = [
      'Introduction to Algorithms',
      'Data Structures Handbook',
      'Lab Safety Manual',
    ];
    return List.generate(
      count,
      (index) => createResource(
        id: index + 1,
        title: titles[index % titles.length],
        resourceGroup: resourceGroup,
      ),
    );
  }

  /// Creates a mock [ReminderModel] with default or custom values.
  static ReminderModel createReminder({
    int id = 1,
    String title = 'Test Reminder',
    String message = 'This is a test reminder',
    DateTime? startOfRange,
    int offset = 15,
    int offsetType = 0,
    int type = 0,
    bool sent = false,
    bool dismissed = false,
    int? homeworkId,
    int? eventId,
  }) {
    return ReminderModel(
      id: id,
      title: title,
      message: message,
      startOfRange: startOfRange ?? DateTime.parse('2025-01-15T10:00:00Z'),
      offset: offset,
      offsetType: offsetType,
      type: type,
      sent: sent,
      dismissed: dismissed,
    );
  }

  /// Creates a list of mock [ReminderModel] instances.
  static List<ReminderModel> createReminders({int count = 3}) {
    return List.generate(
      count,
      (index) => createReminder(
        id: index + 1,
        title: 'Reminder ${index + 1}',
        offset: (index + 1) * 15,
      ),
    );
  }

  /// Creates a mock [AttachmentModel] with default or custom values.
  static AttachmentModel createAttachment({
    int id = 1,
    String title = 'test_file.pdf',
    String attachment = 'https://example.com/files/test_file.pdf',
    int size = 1024,
    int user = 1,
    int? course,
    int? event,
    int? homework,
  }) {
    return AttachmentModel(
      id: id,
      title: title,
      attachment: attachment,
      size: size,
      user: user,
      course: course,
      event: event,
      homework: homework,
    );
  }

  /// Creates a list of mock [AttachmentModel] instances.
  static List<AttachmentModel> createAttachments({
    int count = 3,
    int? homeworkId,
    int? eventId,
    int? courseId,
  }) {
    final titles = ['document.pdf', 'image.png', 'notes.txt'];
    return List.generate(
      count,
      (index) => createAttachment(
        id: index + 1,
        title: titles[index % titles.length],
        homework: homeworkId,
        event: eventId,
        course: courseId,
      ),
    );
  }

  /// Creates a mock [AttachmentFile] for upload testing.
  static AttachmentFile createAttachmentFile({
    String title = 'upload_test.pdf',
    Uint8List? bytes,
  }) {
    return AttachmentFile(
      title: title,
      bytes: bytes ?? Uint8List.fromList([0x48, 0x65, 0x6c, 0x6c, 0x6f]),
    );
  }

  /// Creates a list of mock [AttachmentFile] instances for upload testing.
  static List<AttachmentFile> createAttachmentFiles({int count = 2}) {
    final titles = ['file1.pdf', 'file2.png', 'file3.doc'];
    return List.generate(
      count,
      (index) => createAttachmentFile(title: titles[index % titles.length]),
    );
  }

  /// Creates a mock [EventModel] with default or custom values.
  static EventModel createEvent({
    int id = 1,
    String title = 'Test Event',
    bool allDay = false,
    bool showEndTime = true,
    DateTime? start,
    DateTime? end,
    int priority = 50,
    String? url,
    String comments = '',
    Color color = const Color(0xFF4CAF50),
  }) {
    return EventModel(
      id: id,
      title: title,
      allDay: allDay,
      showEndTime: showEndTime,
      start: start ?? DateTime.parse('2025-01-15T10:00:00Z'),
      end: end ?? DateTime.parse('2025-01-15T11:00:00Z'),
      priority: priority,
      url: url,
      comments: comments,
      attachments: [],
      reminders: [],
      color: color,
    );
  }

  /// Creates a list of mock [EventModel] instances.
  static List<EventModel> createEvents({int count = 3}) {
    final titles = ['Meeting', 'Appointment', 'Deadline'];
    return List.generate(
      count,
      (index) =>
          createEvent(id: index + 1, title: titles[index % titles.length]),
    );
  }

  /// Creates a mock [HomeworkModel] with default or custom values.
  static HomeworkModel createHomework({
    int id = 1,
    String title = 'Test Homework',
    bool allDay = false,
    bool showEndTime = true,
    DateTime? start,
    DateTime? end,
    int priority = 50,
    String comments = '',
    bool completed = false,
    String currentGrade = '-1/100',
    int courseId = 1,
    int categoryId = 1,
  }) {
    return HomeworkModel(
      id: id,
      title: title,
      allDay: allDay,
      showEndTime: showEndTime,
      start: start ?? DateTime.parse('2025-01-15T10:00:00Z'),
      end: end ?? DateTime.parse('2025-01-15T11:00:00Z'),
      priority: priority,
      comments: comments,
      attachments: [],
      reminders: [],
      completed: completed,
      currentGrade: currentGrade,
      course: IdOrEntity<CourseModel>(id: courseId),
      category: IdOrEntity<CategoryModel>(id: categoryId),
      resources: [],
    );
  }

  /// Creates a list of mock [HomeworkModel] instances.
  static List<HomeworkModel> createHomeworks({int count = 3}) {
    final titles = ['Assignment 1', 'Lab Report', 'Essay'];
    return List.generate(
      count,
      (index) =>
          createHomework(id: index + 1, title: titles[index % titles.length]),
    );
  }

  /// Creates a mock [ExternalCalendarModel] with default or custom values.
  static ExternalCalendarModel createExternalCalendar({
    int id = 1,
    String title = 'External Calendar',
    String url = 'https://example.com/calendar.ics',
    Color color = const Color(0xFF2196F3),
    bool shownOnCalendar = true,
  }) {
    return ExternalCalendarModel(
      id: id,
      title: title,
      url: url,
      color: color,
      shownOnCalendar: shownOnCalendar,
    );
  }

  /// Creates a list of mock [ExternalCalendarModel] instances.
  static List<ExternalCalendarModel> createExternalCalendars({int count = 2}) {
    final titles = ['Work Calendar', 'Personal Calendar', 'Family Calendar'];
    return List.generate(
      count,
      (index) => createExternalCalendar(
        id: index + 1,
        title: titles[index % titles.length],
      ),
    );
  }

  /// Creates a mock [ExternalCalendarEventModel] with default or custom values.
  static ExternalCalendarEventModel createExternalCalendarEvent({
    int id = 1,
    String title = 'External Event',
    bool allDay = false,
    bool showEndTime = true,
    DateTime? start,
    DateTime? end,
    int priority = 50,
    String? url,
    String comments = '',
    Color color = const Color(0xFF2196F3),
    String ownerId = '1',
  }) {
    return ExternalCalendarEventModel(
      id: id,
      title: title,
      allDay: allDay,
      showEndTime: showEndTime,
      start: start ?? DateTime.parse('2025-01-15T10:00:00Z'),
      end: end ?? DateTime.parse('2025-01-15T11:00:00Z'),
      priority: priority,
      url: url,
      comments: comments,
      attachments: [],
      reminders: [],
      color: color,
      ownerId: ownerId,
    );
  }

  /// Creates a list of mock [ExternalCalendarEventModel] instances.
  static List<ExternalCalendarEventModel> createExternalCalendarEvents({
    int count = 3,
  }) {
    final titles = ['Work Meeting', 'Doctor Appointment', 'Birthday Party'];
    return List.generate(
      count,
      (index) => createExternalCalendarEvent(
        id: index + 1,
        title: titles[index % titles.length],
      ),
    );
  }

  /// Creates a list of mock [CategoryModel] instances.
  static List<CategoryModel> createCategories({
    int count = 3,
    int courseId = 1,
  }) {
    final titles = ['Homework', 'Exams', 'Projects'];
    return List.generate(
      count,
      (index) => createCategory(
        id: index + 1,
        title: titles[index % titles.length],
        course: courseId,
      ),
    );
  }
}

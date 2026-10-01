import 'dart:ui';

import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';

class NotificationModel extends BaseModel {
  final String title;
  final String body;
  final String timestamp;
  final ReminderModel reminder;
  final CourseModel? course;
  final Color? color;

  NotificationModel({
    required super.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.reminder,
    this.course,
    this.color,
  });
}

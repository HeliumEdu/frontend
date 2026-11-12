import 'dart:ui';

import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/id_or_entity.dart';
import 'package:heliumapp/data/models/planner/attachment_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/utils/planner_helper.dart';

abstract class PlannerItemBaseModel extends BaseTitledModel {
  final bool allDay;
  final bool showEndTime;
  final DateTime start;
  final DateTime end;
  final int priority;
  final Uri? url;
  final Color? color;
  final String? location;
  final PlannerItemType plannerItemType;
  final List<IdOrEntity<AttachmentModel>> attachments;
  final List<IdOrEntity<ReminderModel>> reminders;
  final String? recurrenceRule;
  final List<DateTime> exceptionDates;

  PlannerItemBaseModel({
    required super.id,
    required super.title,
    required this.allDay,
    required this.showEndTime,
    required this.start,
    required this.end,
    required this.priority,
    this.url,
    this.color,
    this.location,
    required this.plannerItemType,
    required this.attachments,
    required this.reminders,
    super.version,
    this.recurrenceRule,
    this.exceptionDates = const [],
  });

  static List<DateTime> parseExceptionDatesJson(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<String>().map(DateTime.parse).toList();
  }

  PlannerItemBaseModel copyWith({DateTime? start, DateTime? end});
}

import 'package:flutter/material.dart';
import 'package:heliumapp/data/models/planner/course_schedule_cycle_slot_model.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';

class CourseScheduleRequestModel {
  final String daysOfWeek;
  final TimeOfDay sunStartTime;
  final TimeOfDay sunEndTime;
  final TimeOfDay monStartTime;
  final TimeOfDay monEndTime;
  final TimeOfDay tueStartTime;
  final TimeOfDay tueEndTime;
  final TimeOfDay wedStartTime;
  final TimeOfDay wedEndTime;
  final TimeOfDay thuStartTime;
  final TimeOfDay thuEndTime;
  final TimeOfDay friStartTime;
  final TimeOfDay friEndTime;
  final TimeOfDay satStartTime;
  final TimeOfDay satEndTime;

  /// Optional per-schedule date window. Null clears the override so the schedule
  /// inherits the parent course's dates.
  final DateTime? startDate;
  final DateTime? endDate;

  /// Rotating-schedule config (see `CourseScheduleModel`). A preset `template`
  /// or the raw Custom field (`cycleLength`), never both — see `toJson`.
  final int? template;
  final int? cycleLength;
  final DateTime? anchorDate;
  final List<CourseScheduleCycleSlotModel>? cycleSlots;
  final int? weekOffset;

  CourseScheduleRequestModel({
    required this.daysOfWeek,
    required this.sunStartTime,
    required this.sunEndTime,
    required this.monStartTime,
    required this.monEndTime,
    required this.tueStartTime,
    required this.tueEndTime,
    required this.wedStartTime,
    required this.wedEndTime,
    required this.thuStartTime,
    required this.thuEndTime,
    required this.friStartTime,
    required this.friEndTime,
    required this.satStartTime,
    required this.satEndTime,
    this.startDate,
    this.endDate,
    this.template,
    this.cycleLength,
    this.anchorDate,
    this.cycleSlots,
    this.weekOffset,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'days_of_week': daysOfWeek,
      'sun_start_time': HeliumTime.formatForApi(sunStartTime),
      'sun_end_time': HeliumTime.formatForApi(sunEndTime),
      'mon_start_time': HeliumTime.formatForApi(monStartTime),
      'mon_end_time': HeliumTime.formatForApi(monEndTime),
      'tue_start_time': HeliumTime.formatForApi(tueStartTime),
      'tue_end_time': HeliumTime.formatForApi(tueEndTime),
      'wed_start_time': HeliumTime.formatForApi(wedStartTime),
      'wed_end_time': HeliumTime.formatForApi(wedEndTime),
      'thu_start_time': HeliumTime.formatForApi(thuStartTime),
      'thu_end_time': HeliumTime.formatForApi(thuEndTime),
      'fri_start_time': HeliumTime.formatForApi(friStartTime),
      'fri_end_time': HeliumTime.formatForApi(friEndTime),
      'sat_start_time': HeliumTime.formatForApi(satStartTime),
      'sat_end_time': HeliumTime.formatForApi(satEndTime),
      'start_date':
          startDate != null ? HeliumDateTime.formatDateForApi(startDate!) : null,
      'end_date':
          endDate != null ? HeliumDateTime.formatDateForApi(endDate!) : null,
      'anchor_date': anchorDate != null
          ? HeliumDateTime.formatDateForApi(anchorDate!)
          : null,
      'cycle_slots': cycleSlots?.map((slot) => slot.toJson()).toList(),
      'week_offset': weekOffset,
    };

    // A template expands to cycle_length / is_week_based server-side; sending
    // them alongside it conflicts, so only Custom sends the raw values.
    if (template != null) {
      json['template'] = template;
    } else {
      json['template'] = null;
      json['cycle_length'] = cycleLength;
    }

    return json;
  }
}

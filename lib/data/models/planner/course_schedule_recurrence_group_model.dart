/// One recurring occurrence definition for a [CourseScheduleModel], resolved
/// server-side: an iCal [recurrenceRule] anchored at [start]/[end] with
/// course and course-group exceptions already merged into [exceptionDates].
/// Read-only — the backend derives it from the schedule's day/time fields.
class CourseScheduleRecurrenceGroupModel {
  final DateTime start;
  final DateTime end;
  final String recurrenceRule;
  final List<DateTime> exceptionDates;

  CourseScheduleRecurrenceGroupModel({
    required this.start,
    required this.end,
    required this.recurrenceRule,
    required this.exceptionDates,
  });

  factory CourseScheduleRecurrenceGroupModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return CourseScheduleRecurrenceGroupModel(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      recurrenceRule: json['recurrence_rule'] as String,
      exceptionDates: (json['exception_dates'] as List<dynamic>? ?? const [])
          .map((e) => DateTime.parse(e as String))
          .toList(),
    );
  }
}

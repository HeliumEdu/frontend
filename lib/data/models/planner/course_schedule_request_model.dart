class CourseScheduleRequestModel {
  final String daysOfWeek;
  final String sunStartTime;
  final String sunEndTime;
  final String monStartTime;
  final String monEndTime;
  final String tueStartTime;
  final String tueEndTime;
  final String wedStartTime;
  final String wedEndTime;
  final String thuStartTime;
  final String thuEndTime;
  final String friStartTime;
  final String friEndTime;
  final String satStartTime;
  final String satEndTime;

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
  });

  Map<String, dynamic> toJson() {
    return {
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
    };
  }
}

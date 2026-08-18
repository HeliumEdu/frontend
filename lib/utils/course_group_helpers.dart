import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';

class CourseGroupHelpers {
  CourseGroupHelpers._();

  /// Returns the id of the group whose date range contains today, or the
  /// closest group by date if none matches (preferring the nearest upcoming
  /// group over the nearest past one on a tie).
  static int? currentGroupId(List<CourseGroupModel> groups) {
    if (groups.isEmpty) return null;

    final today = HeliumDateTime.dateOnly(DateTime.now());

    for (final group in groups) {
      final start = HeliumDateTime.dateOnly(group.startDate);
      final end = HeliumDateTime.dateOnly(group.endDate);
      if (!today.isBefore(start) && !today.isAfter(end)) {
        return group.id;
      }
    }

    CourseGroupModel? nearestUpcoming;
    int? nearestUpcomingDays;
    CourseGroupModel? nearestPast;
    int? nearestPastDays;

    for (final group in groups) {
      final start = HeliumDateTime.dateOnly(group.startDate);
      final end = HeliumDateTime.dateOnly(group.endDate);

      if (today.isBefore(start)) {
        final days = start.difference(today).inDays;
        if (nearestUpcomingDays == null || days < nearestUpcomingDays) {
          nearestUpcoming = group;
          nearestUpcomingDays = days;
        }
      } else {
        final days = today.difference(end).inDays;
        if (nearestPastDays == null || days < nearestPastDays) {
          nearestPast = group;
          nearestPastDays = days;
        }
      }
    }

    if (nearestUpcoming != null &&
        (nearestPast == null || nearestUpcomingDays! <= nearestPastDays!)) {
      return nearestUpcoming.id;
    }

    return nearestPast?.id;
  }
}

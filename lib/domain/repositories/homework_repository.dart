import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/request/homework_request_model.dart';

abstract class HomeworkRepository {
  Future<List<HomeworkModel>> getHomeworks({
    required DateTime from,
    required DateTime to,
    List<String>? categoryTitles,
    String? search,
    String? title,
    bool? shownOnCalendar,
    bool forceRefresh = false,
  });

  Future<HomeworkModel> getHomework({
    required int id,
    bool forceRefresh = false,
  });

  Future<HomeworkModel> createHomework({
    required int groupId,
    required int courseId,
    required HomeworkRequestModel request,
  });

  Future<HomeworkModel> cloneHomework({
    required int groupId,
    required int courseId,
    required int homeworkId,
  });

  Future<HomeworkModel> updateHomework({
    required int groupId,
    required int courseId,
    required int homeworkId,
    required HomeworkRequestModel request,
  });

  Future<void> deleteHomework({
    required int groupId,
    required int courseId,
    required int homeworkId,
  });
}

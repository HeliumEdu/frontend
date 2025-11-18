import 'package:helium_student_flutter/data/models/planner/homework_request_model.dart';
import 'package:helium_student_flutter/data/models/planner/homework_response_model.dart';

abstract class HomeworkRepository {
  Future<List<HomeworkResponseModel>> getAllHomework({
    List<String>? categoryTitles,
  });

  Future<HomeworkResponseModel> createHomework({
    required int groupId,
    required int courseId,
    required HomeworkRequestModel request,
  });

  Future<List<HomeworkResponseModel>> getHomework({
    required int groupId,
    required int courseId,
  });

  Future<HomeworkResponseModel> getHomeworkById({
    required int groupId,
    required int courseId,
    required int homeworkId,
  });

  Future<HomeworkResponseModel> updateHomework({
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

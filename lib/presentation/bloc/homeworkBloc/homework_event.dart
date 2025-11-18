import 'package:helium_student_flutter/data/models/planner/homework_request_model.dart';

abstract class HomeworkEvent {}

class FetchAllHomeworkEvent extends HomeworkEvent {
  final List<String>? categoryTitles;

  FetchAllHomeworkEvent({this.categoryTitles});
}

class CreateHomeworkEvent extends HomeworkEvent {
  final int groupId;
  final int courseId;
  final HomeworkRequestModel request;

  CreateHomeworkEvent({
    required this.groupId,
    required this.courseId,
    required this.request,
  });
}

class FetchHomeworkEvent extends HomeworkEvent {
  final int groupId;
  final int courseId;

  FetchHomeworkEvent({required this.groupId, required this.courseId});
}

class FetchHomeworkByIdEvent extends HomeworkEvent {
  final int groupId;
  final int courseId;
  final int homeworkId;

  FetchHomeworkByIdEvent({
    required this.groupId,
    required this.courseId,
    required this.homeworkId,
  });
}

class UpdateHomeworkEvent extends HomeworkEvent {
  final int groupId;
  final int courseId;
  final int homeworkId;
  final HomeworkRequestModel request;

  UpdateHomeworkEvent({
    required this.groupId,
    required this.courseId,
    required this.homeworkId,
    required this.request,
  });
}

class DeleteHomeworkEvent extends HomeworkEvent {
  final int groupId;
  final int courseId;
  final int homeworkId;

  DeleteHomeworkEvent({
    required this.groupId,
    required this.courseId,
    required this.homeworkId,
  });
}

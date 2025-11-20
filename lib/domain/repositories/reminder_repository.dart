import 'package:heliumedu/data/models/planner/reminder_request_model.dart';
import 'package:heliumedu/data/models/planner/reminder_response_model.dart';

abstract class ReminderRepository {
  Future<ReminderResponseModel> createReminder(ReminderRequestModel request);
  Future<List<ReminderResponseModel>> getReminders();
  Future<ReminderResponseModel> getReminderById(int reminderId);
  Future<ReminderResponseModel> updateReminder(
    int reminderId,
    ReminderRequestModel request,
  );
  Future<void> deleteReminder(int reminderId);
}

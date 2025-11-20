import 'package:heliumedu/data/datasources/reminder_remote_data_source.dart';
import 'package:heliumedu/data/models/planner/reminder_request_model.dart';
import 'package:heliumedu/data/models/planner/reminder_response_model.dart';
import 'package:heliumedu/domain/repositories/reminder_repository.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  final ReminderRemoteDataSource remoteDataSource;

  ReminderRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ReminderResponseModel> createReminder(
    ReminderRequestModel request,
  ) async {
    return await remoteDataSource.createReminder(request);
  }

  @override
  Future<List<ReminderResponseModel>> getReminders() async {
    return await remoteDataSource.getReminders();
  }

  @override
  Future<ReminderResponseModel> getReminderById(int reminderId) async {
    return await remoteDataSource.getReminderById(reminderId);
  }

  @override
  Future<ReminderResponseModel> updateReminder(
    int reminderId,
    ReminderRequestModel request,
  ) async {
    return await remoteDataSource.updateReminder(reminderId, request);
  }

  @override
  Future<void> deleteReminder(int reminderId) async {
    return await remoteDataSource.deleteReminder(reminderId);
  }
}

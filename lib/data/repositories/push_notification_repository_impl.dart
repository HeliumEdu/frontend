import 'package:heliumedu/core/app_exception.dart';
import 'package:heliumedu/data/datasources/push_notification_remote_data_source.dart';
import 'package:heliumedu/data/models/notification/push_token_request_model.dart';
import 'package:heliumedu/data/models/notification/push_token_response_model.dart';
import 'package:heliumedu/domain/repositories/push_notification_repository.dart';

class PushNotificationRepositoryImpl implements PushNotificationRepository {
  final PushNotificationRemoteDataSource remoteDataSource;

  PushNotificationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<PushTokenResponseModel> registerPushToken(
    PushTokenRequestModel request,
  ) async {
    try {
      return await remoteDataSource.registerPushToken(request);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(message: 'Failed to register push token: $e');
    }
  }

  @override
  Future<void> deletePushToken(int userId) async {
    try {
      await remoteDataSource.deletePushToken(userId);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(message: 'Failed to delete push token: $e');
    }
  }

  @override
  Future<void> deletePushTokenById(int tokenId) async {
    try {
      await remoteDataSource.deletePushTokenById(tokenId);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(message: 'Failed to delete push token: $e');
    }
  }

  @override
  Future<List<PushTokenResponseModel>> retrievePushTokens(int userId) async {
    try {
      return await remoteDataSource.retrievePushTokens(userId);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(message: 'Failed to retrieve push tokens: $e');
    }
  }
}

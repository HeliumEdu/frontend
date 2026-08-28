import 'package:heliumapp/data/models/notification/push_token_model.dart';
import 'package:heliumapp/data/models/notification/request/push_token_request_model.dart';
import 'package:heliumapp/data/sources/push_notification_remote_data_source.dart';
import 'package:heliumapp/domain/repositories/push_notification_repository.dart';

class PushTokenRepositoryImpl implements PushNotificationRepository {
  final PushNotificationRemoteDataSource remoteDataSource;

  PushTokenRepositoryImpl({required this.remoteDataSource});

  @override
  Future<PushTokenModel> registerPushToken(
    PushTokenRequestModel request,
  ) async {
    return remoteDataSource.registerPushToken(request);
  }

  @override
  Future<void> deletePushTokenById(int tokenId) async {
    return remoteDataSource.deletePushTokenById(tokenId);
  }

  @override
  Future<List<PushTokenModel>> retrievePushTokens() async {
    return remoteDataSource.retrievePushTokens();
  }
}

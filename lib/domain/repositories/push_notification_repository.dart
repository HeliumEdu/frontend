import 'package:helium_student_flutter/data/models/notification/push_token_request_model.dart';
import 'package:helium_student_flutter/data/models/notification/push_token_response_model.dart';

abstract class PushNotificationRepository {
  Future<PushTokenResponseModel> registerPushToken(
    PushTokenRequestModel request,
  );
  Future<void> deletePushToken(int userId);
  Future<void> deletePushTokenById(int tokenId);
  Future<List<PushTokenResponseModel>> retrievePushTokens(int userId);
}

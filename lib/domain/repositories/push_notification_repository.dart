// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/notification/push_token_request_model.dart';
import 'package:heliumapp/data/models/notification/push_token_response_model.dart';

abstract class PushNotificationRepository {
  Future<PushTokenResponseModel> registerPushToken(
    PushTokenRequestModel request,
  );

  Future<void> deletePushToken(int userId);

  Future<void> deletePushTokenById(int tokenId);

  Future<List<PushTokenResponseModel>> retrievePushTokens(int userId);
}

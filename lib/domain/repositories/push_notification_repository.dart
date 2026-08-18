// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:heliumapp/data/models/notification/push_token_model.dart';
import 'package:heliumapp/data/models/notification/request/push_token_request_model.dart';

abstract class PushNotificationRepository {
  Future<PushTokenModel> registerPushToken(PushTokenRequestModel request);

  Future<void> deletePushToken(int tokenId);

  Future<void> deletePushTokenById(int tokenId);

  Future<List<PushTokenModel>> retrievePushTokens();
}

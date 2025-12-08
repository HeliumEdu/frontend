// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/sources/push_notification_remote_data_source.dart';
import 'package:heliumapp/data/models/notification/push_token_request_model.dart';
import 'package:heliumapp/data/models/notification/push_token_response_model.dart';
import 'package:heliumapp/domain/repositories/push_notification_repository.dart';

class PushNotificationRepositoryImpl implements PushNotificationRepository {
  final PushNotificationRemoteDataSource remoteDataSource;

  PushNotificationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<PushTokenResponseModel> registerPushToken(
    PushTokenRequestModel request,
  ) async {
    try {
      return await remoteDataSource.registerPushToken(request);
    } on HeliumException {
      rethrow;
    } catch (e) {
      throw HeliumException(message: 'Failed to register push token: $e');
    }
  }

  @override
  Future<void> deletePushToken(int userId) async {
    try {
      await remoteDataSource.deletePushToken(userId);
    } on HeliumException {
      rethrow;
    } catch (e) {
      throw HeliumException(message: 'Failed to delete push token: $e');
    }
  }

  @override
  Future<void> deletePushTokenById(int tokenId) async {
    try {
      await remoteDataSource.deletePushTokenById(tokenId);
    } on HeliumException {
      rethrow;
    } catch (e) {
      throw HeliumException(message: 'Failed to delete push token: $e');
    }
  }

  @override
  Future<List<PushTokenResponseModel>> retrievePushTokens(int userId) async {
    try {
      return await remoteDataSource.retrievePushTokens(userId);
    } on HeliumException {
      rethrow;
    } catch (e) {
      throw HeliumException(message: 'Failed to retrieve push tokens: $e');
    }
  }
}

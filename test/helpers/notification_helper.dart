// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/notification/push_token_model.dart';
import 'package:heliumapp/data/models/notification/request/push_token_request_model.dart';

// ============================================================================
// GIVEN: Push Token JSON Fixtures
// ============================================================================

/// Creates JSON data representing a push token.
Map<String, dynamic> givenPushTokenJson({
  int id = 1,
  String deviceId = 'device_abc123',
  String token = 'fcm_token_xyz789',
  int user = 1,
  String createdAt = '2025-01-15T10:30:00Z',
}) {
  return {
    'id': id,
    'device_id': deviceId,
    'token': token,
    'user': user,
    'created_at': createdAt,
  };
}

/// Verifies that a [PushTokenModel] matches the expected JSON data.
void verifyPushTokenMatchesJson(
  PushTokenModel pushToken,
  Map<String, dynamic> json,
) {
  expect(pushToken.id, equals(json['id']));
  expect(pushToken.deviceId, equals(json['device_id']));
  expect(pushToken.token, equals(json['token']));
  expect(pushToken.user, equals(json['user']));
  expect(pushToken.createdAt, equals(json['created_at']));
}

// ============================================================================
// GIVEN: Push Token Request Model Fixtures
// ============================================================================

/// Creates a PushTokenRequestModel for testing.
/// Note: Token must be at least 20 characters for the implementation's substring operation.
PushTokenRequestModel givenPushTokenRequestModel({
  String deviceId = 'device_abc123',
  String token = 'fcm_token_xyz789_abcdefghij123456',
}) {
  return PushTokenRequestModel(deviceId: deviceId, token: token);
}

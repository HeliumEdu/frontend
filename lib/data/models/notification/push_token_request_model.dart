// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class PushTokenRequestModel {
  final String deviceId;
  final String token;
  final int user;
  final String type;

  PushTokenRequestModel({
    required this.deviceId,
    required this.token,
    required this.user,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {'device_id': deviceId, 'token': token, 'user': user, 'type': type};
  }

  factory PushTokenRequestModel.fromJson(Map<String, dynamic> json) {
    return PushTokenRequestModel(
      deviceId: json['device_id'] ?? '',
      token: json['token'] ?? '',
      user: json['user'] ?? 0,
      type: json['type'] ?? '',
    );
  }
}

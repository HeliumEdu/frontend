// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class PushTokenResponseModel {
  final int id;
  final String deviceId;
  final String token;
  final int user;
  final String? registrationId;
  final String? type;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PushTokenResponseModel({
    required this.id,
    required this.deviceId,
    required this.token,
    required this.user,
    this.registrationId,
    this.type,
    this.createdAt,
    this.updatedAt,
  });

  factory PushTokenResponseModel.fromJson(Map<String, dynamic> json) {
    return PushTokenResponseModel(
      id: json['id'] ?? 0,
      deviceId: json['device_id'] ?? '',
      token: json['token'] ?? '',
      user: json['user'] ?? 0,
      registrationId: json['registration_id'] ?? json['registrationId'],
      type: json['type'] ?? 'android',
      // Default to android if not provided
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'token': token,
      'user': user,
      'registration_id': registrationId,
      'type': type,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

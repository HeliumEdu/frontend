// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/base_model.dart';

class PushTokenModel extends BaseModel {
  final String deviceId;
  final String token;
  final int user;
  final String createdAt;

  PushTokenModel({
    required super.id,
    required this.deviceId,
    required this.token,
    required this.user,
    required this.createdAt,
  });

  factory PushTokenModel.fromJson(Map<String, dynamic> json) {
    return PushTokenModel(
      id: json['id'],
      deviceId: json['device_id'],
      token: json['token'],
      user: json['user'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'token': token,
      'user': user,
      'created_at': createdAt,
    };
  }
}

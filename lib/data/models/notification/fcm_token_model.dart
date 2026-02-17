// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class FcmTokenModel {
  final String token;
  final String timestamp;
  final bool isActive;

  FcmTokenModel({
    required this.token,
    required this.timestamp,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {'token': token, 'timestamp': timestamp, 'is_active': isActive};
  }

  FcmTokenModel copyWith({String? token, String? timestamp, bool? isActive}) {
    return FcmTokenModel(
      token: token ?? this.token,
      timestamp: timestamp ?? this.timestamp,
      isActive: isActive ?? this.isActive,
    );
  }
}

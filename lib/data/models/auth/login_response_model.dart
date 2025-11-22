// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class LoginResponseModel {
  final String token;
  final String? refreshToken;
  final int? userId;
  final String? username;
  final String? email;

  LoginResponseModel({
    required this.token,
    this.refreshToken,
    this.userId,
    this.username,
    this.email,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      token:
          json['access'] ??
          json['token'] ??
          json['auth_token'] ??
          json['access_token'] ??
          '',
      refreshToken: json['refresh'],
      userId: json['user_id'] ?? json['id'],
      username: json['username'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'refresh': refreshToken,
      'user_id': userId,
      'username': username,
      'email': email,
    };
  }
}

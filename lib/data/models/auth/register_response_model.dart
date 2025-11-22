// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class RegisterResponseModel {
  final String message;
  final int? userId;
  final String? username;
  final String? email;

  RegisterResponseModel({
    required this.message,
    this.userId,
    this.username,
    this.email,
  });

  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    return RegisterResponseModel(
      message: json['message'] ?? json['detail'] ?? 'Registration successful',
      userId: json['id'],
      username: json['username'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'id': userId,
      'username': username,
      'email': email,
    };
  }
}

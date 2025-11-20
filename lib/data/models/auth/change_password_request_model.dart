// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class ChangePasswordRequestModel {
  final String? username;
  final String? email;
  final String oldPassword;
  final String password;

  ChangePasswordRequestModel({
    this.username,
    this.email,
    required this.oldPassword,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      if (username != null) 'username': username,
      if (email != null) 'email': email,
      'old_password': oldPassword,
      'password': password,
    };
  }
}

// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class RegisterRequestModel {
  final String username;
  final String email;
  final String password;
  final String timezone;

  RegisterRequestModel({
    required this.username,
    required this.email,
    required this.password,
    required this.timezone,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'time_zone': timezone,
    };
  }
}

// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

class RegisterRequestModel {
  final String email;
  final String password;
  final String timezone;

  RegisterRequestModel({
    required this.email,
    required this.password,
    required this.timezone,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'time_zone': timezone,
    };
  }
}

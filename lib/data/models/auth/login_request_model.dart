// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

class LoginRequestModel {
  final String email;
  final String password;

  LoginRequestModel({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}

// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

class ResetPasswordRequestModel {
  final String uid;
  final String token;
  final String password;

  ResetPasswordRequestModel({
    required this.uid,
    required this.token,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'token': token,
    'password': password,
  };
}

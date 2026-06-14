// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

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

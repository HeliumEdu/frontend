// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class LoginResponseModel {
  final String access;
  final String refresh;

  LoginResponseModel({required this.access, required this.refresh});

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(access: json['access'], refresh: json['refresh']);
  }

  Map<String, dynamic> toJson() {
    return {'access': access, 'refresh': refresh};
  }
}

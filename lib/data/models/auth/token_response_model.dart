// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

class TokenResponseModel {
  final String access;
  final String refresh;

  TokenResponseModel({required this.access, required this.refresh});

  factory TokenResponseModel.fromJson(Map<String, dynamic> json) {
    return TokenResponseModel(access: json['access'], refresh: json['refresh']);
  }

  Map<String, dynamic> toJson() {
    return {'access': access, 'refresh': refresh};
  }
}

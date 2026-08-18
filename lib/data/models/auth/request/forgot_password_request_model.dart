// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

class ForgotPasswordRequestModel {
  final String email;

  ForgotPasswordRequestModel({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}

// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class ForgotPasswordResponseModel {
  final String? message;

  ForgotPasswordResponseModel({this.message});

  factory ForgotPasswordResponseModel.fromJson(Map<String, dynamic> json) {
    // API might return {} or {"detail": "..."} or custom message
    final msg = json['message'] ?? json['detail'] ?? json['status'] ?? '';
    return ForgotPasswordResponseModel(
      message: msg is String ? msg : msg?.toString(),
    );
  }
}

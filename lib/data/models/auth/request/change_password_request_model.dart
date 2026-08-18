// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

class ChangePasswordRequestModel {
  final String? oldPassword;
  final String password;

  ChangePasswordRequestModel({this.oldPassword, required this.password});

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'password': password};
    if (oldPassword != null && oldPassword!.isNotEmpty) {
      json['old_password'] = oldPassword;
    }
    return json;
  }
}

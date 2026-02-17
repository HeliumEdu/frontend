// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class DeleteAccountRequestModel {
  final String? password;

  DeleteAccountRequestModel({this.password});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (password != null && password!.isNotEmpty) {
      json['password'] = password;
    }
    return json;
  }
}

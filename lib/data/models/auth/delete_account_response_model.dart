// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class DeleteAccountResponseModel {
  final String message;

  DeleteAccountResponseModel({required this.message});

  factory DeleteAccountResponseModel.fromJson(Map<String, dynamic> json) {
    return DeleteAccountResponseModel(
      message:
          json['message'] ?? json['detail'] ?? 'Account deleted successfully',
    );
  }

  Map<String, dynamic> toJson() {
    return {'message': message};
  }
}

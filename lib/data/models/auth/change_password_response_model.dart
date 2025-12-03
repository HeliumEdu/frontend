// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:helium_mobile/data/models/auth/user_profile_model.dart';

class ChangePasswordResponseModel extends UserProfileModel {
  ChangePasswordResponseModel({
    required super.id,
    required super.username,
    required super.email,
    super.emailChanging,
    super.settings,
  });

  factory ChangePasswordResponseModel.fromJson(Map<String, dynamic> json) {
    final base = UserProfileModel.fromJson(json);
    return ChangePasswordResponseModel(
      id: base.id,
      username: base.username,
      email: base.email,
      emailChanging: base.emailChanging,
      settings: base.settings,
    );
  }
}

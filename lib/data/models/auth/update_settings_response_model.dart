// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:helium_mobile/data/models/auth/user_profile_model.dart';

class UpdateSettingsResponseModel {
  final UserSettings settings;

  UpdateSettingsResponseModel({required this.settings});

  factory UpdateSettingsResponseModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('settings')) {
      return UpdateSettingsResponseModel(
        settings: UserSettings.fromJson(
          json['settings'] as Map<String, dynamic>,
        ),
      );
    }
    return UpdateSettingsResponseModel(settings: UserSettings.fromJson(json));
  }
}

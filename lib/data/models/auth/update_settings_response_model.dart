import 'package:helium_student_flutter/data/models/auth/user_profile_model.dart';

class UpdateSettingsResponseModel {
  final UserSettings settings;

  UpdateSettingsResponseModel({required this.settings});

  factory UpdateSettingsResponseModel.fromJson(Map<String, dynamic> json) {
    // API may return full user or just settings; handle both
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

import 'package:helium_student_flutter/data/models/auth/user_profile_model.dart';

class ChangePasswordResponseModel extends UserProfileModel {
  ChangePasswordResponseModel({
    required super.id,
    required super.username,
    required super.email,
    super.emailChanging,
    super.profile,
    super.settings,
  });

  factory ChangePasswordResponseModel.fromJson(Map<String, dynamic> json) {
    final base = UserProfileModel.fromJson(json);
    return ChangePasswordResponseModel(
      id: base.id,
      username: base.username,
      email: base.email,
      emailChanging: base.emailChanging,
      profile: base.profile,
      settings: base.settings,
    );
  }
}

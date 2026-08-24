import 'package:heliumapp/data/models/auth/user_settings_model.dart';
import 'package:heliumapp/data/models/base_model.dart';

class UserModel extends BaseModel {
  final String email;
  final UserSettingsModel settings;
  final String? emailChanging;
  final bool hasUsablePassword;
  final bool hasOAuthProviders;
  final List<String> oauthProviders;

  UserModel({
    required super.id,
    required this.email,
    required this.settings,
    this.emailChanging,
    required this.hasUsablePassword,
    required this.hasOAuthProviders,
    this.oauthProviders = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      emailChanging: json['email_changing'],
      settings: UserSettingsModel.fromJson(json['settings']),
      hasUsablePassword: json['has_usable_password'] ?? true,
      hasOAuthProviders: json['has_oauth_providers'] ?? false,
      oauthProviders: (json['oauth_providers'] as List<dynamic>? ?? [])
          .map((p) => p['provider'] as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'email_changing': emailChanging,
      'settings': settings.toJson(),
      'has_usable_password': hasUsablePassword,
      'has_oauth_providers': hasOAuthProviders,
    };
  }
}

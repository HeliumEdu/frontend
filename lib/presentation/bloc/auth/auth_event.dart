// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/auth/request/update_settings_request_model.dart';

abstract class AuthEvent {}

class RegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String timezone;

  RegisterEvent({
    required this.email,
    required this.password,
    required this.timezone,
  });
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  LoginEvent({required this.email, required this.password});
}

class GoogleLoginEvent extends AuthEvent {}

class AppleLoginEvent extends AuthEvent {}

class LogoutEvent extends AuthEvent {}

class CheckAuthEvent extends AuthEvent {}

class RefreshTokenEvent extends AuthEvent {}

class FetchProfileEvent extends AuthEvent {}

class UpdateProfileEvent extends AuthEvent {
  final UpdateSettingsRequestModel request;

  UpdateProfileEvent({required this.request});
}

class EnablePrivateFeedsEvent extends AuthEvent {}

class DisablePrivateFeedsEvent extends AuthEvent {}

class ChangePasswordEvent extends AuthEvent {
  final String oldPassword;
  final String newPassword;

  ChangePasswordEvent({required this.oldPassword, required this.newPassword});
}

class ForgotPasswordEvent extends AuthEvent {
  final String email;

  ForgotPasswordEvent({required this.email});
}

class DeleteAccountEvent extends AuthEvent {
  final String? password;

  DeleteAccountEvent({this.password});
}

class VerifyEmailEvent extends AuthEvent {
  final String email;
  final String code;

  VerifyEmailEvent({required this.email, required this.code});
}

class ResendVerificationEvent extends AuthEvent {
  final String email;

  ResendVerificationEvent({required this.email});
}

class DeleteExampleScheduleEvent extends AuthEvent {}

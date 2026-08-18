import 'package:heliumapp/core/google_account_store.dart';
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

class GoogleLoginEvent extends AuthEvent {
  /// Confirms the remembered Google account (iOS only): true to continue as
  /// it, false for a different account, null if dismissed without a choice.
  final Future<bool?> Function(RememberedGoogleAccount)? onChooseAccount;

  GoogleLoginEvent({this.onChooseAccount});
}

class AppleLoginEvent extends AuthEvent {}

class MicrosoftLoginEvent extends AuthEvent {}


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
  final String? oldPassword;
  final String newPassword;

  ChangePasswordEvent({this.oldPassword, required this.newPassword});
}

class ChangeEmailEvent extends AuthEvent {
  final String newEmail;
  final String oldPassword;

  ChangeEmailEvent({required this.newEmail, required this.oldPassword});
}

class ForgotPasswordEvent extends AuthEvent {
  final String email;

  ForgotPasswordEvent({required this.email});
}

class ResetPasswordEvent extends AuthEvent {
  final String uid;
  final String token;
  final String password;

  ResetPasswordEvent({
    required this.uid,
    required this.token,
    required this.password,
  });
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

/// Triggers schedule data refresh on listening screens (e.g., after import or delete)
class RefreshScheduleDataEvent extends AuthEvent {}

import 'package:heliumapp/core/google_account_store.dart';
import 'package:heliumapp/core/oauth_sign_in_service.dart';
import 'package:heliumapp/data/models/auth/request/update_settings_request_model.dart';

abstract class AuthEvent {}

class RegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String timezone;
  final String language;

  RegisterEvent({
    required this.email,
    required this.password,
    required this.timezone,
    required this.language,
  });
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  LoginEvent({required this.email, required this.password});
}

/// Asks whether to link the provider the sign-in removed: true to link it now.
typedef RelinkProviderPrompt = Future<bool> Function(String providerLabel, {required bool removed});

class GoogleLoginEvent extends AuthEvent {
  /// Confirms the remembered Google account (iOS only): true to continue as
  /// it, false for a different account, null if dismissed without a choice.
  final Future<bool?> Function(RememberedGoogleAccount)? onChooseAccount;
  final RelinkProviderPrompt onRelinkProvider;

  GoogleLoginEvent({this.onChooseAccount, required this.onRelinkProvider});
}

class AppleLoginEvent extends AuthEvent {
  final RelinkProviderPrompt onRelinkProvider;

  AppleLoginEvent({required this.onRelinkProvider});
}

class MicrosoftLoginEvent extends AuthEvent {
  final RelinkProviderPrompt onRelinkProvider;

  MicrosoftLoginEvent({required this.onRelinkProvider});
}


class LogoutEvent extends AuthEvent {}

class ForcedLogoutEvent extends AuthEvent {}

class CheckAuthEvent extends AuthEvent {}

class RefreshTokenEvent extends AuthEvent {}

class FetchProfileEvent extends AuthEvent {}

class UpdateProfileEvent extends AuthEvent {
  final UpdateSettingsRequestModel request;

  UpdateProfileEvent({required this.request});
}

class EnablePrivateFeedsEvent extends AuthEvent {}

class DisablePrivateFeedsEvent extends AuthEvent {}

class CreateApiTokenEvent extends AuthEvent {}

class RevokeApiTokenEvent extends AuthEvent {}

class RemoveOAuthProviderEvent extends AuthEvent {
  final OAuthProvider provider;

  RemoveOAuthProviderEvent({required this.provider});
}

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

class DescribeAuthorizationEvent extends AuthEvent {
  final String query;

  DescribeAuthorizationEvent({required this.query});
}

class DecideAuthorizationEvent extends AuthEvent {
  final String query;
  final bool allow;

  final List<String>? scopes;

  DecideAuthorizationEvent({
    required this.query,
    required this.allow,
    this.scopes,
  });
}

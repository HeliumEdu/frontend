import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class RegisterEvent extends AuthEvent {
  final String username;
  final String email;
  final String password;
  final String timezone;

  const RegisterEvent({
    required this.username,
    required this.email,
    required this.password,
    required this.timezone,
  });

  @override
  List<Object?> get props => [username, email, password, timezone];
}

class LoginEvent extends AuthEvent {
  final String username;
  final String password;

  const LoginEvent({required this.username, required this.password});

  @override
  List<Object?> get props => [username, password];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

class BlacklistTokenEvent extends AuthEvent {
  final String refreshToken;

  const BlacklistTokenEvent({required this.refreshToken});

  @override
  List<Object?> get props => [refreshToken];
}

class GetProfileEvent extends AuthEvent {
  const GetProfileEvent();
}

class DeleteAccountEvent extends AuthEvent {
  final String password;

  const DeleteAccountEvent({required this.password});

  @override
  List<Object?> get props => [password];
}

class UpdatePhoneEvent extends AuthEvent {
  final String phone;
  final int? verificationCode;

  const UpdatePhoneEvent({required this.phone, this.verificationCode});

  @override
  List<Object?> get props => [phone, verificationCode];
}

class ChangePasswordEvent extends AuthEvent {
  final String oldPassword;
  final String newPassword;
  final String? username;
  final String? email;

  const ChangePasswordEvent({
    required this.oldPassword,
    required this.newPassword,
    this.username,
    this.email,
  });

  @override
  List<Object?> get props => [oldPassword, newPassword, username, email];
}

class ResetAuthEvent extends AuthEvent {
  const ResetAuthEvent();
}

class RefreshTokenEvent extends AuthEvent {
  const RefreshTokenEvent();
}

class CheckAuthEvent extends AuthEvent {
  const CheckAuthEvent();
}

class ForgotPasswordEvent extends AuthEvent {
  final String email;

  const ForgotPasswordEvent({required this.email});

  @override
  List<Object?> get props => [email];
}

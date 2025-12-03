// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:equatable/equatable.dart';
import 'package:helium_mobile/data/models/auth/user_profile_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthRegistrationSuccess extends AuthState {
  final String message;

  const AuthRegistrationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthLoginSuccess extends AuthState {
  final String accessToken;

  const AuthLoginSuccess({
    required this.accessToken
  });

  @override
  List<Object?> get props => [accessToken];
}

class AuthLogoutSuccess extends AuthState {
  final String message;

  const AuthLogoutSuccess({this.message = 'Logged out successfully'});

  @override
  List<Object?> get props => [message];
}

class AuthTokenBlacklisted extends AuthState {
  final String message;

  const AuthTokenBlacklisted({this.message = 'Token blacklisted successfully'});

  @override
  List<Object?> get props => [message];
}

class AuthProfileLoaded extends AuthState {
  final String username;
  final String email;
  final String? phone;

  const AuthProfileLoaded({
    required this.username,
    required this.email,
    this.phone,
  });

  @override
  List<Object?> get props => [username, email, phone];
}

class AuthAccountDeletedSuccess extends AuthState {
  final String message;

  const AuthAccountDeletedSuccess({
    this.message = 'Account deleted successfully',
  });

  @override
  List<Object?> get props => [message];
}

class AuthPhoneUpdateSuccess extends AuthState {
  final String? phone;
  final String? phoneChanging;
  final bool phoneVerified;
  final String message;

  const AuthPhoneUpdateSuccess({
    this.phone,
    this.phoneChanging,
    required this.phoneVerified,
    this.message = 'Phone number updated successfully',
  });

  @override
  List<Object?> get props => [phone, phoneChanging, phoneVerified, message];
}

class AuthPasswordChangeSuccess extends AuthState {
  final String message;

  const AuthPasswordChangeSuccess({
    this.message = 'Password changed successfully',
  });

  @override
  List<Object?> get props => [message];
}

class AuthTokenRefreshed extends AuthState {
  final String accessToken;
  final String message;

  const AuthTokenRefreshed({
    required this.accessToken,
    this.message = 'Access token refreshed successfully',
  });

  @override
  List<Object?> get props => [accessToken, message];
}

class AuthAuthenticated extends AuthState {
  final String message;

  const AuthAuthenticated({this.message = 'User is authenticated'});

  @override
  List<Object?> get props => [message];
}

class AuthUnauthenticated extends AuthState {
  final String message;

  const AuthUnauthenticated({this.message = 'User is not authenticated'});

  @override
  List<Object?> get props => [message];
}

class AuthError extends AuthState {
  final String message;
  final String? code;

  const AuthError({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

class AuthForgotPasswordSent extends AuthState {
  final String message;

  const AuthForgotPasswordSent({
    this.message = 'Password reset link sent. Please check your email.',
  });

  @override
  List<Object?> get props => [message];
}

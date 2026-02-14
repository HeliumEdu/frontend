// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/auth/user_model.dart';

abstract class AuthState {
  final String? message;

  AuthState({this.message});
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthProfileFetched extends AuthState {
  final UserModel user;

  AuthProfileFetched({required this.user});
}

class AuthProfileUpdated extends AuthState {
  final UserModel user;

  AuthProfileUpdated({required this.user});
}

class AuthRegistered extends AuthState {
  final String? username;

  AuthRegistered({this.username});
}

class AuthEmailVerified extends AuthState {}

class AuthVerificationResent extends AuthState {}

class AuthAccountInactive extends AuthState {
  final String username;

  AuthAccountInactive({required super.message, required this.username});
}

class AuthLoggedIn extends AuthState {}

class AuthLoggedOut extends AuthState {}

class AuthAccountDeleted extends AuthState {}

class AuthPasswordChanged extends AuthState {}

class AuthPasswordReset extends AuthState {}

class AuthAuthenticated extends AuthState {}

class AuthTokenRefreshed extends AuthState {}

class AuthUnauthenticated extends AuthState {
  AuthUnauthenticated({required super.message});
}

class AuthError extends AuthState {
  final String? code;
  final int? httpStatusCode;

  AuthError({required super.message, this.code, this.httpStatusCode});
}

class AuthProfileError extends AuthError {
  AuthProfileError({required super.message});
}

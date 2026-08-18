// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:heliumapp/core/api_error_parser.dart';
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
  final String? email;

  AuthRegistered({this.email});
}

class AuthVerificationResent extends AuthState {}

class AuthAccountInactive extends AuthState {
  final String email;

  AuthAccountInactive({required super.message, required this.email});
}

class AuthLoggedIn extends AuthState {}

class AuthLoggedOut extends AuthState {}

class AuthAccountDeleted extends AuthState {}

class AuthScheduleDataRefreshed extends AuthState {}

class AuthPasswordChanged extends AuthState {}

class AuthEmailChangeRequested extends AuthState {
  final String newEmail;

  AuthEmailChangeRequested({required this.newEmail});
}

class AuthEmailChangeCancelled extends AuthState {}

class AuthPasswordReset extends AuthState {}

class AuthAuthenticated extends AuthState {}

class AuthTokenRefreshed extends AuthState {}

class AuthUnauthenticated extends AuthState {
  AuthUnauthenticated({required super.message});
}

class AuthError extends AuthState {
  final String? code;
  final int? httpStatusCode;
  final ParsedApiError? parsedError;

  AuthError({
    required super.message,
    this.code,
    this.httpStatusCode,
    this.parsedError,
  });

  /// Returns the error message for a specific field, or null if none
  String? getFieldError(String fieldName) => parsedError?.getFieldError(fieldName);

  /// Whether this error has field-specific errors
  bool get hasFieldErrors => parsedError?.hasFieldErrors ?? false;
}


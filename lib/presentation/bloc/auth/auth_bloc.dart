// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:bloc/bloc.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/models/auth/change_password_request_model.dart';
import 'package:heliumapp/data/models/auth/delete_account_request_model.dart';
import 'package:heliumapp/data/models/auth/forgot_password_request_model.dart';
import 'package:heliumapp/data/models/auth/login_request_model.dart';
import 'package:heliumapp/data/models/auth/refresh_token_request_model.dart';
import 'package:heliumapp/data/models/auth/register_request_model.dart';
import 'package:heliumapp/domain/repositories/auth_repository.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_event.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_state.dart';
import 'package:logging/logging.dart';

final log = Logger('HeliumLogger');

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final DioClient dioClient;

  AuthBloc({required this.authRepository, required this.dioClient})
    : super(const AuthInitial()) {
    on<RegisterEvent>(_onRegister);
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<BlacklistTokenEvent>(_onBlacklistToken);
    on<GetProfileEvent>(_onGetProfile);
    on<DeleteAccountEvent>(_onDeleteAccount);
    on<ChangePasswordEvent>(_onChangePassword);
    on<ForgotPasswordEvent>(_onForgotPassword);
    on<RefreshTokenEvent>(_onRefreshToken);
    on<CheckAuthEvent>(_onCheckAuth);
    on<ResetAuthEvent>(_onReset);
  }

  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    try {
      final request = RegisterRequestModel(
        username: event.username,
        email: event.email,
        password: event.password,
        timezone: event.timezone,
      );

      final response = await authRepository.register(request);

      emit(AuthRegistrationSuccess(message: response.message));
    } on ValidationException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } on NetworkException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } on ServerException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } on HeliumException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onChangePassword(
    ChangePasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final request = ChangePasswordRequestModel(
        username: event.username,
        email: event.email,
        oldPassword: event.oldPassword,
        password: event.newPassword,
      );

      await authRepository.changePassword(request);

      emit(const AuthPasswordChangeSuccess());
    } on ValidationException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } on NetworkException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } on ServerException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } on UnauthorizedException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } on HeliumException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onForgotPassword(
    ForgotPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final request = ForgotPasswordRequestModel(email: event.email);
      await authRepository.forgotPassword(request);
      emit(const AuthForgotPasswordSent());
    } on ValidationException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } on NetworkException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } on ServerException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } on HeliumException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    try {
      final request = LoginRequestModel(
        username: event.username,
        password: event.password,
      );

      final response = await authRepository.login(request);

      emit(AuthLoginSuccess(accessToken: response.access));
    } on ValidationException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } on NetworkException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } on ServerException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } on UnauthorizedException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } on HeliumException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    try {
      await authRepository.logout();
      emit(const AuthLogoutSuccess());
    } on NetworkException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } on ServerException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } on HeliumException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onBlacklistToken(
    BlacklistTokenEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await authRepository.blacklistToken(event.refreshToken);
      emit(const AuthTokenBlacklisted());
    } on NetworkException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } on ServerException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } on HeliumException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onGetProfile(
    GetProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final profile = await authRepository.getProfile();
      emit(AuthProfileLoaded(username: profile.username, email: profile.email));
    } on NetworkException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } on ServerException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } on HeliumException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onDeleteAccount(
    DeleteAccountEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final request = DeleteAccountRequestModel(password: event.password);
      final response = await authRepository.deleteAccount(request);

      emit(AuthAccountDeletedSuccess(message: response.message));
    } on ValidationException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } on NetworkException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } on ServerException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } on UnauthorizedException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } on HeliumException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onRefreshToken(
    RefreshTokenEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final refreshToken = await dioClient.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        emit(const AuthUnauthenticated(message: 'No refresh token found'));
        return;
      }

      final request = RefreshTokenRequestModel(refresh: refreshToken);
      final response = await authRepository.refreshToken(request);

      emit(AuthTokenRefreshed(accessToken: response.access));
    } on NetworkException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } on ServerException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } on UnauthorizedException {
      await dioClient.clearStorage();
      emit(
        const AuthUnauthenticated(
          message: 'Session expired. Please login again.',
        ),
      );
    } on HeliumException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onCheckAuth(
    CheckAuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final accessToken = await dioClient.getAccessToken();
      final refreshToken = await dioClient.getRefreshToken();

      if (accessToken != null && accessToken.isNotEmpty) {
        try {
          emit(AuthAuthenticated());
        } catch (e) {
          if (refreshToken != null && refreshToken.isNotEmpty) {
            log.info(' Token seems expired, attempting to refresh...');
            add(const RefreshTokenEvent());
          } else {
            emit(
              const AuthUnauthenticated(
                message: 'Token expired and no refresh token available',
              ),
            );
          }
        }
      } else {
        emit(const AuthUnauthenticated(message: 'No authentication token'));
      }
    } catch (e) {
      emit(const AuthUnauthenticated(message: 'Authentication check failed'));
    }
  }

  void _onReset(ResetAuthEvent event, Emitter<AuthState> emit) {
    emit(const AuthInitial());
  }
}

// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/oauth_sign_in_service.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/auth/login_request_model.dart';
import 'package:heliumapp/data/models/auth/register_request_model.dart';
import 'package:heliumapp/data/models/auth/request/change_password_request_model.dart';
import 'package:heliumapp/data/models/auth/request/delete_account_request_model.dart';
import 'package:heliumapp/data/models/auth/request/forgot_password_request_model.dart';
import 'package:heliumapp/data/models/auth/request/refresh_token_request_model.dart';
import 'package:heliumapp/data/models/auth/request/update_settings_request_model.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/domain/repositories/auth_repository.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_event.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_state.dart';
import 'package:logging/logging.dart';

final _log = Logger('presentation.bloc');

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final DioClient dioClient;

  AuthBloc({required this.authRepository, required this.dioClient})
    : super(AuthInitial()) {
    on<RegisterEvent>(_onRegister);
    on<VerifyEmailEvent>(_onVerifyEmail);
    on<ResendVerificationEvent>(_onResendVerification);
    on<LoginEvent>(_onLogin);
    on<GoogleLoginEvent>(_onGoogleLogin);
    on<AppleLoginEvent>(_onAppleLogin);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthEvent>(_onCheckAuth);
    on<RefreshTokenEvent>(_onRefreshToken);
    on<FetchProfileEvent>(_onFetchProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<EnablePrivateFeedsEvent>(_onEnablePrivateFeeds);
    on<DisablePrivateFeedsEvent>(_onDisablePrivateFeeds);
    on<ChangePasswordEvent>(_onChangePassword);
    on<ForgotPasswordEvent>(_onForgotPassword);
    on<DeleteAccountEvent>(_onDeleteAccount);
    on<DeleteExampleScheduleEvent>(_onDeleteExampleSchedule);
  }

  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final request = RegisterRequestModel(
        email: event.email,
        password: event.password,
        timezone: event.timezone,
      );

      final response = await authRepository.register(request);

      emit(AuthRegistered(username: response.username));
    } on HeliumException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onVerifyEmail(
    VerifyEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await authRepository.verifyEmail(event.username, event.code);

      emit(AuthLoggedIn());
    } on HeliumException catch (e) {
      // Show friendly message for verification errors (400/404) to avoid revealing user existence
      if (e.httpStatusCode == 400 || e.httpStatusCode == 404) {
        emit(
          AuthError(
            message:
                'That code doesn\'t look right. Please check and try again.',
          ),
        );
      } else {
        emit(AuthError(message: e.message));
      }
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onResendVerification(
    ResendVerificationEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await authRepository.resendVerificationEmail(event.username);

      emit(AuthVerificationResent());
    } on HeliumException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onChangePassword(
    ChangePasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final request = ChangePasswordRequestModel(
        oldPassword: event.oldPassword,
        password: event.newPassword,
      );

      await authRepository.changePassword(request);

      emit(AuthPasswordChanged());
    } on HeliumException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onForgotPassword(
    ForgotPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final request = ForgotPasswordRequestModel(email: event.email);
      await authRepository.forgotPassword(request);
      emit(AuthPasswordReset());
    } on HeliumException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final request = LoginRequestModel(
        username: event.username,
        password: event.password,
      );

      await authRepository.login(request);

      emit(AuthLoggedIn());
    } on HeliumException catch (e) {
      // Check for inactive account error
      if (e.code == 'account_inactive') {
        final username = e.details is Map
            ? e.details['username'] ?? event.username
            : event.username;
        emit(AuthAccountInactive(message: e.message, username: username));
      } else {
        emit(
          AuthError(
            message: e.message,
            code: e.code,
            httpStatusCode: e.httpStatusCode,
          ),
        );
      }
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onOAuthLogin(
    String provider,
    Future<String?> Function() signInMethod,
    Future<void> Function(String) backendLogin,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      _log.info('Starting $provider Sign-In flow');

      final firebaseIdToken = await signInMethod();

      if (firebaseIdToken == null) {
        _log.info('$provider Sign-In cancelled by user');
        emit(AuthInitial());
        return;
      }

      _log.info('Firebase ID token obtained, authenticating with backend');

      // Send Firebase ID token to backend and get JWT tokens
      await backendLogin(firebaseIdToken);

      _log.info('$provider Sign-In successful');
      emit(AuthLoggedIn());
    } on HeliumException catch (e) {
      _log.warning('$provider Sign-In failed: ${e.message}');
      emit(
        AuthError(
          message: e.message,
          code: e.code,
          httpStatusCode: e.httpStatusCode,
        ),
      );
    } catch (e, s) {
      _log.severe('$provider Sign-In error', e, s);
      emit(AuthError(message: '$provider Sign-In failed: $e'));
    }
  }

  Future<void> _onGoogleLogin(
    GoogleLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    final oauthSignInService = OAuthSignInService();
    await _onOAuthLogin(
      'Google',
      oauthSignInService.signInWithGoogle,
      authRepository.loginWithGoogle,
      emit,
    );
  }

  Future<void> _onAppleLogin(
    AppleLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    final oauthSignInService = OAuthSignInService();
    await _onOAuthLogin(
      'Apple',
      oauthSignInService.signInWithApple,
      authRepository.loginWithApple,
      emit,
    );
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      await authRepository.logout();
      emit(AuthLoggedOut());
    } on HeliumException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onFetchProfile(
    FetchProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await authRepository.getUser();
      emit(AuthProfileFetched(user: user));
    } on HeliumException catch (e) {
      emit(AuthError(message: e.message));
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

      if (accessToken?.isNotEmpty ?? false) {
        try {
          await dioClient.fetchSettings();

          emit(AuthAuthenticated());
        } catch (e) {
          if (refreshToken?.isNotEmpty ?? false) {
            _log.info('Access token seems expired, will attempt refresh ...');
            add(RefreshTokenEvent());
          } else {
            emit(
              AuthUnauthenticated(
                message: 'Access token expired, no refresh token found',
              ),
            );
          }
        }
      } else {
        emit(AuthUnauthenticated(message: 'No access token found'));
      }
    } catch (e) {
      emit(AuthUnauthenticated(message: 'Authentication check failed'));
    }
  }

  Future<void> _onRefreshToken(
    RefreshTokenEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final refreshToken = await dioClient.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        emit(AuthUnauthenticated(message: 'No refresh token found'));
        return;
      }

      final request = RefreshTokenRequestModel(refresh: refreshToken);
      await authRepository.refreshToken(request);

      emit(AuthTokenRefreshed());
    } on UnauthorizedException {
      await dioClient.clearStorage();
      emit(AuthUnauthenticated(message: 'Please login to continue.'));
    } on HeliumException catch (e) {
      await dioClient.clearStorage();
      emit(AuthError(message: e.message));
    } catch (e) {
      await dioClient.clearStorage();
      emit(AuthError(message: 'An unexpected error occurred: $e'));
    } finally {}
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await authRepository.updateUserSettings(event.request);
      final UserModel user = await authRepository.getUser();
      await dioClient.saveSettings(user.settings);

      emit(AuthProfileUpdated(user: user));
    } on HeliumException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onEnablePrivateFeeds(
    EnablePrivateFeedsEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await authRepository.enablePrivateFeeds();
      final UserModel user = await authRepository.getUser();

      emit(AuthProfileFetched(user: user));
    } on HeliumException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onDisablePrivateFeeds(
    DisablePrivateFeedsEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await authRepository.disablePrivateFeeds();
      final UserModel user = await authRepository.getUser();

      emit(AuthProfileFetched(user: user));
    } on HeliumException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onDeleteAccount(
    DeleteAccountEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final request = DeleteAccountRequestModel(password: event.password);
      await authRepository.deleteAccount(request);

      emit(AuthAccountDeleted());
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

  Future<void> _onDeleteExampleSchedule(
    DeleteExampleScheduleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await authRepository.deleteExampleSchedule();
      await authRepository.updateUserSettings(
        UpdateSettingsRequestModel(showGettingStarted: false),
      );

      emit(AuthExampleScheduleDeleted());
    } on HeliumException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred: $e'));
    }
  }
}

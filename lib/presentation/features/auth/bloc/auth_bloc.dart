import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/locale_notifier.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/core/last_oauth_provider_store.dart';
import 'package:heliumapp/core/oauth_sign_in_service.dart';
import 'package:heliumapp/data/models/auth/login_request_model.dart';
import 'package:heliumapp/data/models/auth/register_request_model.dart';
import 'package:heliumapp/data/models/auth/request/change_email_request_model.dart';
import 'package:heliumapp/data/models/auth/request/change_password_request_model.dart';
import 'package:heliumapp/data/models/auth/request/delete_account_request_model.dart';
import 'package:heliumapp/data/models/auth/request/forgot_password_request_model.dart';
import 'package:heliumapp/data/models/auth/request/refresh_token_request_model.dart';
import 'package:heliumapp/data/models/auth/request/reset_password_request_model.dart';
import 'package:heliumapp/data/models/auth/token_response_model.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/domain/repositories/auth_repository.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_event.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:logging/logging.dart';

final _log = Logger('presentation.bloc');

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final DioClient dioClient;
  final OAuthSignInService _oauthSignInService;

  AuthBloc({
    required this.authRepository,
    required this.dioClient,
    OAuthSignInService? oauthSignInService,
  }) : _oauthSignInService = oauthSignInService ?? OAuthSignInService(),
       super(AuthInitial()) {
    dioClient.addForcedLogoutListener(_onForcedLogoutSignal);

    on<RegisterEvent>(_onRegister);
    on<VerifyEmailEvent>(_onVerifyEmail);
    on<ResendVerificationEvent>(_onResendVerification);
    on<LoginEvent>(_onLogin);
    on<GoogleLoginEvent>(_onGoogleLogin);
    on<AppleLoginEvent>(_onAppleLogin);
    on<MicrosoftLoginEvent>(_onMicrosoftLogin);

    on<LogoutEvent>(_onLogout);
    on<ForcedLogoutEvent>(_onForcedLogout);
    on<CheckAuthEvent>(_onCheckAuth);
    on<RefreshTokenEvent>(_onRefreshToken);
    on<FetchProfileEvent>(_onFetchProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<EnablePrivateFeedsEvent>(_onEnablePrivateFeeds);
    on<DisablePrivateFeedsEvent>(_onDisablePrivateFeeds);
    on<CreateApiTokenEvent>(_onCreateApiToken);
    on<RevokeApiTokenEvent>(_onRevokeApiToken);
    on<RemoveOAuthProviderEvent>(_onRemoveOAuthProvider);
    on<ChangePasswordEvent>(_onChangePassword);
    on<ChangeEmailEvent>(_onChangeEmail);
    on<ForgotPasswordEvent>(_onForgotPassword);
    on<ResetPasswordEvent>(_onResetPassword);
    on<DeleteAccountEvent>(_onDeleteAccount);
    on<DeleteExampleScheduleEvent>(_onDeleteExampleSchedule);
    on<RefreshScheduleDataEvent>(_onRefreshScheduleData);
    on<DescribeAuthorizationEvent>(_onDescribeAuthorization);
    on<DecideAuthorizationEvent>(_onDecideAuthorization);
  }

  @override
  Future<void> close() {
    dioClient.removeForcedLogoutListener(_onForcedLogoutSignal);
    return super.close();
  }

  static String get invalidAuthorizationMessage =>
      LocaleNotifier().localizations.connectInvalidRequestMessage;

  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final request = RegisterRequestModel(
        email: event.email,
        password: event.password,
        timezone: event.timezone,
        language: event.language,
      );

      final response = await authRepository.register(request);

      emit(AuthRegistered(email: response.email));
    } on HeliumException catch (e) {
      emit(AuthError(
        message: e.displayMessage,
        code: e.code,
        httpStatusCode: e.httpStatusCode,
        parsedError: e.parsedError,
      ));
    } catch (e) {
      emit(AuthError(message: HeliumException.unexpectedErrorMessage));
    }
  }

  Future<void> _onVerifyEmail(
    VerifyEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await authRepository.verifyEmail(event.email, event.code);

      emit(AuthLoggedIn());
    } on HeliumException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: HeliumException.unexpectedErrorMessage));
    }
  }

  Future<void> _onResendVerification(
    ResendVerificationEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await authRepository.resendVerificationEmail(event.email);

      emit(AuthVerificationResent());
    } on HeliumException catch (e) {
      emit(AuthError(
        message: e.displayMessage,
        code: e.code,
        httpStatusCode: e.httpStatusCode,
        parsedError: e.parsedError,
      ));
    } catch (e) {
      emit(AuthError(message: HeliumException.unexpectedErrorMessage));
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
      emit(AuthError(
        message: e.displayMessage,
        code: e.code,
        httpStatusCode: e.httpStatusCode,
        parsedError: e.parsedError,
      ));
    } catch (e) {
      emit(AuthError(message: HeliumException.unexpectedErrorMessage));
    }
  }

  Future<void> _onChangeEmail(
    ChangeEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final request = ChangeEmailRequestModel(
        email: event.newEmail,
        oldPassword: event.oldPassword,
      );

      final user = await authRepository.changeEmail(request);

      // If emailChanging is null/empty, the change was cancelled (user submitted current email)
      if (user.emailChanging == null || user.emailChanging!.isEmpty) {
        emit(AuthEmailChangeCancelled());
      } else {
        emit(AuthEmailChangeRequested(newEmail: event.newEmail));
      }
    } on HeliumException catch (e) {
      emit(AuthError(
        message: e.displayMessage,
        code: e.code,
        httpStatusCode: e.httpStatusCode,
        parsedError: e.parsedError,
      ));
    } catch (e) {
      emit(AuthError(message: HeliumException.unexpectedErrorMessage));
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
      emit(AuthError(
        message: e.displayMessage,
        code: e.code,
        httpStatusCode: e.httpStatusCode,
        parsedError: e.parsedError,
      ));
    } catch (e) {
      emit(AuthError(message: HeliumException.unexpectedErrorMessage));
    }
  }

  Future<void> _onResetPassword(
    ResetPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final request = ResetPasswordRequestModel(
        uid: event.uid,
        token: event.token,
        password: event.password,
      );
      await authRepository.confirmPasswordReset(request);
      emit(AuthLoggedIn());
    } on HeliumException catch (e) {
      emit(AuthError(
        message: e.displayMessage,
        code: e.code,
        httpStatusCode: e.httpStatusCode,
        parsedError: e.parsedError,
      ));
    } catch (e) {
      emit(AuthError(message: HeliumException.unexpectedErrorMessage));
    }
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final request = LoginRequestModel(
        email: event.email,
        password: event.password,
      );

      await authRepository.login(request);

      await LastOAuthProviderStore().clearLastUsedProvider();

      emit(AuthLoggedIn());
    } on HeliumException catch (e) {
      // Check for inactive account error
      if (e.code == 'account_inactive') {
        final email = e.details is Map
            ? e.details['email'] ?? event.email
            : event.email;
        emit(AuthAccountInactive(message: e.message, email: email));
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
      emit(AuthError(message: HeliumException.unexpectedErrorMessage));
    }
  }

  Future<void> _onOAuthLogin(
    String provider,
    Future<String?> Function() signInMethod,
    Future<TokenResponseModel> Function(String) backendLogin,
    RelinkProviderPrompt onRelinkProvider,
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
      final loginResponse = await backendLogin(firebaseIdToken);

      _log.info('$provider Sign-In successful');

      final linkedProviders = [?_oauthSignInService.takeLinkedProvider()];
      final notLinkedProviders = <String>[];
      final failedLinkProvider = _oauthSignInService.takeFailedLinkProvider();
      final providersToLink = [
        if (failedLinkProvider != null) (provider: failedLinkProvider, removed: false),
        for (final name in loginResponse.unlinkedProviders)
          if (OAuthProvider.values.asNameMap()[name] case final unlinked?) (provider: unlinked, removed: true),
      ];
      for (final (:provider, :removed) in providersToLink) {
        if (await _relinkProvider(provider, removed, onRelinkProvider)) {
          linkedProviders.add(provider.label);
        } else {
          notLinkedProviders.add(provider.label);
        }
      }

      emit(
        AuthLoggedIn(
          linkedProviders: linkedProviders,
          notLinkedProviders: notLinkedProviders,
        ),
      );
    } on HeliumException catch (e) {
      _log.warning('$provider Sign-In failed: ${e.runtimeType} code=${e.code}');
      emit(
        AuthError(
          message: e.message,
          code: e.code,
          httpStatusCode: e.httpStatusCode,
        ),
      );
    } catch (e, s) {
      _log.severe('$provider Sign-In error', e, s);
      emit(
        AuthError(message: LocaleNotifier().localizations.authOAuthSignInFailedMessage(provider)),
      );
    }
  }

  Future<bool> _relinkProvider(
    OAuthProvider provider,
    bool removed,
    RelinkProviderPrompt onRelinkProvider,
  ) async {
    if (!await onRelinkProvider(provider.label, removed: removed)) {
      _log.info('${provider.label} re-link declined');
      return false;
    }

    final firebaseIdToken = await _oauthSignInService.linkProvider(provider);
    if (firebaseIdToken == null) return false;

    try {
      await authRepository.syncOAuthProviders(firebaseIdToken);
    } on HeliumException catch (e) {
      _log.warning(
        '${provider.label} linked, but the sync failed: ${e.runtimeType} '
        'code=${e.code}; it syncs at the next sign-in',
      );
    }

    return true;
  }

  Future<void> _onGoogleLogin(
    GoogleLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    await _onOAuthLogin(
      'Google',
      () => _oauthSignInService.signInWithGoogle(
        onChooseAccount: event.onChooseAccount,
      ),
      authRepository.loginWithGoogle,
      event.onRelinkProvider,
      emit,
    );
  }

  Future<void> _onAppleLogin(
    AppleLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    await _onOAuthLogin(
      'Apple',
      _oauthSignInService.signInWithApple,
      authRepository.loginWithApple,
      event.onRelinkProvider,
      emit,
    );
  }

  Future<void> _onMicrosoftLogin(
    MicrosoftLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    await _onOAuthLogin(
      'Microsoft',
      _oauthSignInService.signInWithMicrosoft,
      authRepository.loginWithMicrosoft,
      event.onRelinkProvider,
      emit,
    );
  }


  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      await _oauthSignInService.signOut();
      await authRepository.logout();
      emit(AuthLoggedOut());
    } on HeliumException catch (e) {
      emit(AuthError(
        message: e.displayMessage,
        code: e.code,
        httpStatusCode: e.httpStatusCode,
        parsedError: e.parsedError,
      ));
    } catch (e) {
      emit(AuthError(message: HeliumException.unexpectedErrorMessage));
    }
  }

  void _onForcedLogoutSignal() => add(ForcedLogoutEvent());

  Future<void> _onForcedLogout(
    ForcedLogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    await _oauthSignInService.signOut();
    emit(AuthLoggedOut());
  }

  Future<void> _onFetchProfile(
    FetchProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await authRepository.getUser();
      emit(AuthProfileFetched(user: user));
      unawaited(AnalyticsService().setUserProperty(
        name: 'uses_private_feeds',
        value: user.settings.privateSlug != null ? 'true' : 'false',
      ));
    } on HeliumException catch (e) {
      emit(AuthError(
        message: e.displayMessage,
        code: e.code,
        httpStatusCode: e.httpStatusCode,
        parsedError: e.parsedError,
      ));
    } catch (e) {
      emit(AuthError(message: HeliumException.unexpectedErrorMessage));
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
          await dioClient.getSettings(forceRefresh: true);

          emit(AuthAuthenticated());
        } catch (e) {
          if (refreshToken?.isNotEmpty ?? false) {
            _log.info('Access token seems expired, will attempt refresh ...');
            add(RefreshTokenEvent());
          } else {
            emit(AuthUnauthenticated());
          }
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
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
        emit(AuthUnauthenticated());
        return;
      }

      final request = RefreshTokenRequestModel(refresh: refreshToken);
      await authRepository.refreshToken(request);

      emit(AuthTokenRefreshed());
    } on UnauthorizedException {
      await dioClient.clearStorage();
      emit(AuthUnauthenticated());
    } on HeliumException catch (e) {
      emit(AuthError(
        message: e.displayMessage,
        code: e.code,
        httpStatusCode: e.httpStatusCode,
        parsedError: e.parsedError,
      ));
    } catch (e) {
      emit(AuthError(message: HeliumException.unexpectedErrorMessage));
    }
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
      emit(AuthError(
        message: e.displayMessage,
        code: e.code,
        httpStatusCode: e.httpStatusCode,
        parsedError: e.parsedError,
      ));
    } catch (e) {
      emit(AuthError(message: HeliumException.unexpectedErrorMessage));
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
      emit(AuthError(
        message: e.displayMessage,
        code: e.code,
        httpStatusCode: e.httpStatusCode,
        parsedError: e.parsedError,
      ));
    } catch (e) {
      emit(AuthError(message: HeliumException.unexpectedErrorMessage));
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
      emit(AuthError(
        message: e.displayMessage,
        code: e.code,
        httpStatusCode: e.httpStatusCode,
        parsedError: e.parsedError,
      ));
    } catch (e) {
      emit(AuthError(message: HeliumException.unexpectedErrorMessage));
    }
  }

  Future<void> _onCreateApiToken(
    CreateApiTokenEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final apiToken = await authRepository.createApiToken();
      final user = await authRepository.getUser();

      emit(AuthApiTokenCreated(apiToken: apiToken, user: user));
    } on HeliumException catch (e) {
      emit(AuthError(
        message: e.displayMessage,
        code: e.code,
        httpStatusCode: e.httpStatusCode,
        parsedError: e.parsedError,
      ));
    } catch (e) {
      emit(AuthError(message: HeliumException.unexpectedErrorMessage));
    }
  }

  Future<void> _onRevokeApiToken(
    RevokeApiTokenEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await authRepository.revokeApiToken();
      final user = await authRepository.getUser();

      emit(AuthApiTokenRevoked(user: user));
    } on HeliumException catch (e) {
      emit(AuthError(
        message: e.displayMessage,
        code: e.code,
        httpStatusCode: e.httpStatusCode,
        parsedError: e.parsedError,
      ));
    } catch (e) {
      emit(AuthError(message: HeliumException.unexpectedErrorMessage));
    }
  }

  Future<void> _onRemoveOAuthProvider(
    RemoveOAuthProviderEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await authRepository.removeOAuthProvider(event.provider.name);
      final lastOAuthProviderStore = LastOAuthProviderStore();
      if (await lastOAuthProviderStore.getLastUsedProvider() ==
          event.provider.name) {
        await lastOAuthProviderStore.clearLastUsedProvider();
      }
      final user = await authRepository.getUser();

      emit(AuthOAuthProviderRemoved(provider: event.provider, user: user));
    } on HeliumException catch (e) {
      emit(AuthError(
        message: e.displayMessage,
        code: e.code,
        httpStatusCode: e.httpStatusCode,
        parsedError: e.parsedError,
      ));
    } catch (e) {
      emit(AuthError(message: HeliumException.unexpectedErrorMessage));
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
      await _oauthSignInService.signOut();

      emit(AuthAccountDeleted());
    } on HeliumException catch (e) {
      emit(AuthError(
        message: e.displayMessage,
        code: e.code,
        httpStatusCode: e.httpStatusCode,
        parsedError: e.parsedError,
      ));
    } catch (e) {
      emit(AuthError(message: HeliumException.unexpectedErrorMessage));
    }
  }

  Future<void> _onDeleteExampleSchedule(
    DeleteExampleScheduleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final message = await authRepository.deleteExampleSchedule();
      // Warm the settings cache so the router's auth-redirect read is a hit,
      // not a post-redirect cold fetch that stalls the outgoing screen.
      await dioClient.getSettings(forceRefresh: true);

      emit(AuthScheduleDataRefreshed(message: message));
    } on HeliumException catch (e) {
      emit(AuthError(
        message: e.displayMessage,
        code: e.code,
        httpStatusCode: e.httpStatusCode,
        parsedError: e.parsedError,
      ));
    } catch (e) {
      emit(AuthError(message: HeliumException.unexpectedErrorMessage));
    }
  }

  void _onRefreshScheduleData(
    RefreshScheduleDataEvent event,
    Emitter<AuthState> emit,
  ) {
    emit(AuthScheduleDataRefreshed());
  }

  Future<void> _onDescribeAuthorization(
    DescribeAuthorizationEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final authorization = await authRepository.describeAuthorization(
        event.query,
      );

      emit(AuthAuthorizationDescribed(authorization: authorization));
    } on HeliumException catch (e) {
      emit(_authorizationError(e));
    } catch (e) {
      emit(AuthError(message: HeliumException.unexpectedErrorMessage));
    }
  }

  Future<void> _onDecideAuthorization(
    DecideAuthorizationEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final redirectUri = await authRepository.decideAuthorization(
        event.query,
        allow: event.allow,
        scopes: event.scopes,
      );

      emit(AuthAuthorizationDecided(redirectUri: redirectUri));
    } on HeliumException catch (e) {
      emit(_authorizationError(e));
    } catch (e) {
      emit(AuthError(message: HeliumException.unexpectedErrorMessage));
    }
  }

  AuthState _authorizationError(HeliumException e) {
    final details = e.details;
    if (e is! ValidationException ||
        details is! Map<String, dynamic> ||
        details['error'] is! String) {
      return AuthError(
        message: e.displayMessage,
        code: e.code,
        httpStatusCode: e.httpStatusCode,
        parsedError: e.parsedError,
      );
    }

    _log.warning('OAuth authorization request rejected: ${details['error']}');
    return AuthAuthorizationRejected(
      message: invalidAuthorizationMessage,
      redirectUri: details['redirect_uri'] as String?,
    );
  }
}

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:heliumapp/config/analytics_event.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/core/api_url.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/fcm_service.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/core/sentry_service.dart';
import 'package:heliumapp/core/jwt_utils.dart';
import 'package:heliumapp/data/models/auth/login_request_model.dart';
import 'package:heliumapp/data/models/auth/private_feed_model.dart';
import 'package:heliumapp/data/models/auth/register_request_model.dart';
import 'package:heliumapp/data/models/auth/request/change_email_request_model.dart';
import 'package:heliumapp/data/models/auth/request/change_password_request_model.dart';
import 'package:heliumapp/data/models/auth/request/delete_account_request_model.dart';
import 'package:heliumapp/data/models/auth/request/forgot_password_request_model.dart';
import 'package:heliumapp/data/models/auth/request/refresh_token_request_model.dart';
import 'package:heliumapp/data/models/auth/request/reset_password_request_model.dart';
import 'package:heliumapp/data/models/auth/request/update_settings_request_model.dart';
import 'package:heliumapp/data/models/auth/token_response_model.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';
import 'package:heliumapp/data/models/no_content_response_model.dart';
import 'package:heliumapp/data/sources/base_data_source.dart';
import 'package:logging/logging.dart';

final _log = Logger('data.sources');

abstract class AuthRemoteDataSource extends BaseDataSource {
  Future<NoContentResponseModel> register(RegisterRequestModel request);

  Future<TokenResponseModel> verifyEmail(String email, String code);

  Future<NoContentResponseModel> resendVerificationEmail(String email);

  Future<TokenResponseModel> login(LoginRequestModel request);

  Future<TokenResponseModel> loginWithGoogle(String firebaseIdToken);

  Future<TokenResponseModel> loginWithApple(String firebaseIdToken);

  Future<TokenResponseModel> loginWithMicrosoft(String firebaseIdToken);

  Future<TokenResponseModel> refreshToken(RefreshTokenRequestModel request);

  Future<void> logout();

  Future<PrivateFeedModel> enablePrivateFeeds();

  Future<void> disablePrivateFeeds();

  Future<UserModel> getUser();

  Future<NoContentResponseModel> deleteAccount(
    DeleteAccountRequestModel request,
  );

  Future<UserModel> changePassword(ChangePasswordRequestModel request);

  Future<UserModel> changeEmail(ChangeEmailRequestModel request);

  Future<UserSettingsModel> updateUserSettings(
    UpdateSettingsRequestModel request,
  );

  Future<NoContentResponseModel> forgotPassword(
    ForgotPasswordRequestModel request,
  );

  Future<TokenResponseModel> confirmPasswordReset(
    ResetPasswordRequestModel request,
  );

  Future<void> deleteExampleSchedule();
}

class AuthRemoteDataSourceImpl extends AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<NoContentResponseModel> register(RegisterRequestModel request) async {
    try {
      final response = await dioClient.dio.post(
        ApiUrl.authUserRegisterUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        return NoContentResponseModel(
          message: 'account registered',
          email: response.data['email'],
        );
      } else {
        throw unexpectedStatus(response, 'Registration failed.');
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } on HeliumException {
      rethrow;
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: HeliumException.unexpectedError);
    }
  }

  @override
  Future<TokenResponseModel> verifyEmail(String email, String code) async {
    try {
      final response = await dioClient.dio.get(
        ApiUrl.authUserVerifyUrl,
        queryParameters: {
          'email': email,
          'code': code,
        },
      );

      if (response.statusCode == 202) {
        _log.info('Email verification successful');

        await dioClient.saveTokens(
          response.data['access'],
          response.data['refresh'],
        );

        await dioClient.fetchSettings();

        final tokenResponse = TokenResponseModel.fromJson(response.data);

        try {
          await FcmService().registerToken(force: true);
          if (FcmService().fcmToken != null) {
            _log.info('FCM token registered after verification');
          } else {
            _log.warning('FCM token not yet available after verification');
          }
        } catch (e) {
          _log.warning('Failed to register FCM token after verification', e);
        }

        final verifyUserId = JwtUtils.getUserId(response.data['access'] as String);
        unawaited(AnalyticsService().setUserId(verifyUserId?.toString()));
        unawaited(AnalyticsService().logSignUp());
        SentryService().setUser(verifyUserId?.toString());

        return tokenResponse;
      } else {
        throw unexpectedStatus(response, 'Email verification failed.');
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } on HeliumException {
      rethrow;
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: HeliumException.unexpectedError);
    }
  }

  @override
  Future<NoContentResponseModel> resendVerificationEmail(String email) async {
    try {
      final response = await dioClient.dio.get(
        ApiUrl.authUserVerifyResendUrl,
        queryParameters: {
          'email': email,
        },
      );

      if (response.statusCode == 202) {
        _log.info('Verification email resend succeeded');
        return NoContentResponseModel(message: 'Verification email sent');
      } else {
        throw unexpectedStatus(response, 'Failed to resend verification email.');
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } on HeliumException {
      rethrow;
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: HeliumException.unexpectedError);
    }
  }

  @override
  Future<TokenResponseModel> login(LoginRequestModel request) async {
    try {
      final response = await dioClient.dio.post(
        ApiUrl.authTokenUrl,
        data: {
          'email': request.email,
          'password': request.password,
        },
      );

      if (response.statusCode == 200) {
        _log.info('Login successful');

        await dioClient.saveTokens(
          response.data['access'],
          response.data['refresh'],
        );

        await dioClient.fetchSettings();

        final loginResponse = TokenResponseModel.fromJson(response.data);

        try {
          await FcmService().registerToken(force: true);
          if (FcmService().fcmToken != null) {
            _log.info('FCM token registered after login');
          } else {
            _log.warning('FCM token not yet available after login');
          }
        } catch (e) {
          _log.warning('Failed to register FCM token after login', e);
        }

        final loginUserId = JwtUtils.getUserId(response.data['access'] as String);
        unawaited(AnalyticsService().setUserId(loginUserId?.toString()));
        unawaited(AnalyticsService().logLogin(loginMethod: 'email'));
        SentryService().setUser(loginUserId?.toString());

        return loginResponse;
      } else {
        throw unexpectedStatus(response, 'Login failed.');
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } on HeliumException {
      rethrow;
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: HeliumException.unexpectedError);
    }
  }

  @override
  Future<TokenResponseModel> loginWithGoogle(String firebaseIdToken) async {
    return _loginWithOAuth(firebaseIdToken, 'google');
  }

  @override
  Future<TokenResponseModel> loginWithApple(String firebaseIdToken) async {
    return _loginWithOAuth(firebaseIdToken, 'apple');
  }

  @override
  Future<TokenResponseModel> loginWithMicrosoft(String firebaseIdToken) async {
    return _loginWithOAuth(firebaseIdToken, 'microsoft');
  }

  Future<TokenResponseModel> _loginWithOAuth(
    String firebaseIdToken,
    String provider,
  ) async {
    try {
      final response = await dioClient.dio.post(
        ApiUrl.authTokenOAuthUrl,
        data: {'id_token': firebaseIdToken, 'provider': provider},
      );

      if (response.statusCode == 200) {
        _log.info('OAuth login successful for provider: $provider');

        await dioClient.saveTokens(
          response.data['access'],
          response.data['refresh'],
        );

        await dioClient.fetchSettings();

        final loginResponse = TokenResponseModel.fromJson(response.data);

        try {
          await FcmService().registerToken(force: true);
          if (FcmService().fcmToken != null) {
            _log.info('FCM token registered after $provider login');
          } else {
            _log.warning('FCM token not yet available after $provider login');
          }
        } catch (e) {
          _log.warning('Failed to register FCM token after $provider login', e);
        }

        final oauthUserId = JwtUtils.getUserId(response.data['access'] as String);
        unawaited(AnalyticsService().setUserId(oauthUserId?.toString()));
        unawaited(AnalyticsService().logLogin(loginMethod: provider));
        SentryService().setUser(oauthUserId?.toString());

        return loginResponse;
      } else {
        throw unexpectedStatus(response, 'OAuth login failed.');
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } on HeliumException {
      rethrow;
    } catch (e, s) {
      _log.severe('An unexpected error occurred during $provider login', e, s);
      throw HeliumException(message: 'Sign in failed.');
    }
  }

  @override
  Future<TokenResponseModel> refreshToken(
    RefreshTokenRequestModel request,
  ) async {
    try {
      final response = await dioClient.dio.post(
        ApiUrl.authTokenRefreshUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final refreshResponse = TokenResponseModel.fromJson(response.data);

        _log.info('Token refreshed successfully');

        if (refreshResponse.access.isNotEmpty) {
          await dioClient.saveTokens(
            refreshResponse.access,
            refreshResponse.refresh,
          );
        } else {
          _log.severe('New access token is empty!');
        }

        return refreshResponse;
      } else {
        throw unexpectedStatus(response, 'Token refresh failed.');
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } on HeliumException {
      rethrow;
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: HeliumException.unexpectedError);
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Get the refresh token before clearing
      final refreshToken = await dioClient.getRefreshToken();

      try {
        final fcmService = FcmService();
        await fcmService.unregisterToken();
      } catch (e) {
        // If FCM cleanup fails, we still want to logout
        _log.warning('Failed to unregister FCM token', e);
      }

      await dioClient.clearStorage();
      SentryService().clearUser();

      if (refreshToken?.isNotEmpty ?? false) {
        try {
          await _blacklistRefreshToken(refreshToken!);
        } catch (e) {
          // If blacklisting fails, we still want to logout locally
          _log.warning('Failed to blacklist token on server', e);
        }
      }
    } on HeliumException {
      rethrow;
    } catch (e, s) {
      _log.severe('An unexpected error occurred during sign-out', e, s);
      // Even if something fails, always clear storage
      await dioClient.clearStorage();
      throw HeliumException(message: 'Failed to sign out.');
    }
  }

  @override
  Future<UserModel> getUser() async {
    try {
      final response = await dioClient.dio.get(ApiUrl.authUserUrl);

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw unexpectedStatus(response, 'Failed to fetch profile.');
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } on HeliumException {
      rethrow;
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: HeliumException.unexpectedError);
    }
  }

  @override
  Future<PrivateFeedModel> enablePrivateFeeds() async {
    try {
      final response = await dioClient.dio.put(ApiUrl.feedPrivateEnableUrl);

      if (response.statusCode == 200) {
        unawaited(AnalyticsService().logEvent(name: AnalyticsEvent.feedsEnable, parameters: {'category': AnalyticsCategory.featureInteraction.value}));
        return PrivateFeedModel.fromJson(response.data);
      } else {
        throw unexpectedStatus(response, 'Failed to enable feeds.');
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } on HeliumException {
      rethrow;
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: HeliumException.unexpectedError);
    }
  }

  @override
  Future<void> disablePrivateFeeds() async {
    try {
      final response = await dioClient.dio.put(ApiUrl.feedPrivateDisableUrl);

      if (response.statusCode != 204) {
        throw unexpectedStatus(response, 'Failed to enable feeds.');
      }
      unawaited(AnalyticsService().logEvent(name: AnalyticsEvent.feedsDisable, parameters: {'category': AnalyticsCategory.featureInteraction.value}));
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } on HeliumException {
      rethrow;
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: HeliumException.unexpectedError);
    }
  }

  @override
  Future<NoContentResponseModel> deleteAccount(
    DeleteAccountRequestModel request,
  ) async {
    try {
      final response = await dioClient.dio.delete(
        ApiUrl.authUserDeleteUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 204) {
        await dioClient.clearStorage();
        SentryService().clearUser();

        return NoContentResponseModel(message: 'Account deleted');
      } else {
        throw unexpectedStatus(response, 'Failed to delete account.');
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } on HeliumException {
      rethrow;
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: HeliumException.unexpectedError);
    }
  }

  @override
  Future<UserModel> changePassword(ChangePasswordRequestModel request) async {
    try {
      final response = await dioClient.dio.put(
        ApiUrl.authUserUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        // Changing the password invalidates the current tokens server-side; the response carries a
        // fresh pair to keep this session signed in.
        if (response.data['access'] != null &&
            response.data['refresh'] != null) {
          await dioClient.saveTokens(
            response.data['access'],
            response.data['refresh'],
          );
        }

        return UserModel.fromJson(response.data);
      } else {
        throw unexpectedStatus(response, 'Failed to change password.');
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } on HeliumException {
      rethrow;
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: HeliumException.unexpectedError);
    }
  }

  @override
  Future<UserModel> changeEmail(ChangeEmailRequestModel request) async {
    try {
      final response = await dioClient.dio.put(
        ApiUrl.authUserUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw unexpectedStatus(response, 'Failed to change email.');
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } on HeliumException {
      rethrow;
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: HeliumException.unexpectedError);
    }
  }

  @override
  Future<UserSettingsModel> updateUserSettings(
    UpdateSettingsRequestModel request,
  ) async {
    try {
      final response = await dioClient.dio.put(
        ApiUrl.authUserSettingsUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final responseModel = UserSettingsModel.fromJson(response.data);

        await dioClient.saveSettings(responseModel);

        return responseModel;
      } else {
        throw unexpectedStatus(response, 'Failed to update user settings.');
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } on HeliumException {
      rethrow;
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: HeliumException.unexpectedError);
    }
  }

  @override
  Future<NoContentResponseModel> forgotPassword(
    ForgotPasswordRequestModel request,
  ) async {
    try {
      final response = await dioClient.dio.put(
        ApiUrl.authUserForgotUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 202) {
        return NoContentResponseModel(message: 'Password reset email sent');
      } else {
        throw unexpectedStatus(response, 'Failed to send reset email.');
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } on HeliumException {
      rethrow;
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: HeliumException.unexpectedError);
    }
  }

  @override
  Future<TokenResponseModel> confirmPasswordReset(
    ResetPasswordRequestModel request,
  ) async {
    try {
      final response = await dioClient.dio.put(
        ApiUrl.authUserForgotConfirmUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final tokenResponse = TokenResponseModel.fromJson(
          response.data as Map<String, dynamic>,
        );

        await dioClient.saveTokens(tokenResponse.access, tokenResponse.refresh);
        await dioClient.fetchSettings();

        try {
          await FcmService().registerToken(force: true);
          if (FcmService().fcmToken != null) {
            _log.info('FCM token registered after password reset');
          } else {
            _log.warning('FCM token not yet available after password reset');
          }
        } catch (e) {
          _log.warning('Failed to register FCM token after password reset', e);
        }

        final resetUserId = JwtUtils.getUserId(tokenResponse.access);
        unawaited(AnalyticsService().setUserId(resetUserId?.toString()));
        SentryService().setUser(resetUserId?.toString());

        return tokenResponse;
      } else {
        throw unexpectedStatus(response, 'Failed to reset password.');
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } on HeliumException {
      rethrow;
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: HeliumException.unexpectedError);
    }
  }

  @override
  Future<void> deleteExampleSchedule() async {
    try {
      final response = await dioClient.dio.delete(
        ApiUrl.authUserDeleteExampleScheduleUrl,
      );

      if (response.statusCode != 204) {
        throw unexpectedStatus(response, 'Failed to delete example schedule.');
      }

      // Clear all cached data since the example data is now deleted
      await dioClient.cacheService.clearAll();
      unawaited(AnalyticsService().logEvent(name: AnalyticsEvent.exampleScheduleClear, parameters: {'category': AnalyticsCategory.onboarding.value}));
      unawaited(AnalyticsService().setUserProperty(name: 'onboarding_complete', value: 'true'));
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } on HeliumException {
      rethrow;
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: HeliumException.unexpectedError);
    }
  }

  Future<void> _blacklistRefreshToken(String refreshToken) async {
    try {
      final response = await dioClient.dio.post(
        ApiUrl.authTokenBlacklistUrl,
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200) {
        _log.info('Token blacklisted successfully');
      } else {
        throw unexpectedStatus(response, 'Failed to blacklist token.');
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } on HeliumException {
      rethrow;
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: HeliumException.unexpectedError);
    }
  }
}

// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:dio/dio.dart';
import 'package:heliumapp/core/api_url.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/fcm_service.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/auth/login_request_model.dart';
import 'package:heliumapp/data/models/auth/private_feed_model.dart';
import 'package:heliumapp/data/models/auth/register_request_model.dart';
import 'package:heliumapp/data/models/auth/request/change_password_request_model.dart';
import 'package:heliumapp/data/models/auth/request/delete_account_request_model.dart';
import 'package:heliumapp/data/models/auth/request/forgot_password_request_model.dart';
import 'package:heliumapp/data/models/auth/request/refresh_token_request_model.dart';
import 'package:heliumapp/data/models/auth/request/update_settings_request_model.dart';
import 'package:heliumapp/data/models/auth/token_response_model.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
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

  Future<TokenResponseModel> refreshToken(RefreshTokenRequestModel request);

  Future<void> logout();

  Future<PrivateFeedModel> enablePrivateFeeds();

  Future<void> disablePrivateFeeds();

  Future<UserModel> getUser();

  Future<NoContentResponseModel> deleteAccount(
    DeleteAccountRequestModel request,
  );

  Future<UserModel> changePassword(ChangePasswordRequestModel request);

  Future<UserSettingsModel> updateUserSettings(
    UpdateSettingsRequestModel request,
  );

  Future<NoContentResponseModel> forgotPassword(
    ForgotPasswordRequestModel request,
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
        throw ServerException(
          message: 'Registration failed',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'An unexpected error occurred: $e');
    }
  }

  @override
  Future<TokenResponseModel> verifyEmail(String email, String code) async {
    try {
      final response = await dioClient.dio.get(
        ApiUrl.authUserVerifyUrl,
        queryParameters: {
          'username': email,
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

        return tokenResponse;
      } else {
        throw ServerException(
          message: 'Email verification failed',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'An unexpected error occurred: $e');
    }
  }

  @override
  Future<NoContentResponseModel> resendVerificationEmail(String email) async {
    try {
      final response = await dioClient.dio.get(
        ApiUrl.authUserVerifyResendUrl,
        queryParameters: {
          'username': email,
        },
      );

      if (response.statusCode == 202) {
        _log.info('Verification email resend succeeded');
        return NoContentResponseModel(message: 'Verification email sent');
      } else {
        throw ServerException(
          message: 'Failed to resend verification email',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'An unexpected error occurred: $e');
    }
  }

  @override
  Future<TokenResponseModel> login(LoginRequestModel request) async {
    try {
      final response = await dioClient.dio.post(
        ApiUrl.authTokenUrl,
        data: {
          'username': request.email,
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

        return loginResponse;
      } else {
        throw ServerException(
          message: 'Login failed',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'An unexpected error occurred: $e');
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

        return loginResponse;
      } else {
        throw ServerException(
          message: 'OAuth login failed',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred during $provider login', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'OAuth login failed: $e');
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
        throw ServerException(
          message: 'Token refresh failed',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Get the refresh token before clearing
      final refreshToken = await dioClient.getRefreshToken();

      // Unregister push notification token for this device
      try {
        final fcmService = FcmService();
        await fcmService.unregisterToken();
      } catch (e) {
        // If FCM cleanup fails, we still want to logout
        _log.warning('Failed to unregister FCM token', e);
      }

      await dioClient.clearStorage();

      // If we have a refresh token, blacklist it on the server
      if (refreshToken?.isNotEmpty ?? false) {
        try {
          await _blacklistRefreshToken(refreshToken!);
        } catch (e) {
          // If blacklisting fails, we still want to logout locally
          _log.warning('Failed to blacklist token on server', e);
        }
      }
    } catch (e) {
      // Even if something fails, always clear storage
      await dioClient.clearStorage();
      throw HeliumException(message: 'Logout error: $e');
    }
  }

  @override
  Future<UserModel> getUser() async {
    try {
      final response = await dioClient.dio.get(ApiUrl.authUserUrl);

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to fetch profile',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'An unexpected error occurred: $e');
    }
  }

  @override
  Future<PrivateFeedModel> enablePrivateFeeds() async {
    try {
      final response = await dioClient.dio.put(ApiUrl.feedPrivateEnableUrl);

      if (response.statusCode == 200) {
        return PrivateFeedModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to enable feeds',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> disablePrivateFeeds() async {
    try {
      final response = await dioClient.dio.put(ApiUrl.feedPrivateDisableUrl);

      if (response.statusCode != 204) {
        throw ServerException(
          message: 'Failed to enable feeds',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'An unexpected error occurred: $e');
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
        // After successful deletion, clear storage
        await dioClient.clearStorage();

        return NoContentResponseModel(message: 'Account deleted');
      } else {
        throw ServerException(
          message: 'Failed to delete account',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'An unexpected error occurred: $e');
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
        return UserModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to change password',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'An unexpected error occurred: $e');
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
        throw ServerException(
          message: 'Failed to update user settings',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'An unexpected error occurred: $e');
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
        throw ServerException(
          message: 'Failed to send reset email',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> deleteExampleSchedule() async {
    try {
      final response = await dioClient.dio.delete(
        ApiUrl.authUserDeleteExampleScheduleUrl,
      );

      if (response.statusCode != 204) {
        throw ServerException(
          message: 'Failed to delete example schedule',
          code: response.statusCode.toString(),
        );
      }

      // Clear all cached data since the example data is now deleted
      await dioClient.cacheService.clearAll();
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'An unexpected error occurred: $e');
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
        throw ServerException(
          message: 'Failed to blacklist token',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      if (e is HeliumException) {
        rethrow;
      }
      throw HeliumException(message: 'An unexpected error occurred: $e');
    }
  }
}

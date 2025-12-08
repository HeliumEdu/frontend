// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:dio/dio.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/fcm_service.dart';
import 'package:heliumapp/core/api_url.dart';
import 'package:heliumapp/data/models/auth/change_password_request_model.dart';
import 'package:heliumapp/data/models/auth/change_password_response_model.dart';
import 'package:heliumapp/data/models/auth/delete_account_request_model.dart';
import 'package:heliumapp/data/models/auth/delete_account_response_model.dart';
import 'package:heliumapp/data/models/auth/error_response_model.dart';
import 'package:heliumapp/data/models/auth/forgot_password_request_model.dart';
import 'package:heliumapp/data/models/auth/forgot_password_response_model.dart';
import 'package:heliumapp/data/models/auth/login_request_model.dart';
import 'package:heliumapp/data/models/auth/login_response_model.dart';
import 'package:heliumapp/data/models/auth/refresh_token_request_model.dart';
import 'package:heliumapp/data/models/auth/refresh_token_response_model.dart';
import 'package:heliumapp/data/models/auth/register_request_model.dart';
import 'package:heliumapp/data/models/auth/register_response_model.dart';
import 'package:heliumapp/data/models/auth/update_settings_request_model.dart';
import 'package:heliumapp/data/models/auth/update_settings_response_model.dart';
import 'package:heliumapp/data/models/auth/user_profile_model.dart';
import 'package:logging/logging.dart';

final log = Logger('HeliumLogger');

abstract class AuthRemoteDataSource {
  Future<RegisterResponseModel> register(RegisterRequestModel request);

  Future<LoginResponseModel> login(LoginRequestModel request);

  Future<RefreshTokenResponseModel> refreshToken(
    RefreshTokenRequestModel request,
  );

  Future<void> logout();

  Future<void> blacklistRefreshToken(String refreshToken);

  Future<UserProfileModel> getProfile();

  Future<DeleteAccountResponseModel> deleteAccount(
    DeleteAccountRequestModel request,
  );

  Future<ChangePasswordResponseModel> changePassword(
    ChangePasswordRequestModel request,
  );

  Future<UpdateSettingsResponseModel> updateUserSettings(
    UpdateSettingsRequestModel request,
  );

  Future<ForgotPasswordResponseModel> forgotPassword(
    ForgotPasswordRequestModel request,
  );
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<RegisterResponseModel> register(RegisterRequestModel request) async {
    try {
      final response = await dioClient.dio.post(
        ApiUrl.authUserRegisterUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return RegisterResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Registration failed',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<LoginResponseModel> login(LoginRequestModel request) async {
    try {
      final response = await dioClient.dio.post(
        ApiUrl.authTokenUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        log.info('📦 Login Response: ${response.data}');

        await dioClient.saveTokens(
          response.data['access'],
          response.data['refresh'],
        );

        final userProfile = await getProfile();
        await dioClient.saveSettings(userProfile.settings!);

        final loginResponse = LoginResponseModel.fromJson(response.data);

        try {
          final fcmService = FcmService();
          await fcmService.registerToken(force: true);
          log.info('✅ FCM token registered after login');
        } catch (e) {
          log.info('❌ Failed to register FCM token after login: $e');
        }

        return loginResponse;
      } else {
        throw ServerException(
          message: 'Login failed',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<RefreshTokenResponseModel> refreshToken(
    RefreshTokenRequestModel request,
  ) async {
    try {
      final response = await dioClient.dio.post(
        ApiUrl.authTokenRefreshUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final refreshResponse = RefreshTokenResponseModel.fromJson(
          response.data,
        );

        log.info('🔄 Token refreshed successfully');
        log.info(
          '🔑 New Access Token: ${refreshResponse.access.substring(0, 10)}...',
        );

        if (refreshResponse.access.isNotEmpty) {
          await dioClient.saveTokens(
            refreshResponse.access,
            refreshResponse.refresh,
          );
        } else {
          log.info('❌ New access token is empty!');
        }

        return refreshResponse;
      } else {
        throw ServerException(
          message: 'Token refresh failed',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Get the refresh token before clearing
      final refreshToken = await dioClient.getRefreshToken();

      await dioClient.clearStorage();

      // If we have a refresh token, blacklist it on the server
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          await blacklistRefreshToken(refreshToken);
        } catch (e) {
          // If blacklisting fails, we still want to logout locally
          log.info('⚠️ Failed to blacklist token on server: $e');
        }
      }
    } catch (e) {
      // Even if something fails, always clear storage
      await dioClient.clearStorage();
      throw HeliumException(message: 'Logout error: $e');
    }
  }

  @override
  Future<void> blacklistRefreshToken(String refreshToken) async {
    try {
      final response = await dioClient.dio.post(
        ApiUrl.authTokenBlacklistUrl,
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        log.info('✅ Token blacklisted successfully');
      } else {
        throw ServerException(
          message: 'Failed to blacklist token',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<UserProfileModel> getProfile() async {
    try {
      final response = await dioClient.dio.get(ApiUrl.authUserUrl);

      if (response.statusCode == 200) {
        return UserProfileModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to fetch profile',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<DeleteAccountResponseModel> deleteAccount(
    DeleteAccountRequestModel request,
  ) async {
    try {
      final response = await dioClient.dio.delete(
        ApiUrl.authUserDeleteUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // After successful deletion, clear storage
        await dioClient.clearStorage();

        // Handle both response with body and no content (204)
        if (response.statusCode == 204 || response.data == null) {
          return DeleteAccountResponseModel(
            message: 'Account deleted successfully',
          );
        }

        return DeleteAccountResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to delete account',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<ChangePasswordResponseModel> changePassword(
    ChangePasswordRequestModel request,
  ) async {
    try {
      final response = await dioClient.dio.put(
        ApiUrl.authUserUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return ChangePasswordResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to change password',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<UpdateSettingsResponseModel> updateUserSettings(
    UpdateSettingsRequestModel request,
  ) async {
    try {
      final response = await dioClient.dio.put(
        ApiUrl.authUserSettingsUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final responseModel = UpdateSettingsResponseModel.fromJson(
          response.data,
        );

        await dioClient.saveSettings(responseModel.settings);

        return responseModel;
      } else {
        throw ServerException(
          message: 'Failed to update user settings',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<ForgotPasswordResponseModel> forgotPassword(
    ForgotPasswordRequestModel request,
  ) async {
    try {
      final response = await dioClient.dio.put(
        ApiUrl.authUserForgotUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        if (response.data is Map<String, dynamic>) {
          return ForgotPasswordResponseModel.fromJson(
            response.data as Map<String, dynamic>,
          );
        }
        return ForgotPasswordResponseModel(
          message: 'Password reset link sent. Please check your email.',
        );
      } else {
        throw ServerException(
          message: 'Failed to send reset email',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HeliumException(message: 'Unexpected error occurred: $e');
    }
  }

  HeliumException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          message: 'Connection timeout. Please check your internet connection.',
          code: 'TIMEOUT',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;

        if (responseData is Map<String, dynamic>) {
          final errorModel = ErrorResponseModel.fromJson(
            responseData,
            statusCode: statusCode,
          );

          if (statusCode == 400) {
            return ValidationException(
              message: errorModel.getUserMessage(),
              details: errorModel.fieldErrors,
            );
          } else if (statusCode == 401) {
            return UnauthorizedException(
              message: errorModel.message,
              code: '401',
            );
          } else if (statusCode == 500) {
            return ServerException(
              message: 'Server error. Please try again later.',
              code: '500',
            );
          } else {
            return ServerException(
              message: errorModel.getUserMessage(),
              code: statusCode.toString(),
            );
          }
        }

        return ServerException(
          message:
              'Server error: ${error.response?.statusMessage ?? "Unknown error"}',
          code: statusCode.toString(),
        );

      case DioExceptionType.cancel:
        return NetworkException(
          message: 'Request was cancelled',
          code: 'CANCELLED',
        );

      case DioExceptionType.unknown:
        if (error.message?.contains('SocketException') ?? false) {
          return NetworkException(
            message: 'No internet connection',
            code: 'NO_INTERNET',
          );
        }
        return NetworkException(
          message: 'Network error occurred. Please check your connection.',
          code: 'UNKNOWN',
        );

      default:
        return NetworkException(
          message: 'Network error: ${error.message}',
          code: 'NETWORK_ERROR',
        );
    }
  }
}

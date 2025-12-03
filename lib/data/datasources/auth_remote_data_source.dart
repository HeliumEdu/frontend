// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:dio/dio.dart';
import 'package:helium_mobile/core/app_exception.dart';
import 'package:helium_mobile/core/dio_client.dart';
import 'package:helium_mobile/core/fcm_service.dart';
import 'package:helium_mobile/core/network_urls.dart';
import 'package:helium_mobile/data/models/auth/change_password_request_model.dart';
import 'package:helium_mobile/data/models/auth/change_password_response_model.dart';
import 'package:helium_mobile/data/models/auth/delete_account_request_model.dart';
import 'package:helium_mobile/data/models/auth/delete_account_response_model.dart';
import 'package:helium_mobile/data/models/auth/error_response_model.dart';
import 'package:helium_mobile/data/models/auth/forgot_password_request_model.dart';
import 'package:helium_mobile/data/models/auth/forgot_password_response_model.dart';
import 'package:helium_mobile/data/models/auth/login_request_model.dart';
import 'package:helium_mobile/data/models/auth/login_response_model.dart';
import 'package:helium_mobile/data/models/auth/refresh_token_request_model.dart';
import 'package:helium_mobile/data/models/auth/refresh_token_response_model.dart';
import 'package:helium_mobile/data/models/auth/register_request_model.dart';
import 'package:helium_mobile/data/models/auth/register_response_model.dart';
import 'package:helium_mobile/data/models/auth/update_settings_request_model.dart';
import 'package:helium_mobile/data/models/auth/update_settings_response_model.dart';
import 'package:helium_mobile/data/models/auth/user_profile_model.dart';

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
        NetworkUrl.signUpUrl,
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
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<LoginResponseModel> login(LoginRequestModel request) async {
    try {
      final response = await dioClient.dio.post(
        NetworkUrl.signInUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        print('📦 Login Response: ${response.data}');

        await dioClient.saveTokens(
          response.data['access'],
          response.data['refresh'],
        );

        final userProfile = await getProfile();
        await dioClient.saveSettings(userProfile.settings!);

        final loginResponse = LoginResponseModel.fromJson(response.data);

        // Register FCM token with HeliumEdu API after successful login
        try {
          final fcmService = FCMService();
          await fcmService.registerTokenWithHeliumEdu(force: true);
          print('✅ FCM token registered after login');
        } catch (e) {
          print('❌ Failed to register FCM token after login: $e');
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
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<RefreshTokenResponseModel> refreshToken(
    RefreshTokenRequestModel request,
  ) async {
    try {
      final response = await dioClient.dio.post(
        NetworkUrl.refreshTokenUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final refreshResponse = RefreshTokenResponseModel.fromJson(
          response.data,
        );

        print('🔄 Token refreshed successfully');
        print(
          '🔑 New Access Token: ${refreshResponse.access.substring(0, 10)}...',
        );

        if (refreshResponse.access.isNotEmpty) {
          await dioClient.saveTokens(
            refreshResponse.access,
            refreshResponse.refresh,
          );

          // Extract and save user ID from JWT token
          // final userId = JWTUtils.getUserId(refreshResponse.access);
          // if (userId != null) {
          //   await dioClient.saveUserData(userId);
          //   print('👤 User ID extracted and saved: $userId');
          //
          //   // Register FCM token with HeliumEdu API after token refresh
          //   try {
          //     final fcmService = FCMService();
          //     await fcmService.registerTokenWithHeliumEdu(force: true);
          //     print('✅ FCM token registered after token refresh');
          //   } catch (e) {
          //     print('❌ Failed to register FCM token after token refresh: $e');
          //   }
          // } else {
          //   print('⚠️ Could not extract user ID from JWT token');
          // }
        } else {
          print('❌ New access token is empty!');
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
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Get the refresh token before clearing
      final refreshToken = await dioClient.getRefreshToken();

      // Clear tokens locally first
      await dioClient.clearTokens();

      // If we have a refresh token, blacklist it on the server
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          await blacklistRefreshToken(refreshToken);
        } catch (e) {
          // If blacklisting fails, we still want to logout locally
          print('⚠️ Failed to blacklist token on server: $e');
        }
      }
    } catch (e) {
      // Even if something fails, always clear the token
      await dioClient.clearTokens();
      throw AppException(message: 'Logout error: $e');
    }
  }

  @override
  Future<void> blacklistRefreshToken(String refreshToken) async {
    try {
      final response = await dioClient.dio.post(
        NetworkUrl.blacklistTokenUrl,
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Token blacklisted successfully');
      } else {
        throw ServerException(
          message: 'Failed to blacklist token',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<UserProfileModel> getProfile() async {
    try {
      final response = await dioClient.dio.get(NetworkUrl.getUserUrl);

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
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<DeleteAccountResponseModel> deleteAccount(
    DeleteAccountRequestModel request,
  ) async {
    try {
      final response = await dioClient.dio.delete(
        NetworkUrl.deleteAccountUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // After successful deletion, clear the token
        await dioClient.clearTokens();

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
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<ChangePasswordResponseModel> changePassword(
    ChangePasswordRequestModel request,
  ) async {
    try {
      final response = await dioClient.dio.put(
        NetworkUrl.changePasswordUrl,
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
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<UpdateSettingsResponseModel> updateUserSettings(
    UpdateSettingsRequestModel request,
  ) async {
    try {
      final response = await dioClient.dio.put(
        NetworkUrl.userSettingsUrl,
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
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<ForgotPasswordResponseModel> forgotPassword(
    ForgotPasswordRequestModel request,
  ) async {
    try {
      final response = await dioClient.dio.put(
        NetworkUrl.forgotPasswordUrl,
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
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  AppException _handleDioError(DioException error) {
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

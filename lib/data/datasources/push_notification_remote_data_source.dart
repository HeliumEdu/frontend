// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:dio/dio.dart';
import 'package:helium_mobile/core/app_exception.dart';
import 'package:helium_mobile/core/dio_client.dart';
import 'package:helium_mobile/core/network_urls.dart';
import 'package:helium_mobile/data/models/notification/push_token_request_model.dart';
import 'package:helium_mobile/data/models/notification/push_token_response_model.dart';
import 'package:logging/logging.dart';

final log = Logger('HeliumLogger');

abstract class PushNotificationRemoteDataSource {
  Future<PushTokenResponseModel> registerPushToken(
    PushTokenRequestModel request,
  );

  Future<void> deletePushToken(int userId);

  Future<void> deletePushTokenById(int tokenId);

  Future<List<PushTokenResponseModel>> retrievePushTokens(int userId);
}

class PushNotificationRemoteDataSourceImpl
    implements PushNotificationRemoteDataSource {
  final DioClient dioClient;

  PushNotificationRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<PushTokenResponseModel> registerPushToken(
    PushTokenRequestModel request,
  ) async {
    try {
      log.info(
        '📱 Registering push token for user:........... ${request.user}',
      );
      log.info('🔑 Device ID: ${request.deviceId}');
      log.info('🎯 Token: ${request.token.substring(0, 20)}...');

      final response = await dioClient.dio.post(
        NetworkUrl.pushTokenUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        log.info(
          '________________________________✅ Push token registered successfully  ____________________________?',
        );
        return PushTokenResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          message:
              'Failed to register push token  ----------------------------------------->',
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
  Future<void> deletePushToken(int userId) async {
    try {
      log.info('🗑️ Deleting push token for user: $userId');

      final response = await dioClient.dio.delete(
        '${NetworkUrl.pushTokenUrl}$userId/',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        log.info('✅ Push token deleted successfully');
      } else {
        // Get real error message from API response
        String errorMessage = 'Failed to delete push token';
        if (response.data != null) {
          if (response.data is Map<String, dynamic>) {
            final errorData = response.data as Map<String, dynamic>;
            errorMessage =
                errorData['detail'] ??
                errorData['message'] ??
                errorData['error'] ??
                errorMessage;
          } else if (response.data is String) {
            errorMessage = response.data as String;
          }
        }
        log.info('❌ API Error: $errorMessage');
        throw ServerException(
          message: errorMessage,
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      // Get real error message from DioException
      String errorMessage = 'Network error occurred';
      if (e.response?.data != null) {
        if (e.response!.data is Map<String, dynamic>) {
          final errorData = e.response!.data as Map<String, dynamic>;
          errorMessage =
              errorData['detail'] ??
              errorData['message'] ??
              errorData['error'] ??
              e.message ??
              errorMessage;
        } else if (e.response!.data is String) {
          errorMessage = e.response!.data as String;
        }
      } else {
        errorMessage = e.message ?? errorMessage;
      }
      log.info('❌ DioException Error: $errorMessage');
      throw AppException(message: errorMessage);
    } catch (e) {
      log.info('❌ Unexpected Error: $e');
      throw AppException(message: 'Unexpected error occurred: $e');
    }
  }

  @override
  Future<void> deletePushTokenById(int tokenId) async {
    try {
      log.info('🗑️ Deleting push token by ID: $tokenId');
      final response = await dioClient.dio.delete(
        '${NetworkUrl.pushTokenUrl}$tokenId/',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        log.info('✅ Push token $tokenId deleted successfully');
      } else {
        final message = response.data is Map<String, dynamic>
            ? (response.data['detail'] ?? 'Failed to delete push token')
            : 'Failed to delete push token';
        throw ServerException(
          message: message,
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
          if (statusCode == 400) {
            return ValidationException(
              message: responseData['detail'] ?? 'Invalid request data',
              details: responseData,
            );
          } else if (statusCode == 401) {
            return UnauthorizedException(
              message: 'Authentication failed. Please login again.',
              code: '401',
            );
          } else if (statusCode == 500) {
            return ServerException(
              message: 'Server error. Please try again later.',
              code: '500',
            );
          } else {
            return ServerException(
              message: responseData['detail'] ?? 'Server error occurred',
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

  @override
  Future<List<PushTokenResponseModel>> retrievePushTokens(int userId) async {
    try {
      log.info('📥 Retrieving push tokens for user: $userId');
      log.info('📚 Using official Helium API documentation format');

      // According to official docs: GET /auth/user/pushtoken/ (no query parameters)
      // The API will return tokens for the authenticated user automatically
      final response = await dioClient.dio.get(
        NetworkUrl.pushTokenUrl, // GET /auth/user/pushtoken/
      );

      if (response.statusCode == 200) {
        log.info('✅ Push tokens retrieved successfully');
        log.info('📱 API Response: ${response.data}');

        // Handle both single object and array responses
        if (response.data is List) {
          final tokens = (response.data as List)
              .map((json) => PushTokenResponseModel.fromJson(json))
              .toList();
          log.info('📱 Found ${tokens.length} push tokens');
          for (var token in tokens) {
            log.info(
              '📱 Token ID: ${token.id}, Device: ${token.deviceId}, User: ${token.user}, Type: ${token.type ?? 'Unknown'}, Registration ID: ${token.registrationId ?? 'N/A'}',
            );
          }
          return tokens;
        } else if (response.data != null) {
          // Single object response
          final token = PushTokenResponseModel.fromJson(response.data);
          log.info(
            '📱 Found 1 push token - ID: ${token.id}, Device: ${token.deviceId}, Type: ${token.type ?? 'Unknown'}, Registration ID: ${token.registrationId ?? 'N/A'}',
          );
          return [token];
        } else {
          log.info('📱 No push tokens found');
          return [];
        }
      } else {
        throw ServerException(
          message: 'Failed to retrieve push tokens',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        log.info('📱 No push tokens found for user $userId (404)');
        return []; // Return empty list instead of throwing error
      }
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(message: 'An unexpected error occurred: $e');
    }
  }
}

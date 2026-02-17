// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:dio/dio.dart';
import 'package:heliumapp/core/api_url.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/notification/push_token_model.dart';
import 'package:heliumapp/data/models/notification/request/push_token_request_model.dart';
import 'package:heliumapp/data/sources/base_data_source.dart';
import 'package:logging/logging.dart';

final _log = Logger('data.sources');

abstract class PushNotificationRemoteDataSource extends BaseDataSource {
  Future<PushTokenModel> registerPushToken(PushTokenRequestModel request);

  Future<void> deletePushToken(int tokenId);

  Future<void> deletePushTokenById(int tokenId);

  Future<List<PushTokenModel>> retrievePushTokens();
}

class PushTokenRemoteDataSourceImpl extends PushNotificationRemoteDataSource {
  final DioClient dioClient;

  PushTokenRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<PushTokenModel> registerPushToken(
    PushTokenRequestModel request,
  ) async {
    try {
      _log.info('Registering PushToken for device ${request.deviceId} ...');

      final response = await dioClient.dio.post(
        ApiUrl.authUserPushTokenUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        final pushToken = PushTokenModel.fromJson(response.data);
        _log.info('... PushToken ${pushToken.id} registered for device ${request.deviceId}');
        return pushToken;
      } else {
        throw ServerException(
          message: 'Failed to register push token',
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
  Future<void> deletePushToken(int tokenId) async {
    try {
      _log.info('Deleting PushToken $tokenId ...');

      final response = await dioClient.dio.delete(
        '${ApiUrl.authUserPushTokenUrl}$tokenId/',
      );

      if (response.statusCode == 204) {
        _log.info('... PushToken $tokenId deleted');
      } else {
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
        _log.severe('API Error: $errorMessage');
        throw ServerException(
          message: errorMessage,
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e) {
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
      _log.severe('DioException Error: $errorMessage');
      throw HeliumException(message: errorMessage);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: 'An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> deletePushTokenById(int tokenId) async {
    try {
      _log.info('Deleting PushToken $tokenId ...');
      final response = await dioClient.dio.delete(
        '${ApiUrl.authUserPushTokenUrl}$tokenId/',
      );

      if (response.statusCode == 204) {
        _log.info('... PushToken $tokenId deleted');
      } else {
        final message = response.data is Map<String, dynamic>
            ? (response.data['detail'] ?? 'Failed to delete push token')
            : 'Failed to delete push token';
        throw ServerException(
          message: message,
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
  Future<List<PushTokenModel>> retrievePushTokens() async {
    try {
      _log.info('Fetching PushTokens ...');

      final response = await dioClient.dio.get(ApiUrl.authUserPushTokenUrl);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final tokens =
            data.map((json) => PushTokenModel.fromJson(json)).toList();
        _log.info('... fetched ${tokens.length} PushToken(s)');
        return tokens;
      } else {
        throw ServerException(
          message: 'Failed to retrieve push tokens',
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

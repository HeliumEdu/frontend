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
      _log.info('Registering PushToken ...');

      final response = await dioClient.dio.post(
        ApiUrl.authUserPushTokenUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        final pushToken = PushTokenModel.fromJson(response.data);
        _log.info('... PushToken ${pushToken.id} registered');
        return pushToken;
      } else {
        throw unexpectedStatus(response, 'Failed to register push token.');
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
        throw unexpectedStatus(response, message);
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
        throw unexpectedStatus(response, 'Failed to retrieve push tokens.');
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

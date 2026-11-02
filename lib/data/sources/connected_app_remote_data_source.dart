import 'dart:async';

import 'package:dio/dio.dart';
import 'package:heliumapp/config/analytics_event.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/core/api_url.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/auth/connected_app_model.dart';
import 'package:heliumapp/data/sources/base_data_source.dart';
import 'package:logging/logging.dart';

final _log = Logger('data.sources');

abstract class ConnectedAppRemoteDataSource extends BaseDataSource {
  Future<List<ConnectedAppModel>> getConnectedApps({bool forceRefresh = false});

  Future<void> revokeConnectedApp({required int connectedAppId});
}

class ConnectedAppRemoteDataSourceImpl extends ConnectedAppRemoteDataSource {
  final DioClient dioClient;

  ConnectedAppRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<ConnectedAppModel>> getConnectedApps({
    bool forceRefresh = false,
  }) async {
    try {
      _log.info('Fetching ConnectedApps ...');

      final response = await dioClient.dio.get(
        ApiUrl.authUserConnectedAppsUrl,
        options: forceRefresh ? dioClient.cacheService.forceRefreshOptions() : null,
      );

      if (response.statusCode == 200) {
        final connectedApps = (response.data as List<dynamic>)
            .map((json) => ConnectedAppModel.fromJson(json))
            .toList();

        _log.info('... fetched ${connectedApps.length} ConnectedApp(s)');
        return connectedApps;
      } else {
        throw unexpectedStatus(response, 'Failed to fetch connected apps.');
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
  Future<void> revokeConnectedApp({required int connectedAppId}) async {
    try {
      _log.info('Revoking ConnectedApp $connectedAppId ...');

      final response = await dioClient.dio.delete(
        ApiUrl.authUserConnectedAppDetailUrl(connectedAppId),
      );

      if (response.statusCode == 204) {
        _log.info('... ConnectedApp $connectedAppId revoked');
        unawaited(AnalyticsService().logEvent(name: AnalyticsEvent.connectedAppRevoke, parameters: {'category': AnalyticsCategory.featureInteraction.value}));
        return;
      } else {
        throw unexpectedStatus(response, 'Failed to revoke connected app.');
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

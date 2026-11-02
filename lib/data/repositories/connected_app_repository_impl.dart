import 'package:heliumapp/data/models/auth/connected_app_model.dart';
import 'package:heliumapp/data/sources/connected_app_remote_data_source.dart';
import 'package:heliumapp/domain/repositories/connected_app_repository.dart';

class ConnectedAppRepositoryImpl implements ConnectedAppRepository {
  final ConnectedAppRemoteDataSource remoteDataSource;

  ConnectedAppRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ConnectedAppModel>> getConnectedApps({
    bool forceRefresh = false,
  }) async {
    return remoteDataSource.getConnectedApps(forceRefresh: forceRefresh);
  }

  @override
  Future<void> revokeConnectedApp({required int connectedAppId}) async {
    await remoteDataSource.revokeConnectedApp(connectedAppId: connectedAppId);
  }
}

import 'package:heliumapp/data/models/auth/connected_app_model.dart';

abstract class ConnectedAppRepository {
  Future<List<ConnectedAppModel>> getConnectedApps({bool forceRefresh = false});

  Future<void> revokeConnectedApp({required int connectedAppId});
}

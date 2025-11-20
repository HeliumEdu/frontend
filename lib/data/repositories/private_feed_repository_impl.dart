import 'package:heliumedu/data/datasources/private_feed_remote_data_source.dart';
import 'package:heliumedu/data/models/planner/private_feed_model.dart';
import 'package:heliumedu/domain/repositories/private_feed_repository.dart';

class PrivateFeedRepositoryImpl implements PrivateFeedRepository {
  final PrivateFeedRemoteDataSource remoteDataSource;

  PrivateFeedRepositoryImpl({required this.remoteDataSource});

  @override
  Future<PrivateFeedModel> getPrivateFeedUrls() async {
    return await remoteDataSource.getPrivateFeedUrls();
  }

  @override
  Future<void> enablePrivateFeeds() async {
    return await remoteDataSource.enablePrivateFeeds();
  }

  @override
  Future<void> disablePrivateFeeds() async {
    return await remoteDataSource.disablePrivateFeeds();
  }
}

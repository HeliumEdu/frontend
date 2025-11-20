import 'package:helium_student_flutter/data/datasources/private_feed_remote_data_source.dart';
import 'package:helium_student_flutter/data/models/planner/private_feed_model.dart';
import 'package:helium_student_flutter/domain/repositories/private_feed_repository.dart';

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

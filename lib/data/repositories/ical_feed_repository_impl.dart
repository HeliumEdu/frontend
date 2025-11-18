import 'package:helium_student_flutter/data/datasources/ical_feed_remote_data_source.dart';
import 'package:helium_student_flutter/data/models/planner/ical_feed_model.dart';
import 'package:helium_student_flutter/domain/repositories/ical_feed_repository.dart';

class ICalFeedRepositoryImpl implements ICalFeedRepository {
  final ICalFeedRemoteDataSource remoteDataSource;

  ICalFeedRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ICalFeedModel> getICalFeedUrls() async {
    return await remoteDataSource.getICalFeedUrls();
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

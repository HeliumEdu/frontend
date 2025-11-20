import 'package:heliumedu/data/models/planner/private_feed_model.dart';

abstract class PrivateFeedRepository {
  Future<PrivateFeedModel> getPrivateFeedUrls();
  Future<void> enablePrivateFeeds();
  Future<void> disablePrivateFeeds();
}

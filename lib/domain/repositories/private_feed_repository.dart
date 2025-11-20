import 'package:helium_student_flutter/data/models/planner/private_feed_model.dart';

abstract class PrivateFeedRepository {
  Future<PrivateFeedModel> getPrivateFeedUrls();
  Future<void> enablePrivateFeeds();
  Future<void> disablePrivateFeeds();
}

import 'package:helium_student_flutter/data/models/planner/ical_feed_model.dart';

abstract class ICalFeedRepository {
  Future<ICalFeedModel> getICalFeedUrls();
  Future<void> enablePrivateFeeds();
  Future<void> disablePrivateFeeds();
}

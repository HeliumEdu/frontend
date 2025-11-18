import 'package:helium_student_flutter/data/models/planner/ical_feed_model.dart';

abstract class ICalFeedState {}

class ICalFeedInitial extends ICalFeedState {}

class ICalFeedLoading extends ICalFeedState {}

class ICalFeedLoaded extends ICalFeedState {
  final ICalFeedModel icalFeed;
  ICalFeedLoaded({required this.icalFeed});
}

class ICalFeedError extends ICalFeedState {
  final String message;
  ICalFeedError({required this.message});
}

class ICalFeedEnabling extends ICalFeedState {}

class ICalFeedEnabled extends ICalFeedState {
  final String message;
  ICalFeedEnabled({required this.message});
}

class ICalFeedDisabling extends ICalFeedState {}

class ICalFeedDisabled extends ICalFeedState {
  final String message;
  ICalFeedDisabled({required this.message});
}

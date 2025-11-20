import 'package:heliumedu/data/models/planner/private_feed_model.dart';

abstract class PrivateFeedState {}

class PrivateFeedInitial extends PrivateFeedState {}

class PrivateFeedLoading extends PrivateFeedState {}

class PrivateFeedLoaded extends PrivateFeedState {
  final PrivateFeedModel privateFeed;
  PrivateFeedLoaded({required this.privateFeed});
}

class PrivateFeedError extends PrivateFeedState {
  final String message;
  PrivateFeedError({required this.message});
}

class PrivateFeedEnabling extends PrivateFeedState {}

class PrivateFeedEnabled extends PrivateFeedState {
  final String message;
  PrivateFeedEnabled({required this.message});
}

class PrivateFeedDisabling extends PrivateFeedState {}

class PrivateFeedDisabled extends PrivateFeedState {
  final String message;
  PrivateFeedDisabled({required this.message});
}

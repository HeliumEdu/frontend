// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/private_feed_model.dart';

abstract class PrivateFeedState {}

class PrivateFeedLoading extends PrivateFeedState {}

class PrivateFeedLoaded extends PrivateFeedState {
  final PrivateFeedModel privateFeed;

  PrivateFeedLoaded({required this.privateFeed});
}

class PrivateFeedError extends PrivateFeedState {
  final String message;

  PrivateFeedError({required this.message});
}

class PrivateFeedDisabled extends PrivateFeedState {
  final String message;

  PrivateFeedDisabled({required this.message});
}

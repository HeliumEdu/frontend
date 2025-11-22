// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:helium_mobile/data/models/planner/private_feed_model.dart';

abstract class PrivateFeedRepository {
  Future<PrivateFeedModel> getPrivateFeedUrls();

  Future<void> enablePrivateFeeds();

  Future<void> disablePrivateFeeds();
}

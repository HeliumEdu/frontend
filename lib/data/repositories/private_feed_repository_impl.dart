// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/sources/private_feed_remote_data_source.dart';
import 'package:heliumapp/data/models/planner/private_feed_model.dart';
import 'package:heliumapp/domain/repositories/private_feed_repository.dart';

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

// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:helium_mobile/core/app_exception.dart';
import 'package:helium_mobile/core/dio_client.dart';
import 'package:helium_mobile/core/api_url.dart';
import 'package:helium_mobile/data/models/auth/user_profile_model.dart';
import 'package:helium_mobile/data/models/planner/private_feed_model.dart';
import 'package:logging/logging.dart';

final log = Logger('HeliumLogger');

abstract class PrivateFeedRemoteDataSource {
  Future<PrivateFeedModel> getPrivateFeedUrls();

  Future<void> enablePrivateFeeds();

  Future<void> disablePrivateFeeds();
}

class PrivateFeedRemoteDataSourceImpl implements PrivateFeedRemoteDataSource {
  final DioClient dioClient;

  PrivateFeedRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<PrivateFeedModel> getPrivateFeedUrls() async {
    try {
      log.info(' Fetching Private Feed URLs...');

      log.info(' Fetching user profile to get private slug...');
      final response = await dioClient.dio.get(NetworkUrl.getUserUrl);

      if (response.statusCode != 200) {
        throw ServerException(message: 'Failed to fetch user profile');
      }

      final userProfile = UserProfileModel.fromJson(response.data);

      if (userProfile.settings == null) {
        throw ServerException(
          message: 'User settings not found. Please try logging in again.',
        );
      }

      final privateSlug = userProfile.settings!.privateSlug;

      if (privateSlug.isEmpty) {
        throw ServerException(
          message:
              'Private feed URLs are not enabled. Please enable them in settings on the website.',
        );
      }

      log.info(' Private slug retrieved: $privateSlug');

      final privateFeed = PrivateFeedModel.fromPrivateSlug(
        baseUrl: NetworkUrl.baseUrl,
        privateSlug: privateSlug,
      );

      log.info(' Private Feed URLs generated successfully');
      log.info('   - All Calendar: ${privateFeed.classSchedulesUrl}');
      log.info('   - Homework: ${privateFeed.homeworkUrl}');
      log.info('   - Events: ${privateFeed.eventsUrl}');

      return privateFeed;
    } catch (e) {
      log.info(' Exception in getPrivateFeedUrls: $e');
      if (e is HeliumException) {
        rethrow;
      }
      throw ServerException(
        message: 'Failed to generate Private Feed URLs: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> enablePrivateFeeds() async {
    try {
      log.info('🔧 Enabling private feeds...');

      final response = await dioClient.dio.put(
        NetworkUrl.enablePrivateFeedsUrl,
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: 'Failed to enable private feeds. Please try again.',
        );
      }

      log.info('✅ Private feeds enabled successfully');
    } catch (e) {
      log.info('❌ Exception in enablePrivateFeeds: $e');
      if (e is HeliumException) {
        rethrow;
      }
      throw ServerException(
        message: 'Failed to enable private feeds: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> disablePrivateFeeds() async {
    try {
      log.info('🛑 Disabling private feeds...');

      final response = await dioClient.dio.put(
        NetworkUrl.disablePrivateFeedsUrl,
      );

      if (response.statusCode != 204) {
        throw ServerException(
          message: 'Failed to disable private feeds. Please try again.',
        );
      }

      log.info('✅ Private feeds disabled successfully');
    } catch (e) {
      log.info('❌ Exception in disablePrivateFeeds: $e');
      if (e is HeliumException) {
        rethrow;
      }
      throw ServerException(
        message: 'Failed to disable private feeds: ${e.toString()}',
      );
    }
  }
}

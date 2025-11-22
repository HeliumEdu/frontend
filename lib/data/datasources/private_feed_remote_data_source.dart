// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:helium_mobile/core/app_exception.dart';
import 'package:helium_mobile/core/dio_client.dart';
import 'package:helium_mobile/core/network_urls.dart';
import 'package:helium_mobile/data/models/auth/user_profile_model.dart';
import 'package:helium_mobile/data/models/planner/private_feed_model.dart';

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
      print(' Fetching Private Feed URLs...');

      print(' Fetching user profile to get private slug...');
      final response = await dioClient.dio.get(NetworkUrl.getProfileUrl);

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

      print(' Private slug retrieved: $privateSlug');

      final privateFeed = PrivateFeedModel.fromPrivateSlug(
        baseUrl: NetworkUrl.baseUrl,
        privateSlug: privateSlug,
      );

      print(' Private Feed URLs generated successfully');
      print('   - All Calendar: ${privateFeed.classSchedulesUrl}');
      print('   - Homework: ${privateFeed.homeworkUrl}');
      print('   - Events: ${privateFeed.eventsUrl}');

      return privateFeed;
    } catch (e) {
      print(' Exception in getPrivateFeedUrls: $e');
      if (e is AppException) {
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
      print('🔧 Enabling private feeds...');

      final response = await dioClient.dio.put(
        NetworkUrl.enablePrivateFeedsUrl,
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: 'Failed to enable private feeds. Please try again.',
        );
      }

      print('✅ Private feeds enabled successfully');
    } catch (e) {
      print('❌ Exception in enablePrivateFeeds: $e');
      if (e is AppException) {
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
      print('🛑 Disabling private feeds...');

      final response = await dioClient.dio.put(
        NetworkUrl.disablePrivateFeedsUrl,
      );

      if (response.statusCode != 204) {
        throw ServerException(
          message: 'Failed to disable private feeds. Please try again.',
        );
      }

      print('✅ Private feeds disabled successfully');
    } catch (e) {
      print('❌ Exception in disablePrivateFeeds: $e');
      if (e is AppException) {
        rethrow;
      }
      throw ServerException(
        message: 'Failed to disable private feeds: ${e.toString()}',
      );
    }
  }
}

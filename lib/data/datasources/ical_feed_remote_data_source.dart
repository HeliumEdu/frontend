import 'package:helium_student_flutter/core/app_exception.dart';
import 'package:helium_student_flutter/core/dio_client.dart';
import 'package:helium_student_flutter/core/network_urls.dart';
import 'package:helium_student_flutter/data/models/auth/user_profile_model.dart';
import 'package:helium_student_flutter/data/models/planner/ical_feed_model.dart';

abstract class ICalFeedRemoteDataSource {
  Future<ICalFeedModel> getICalFeedUrls();
  Future<void> enablePrivateFeeds();
  Future<void> disablePrivateFeeds();
}

class ICalFeedRemoteDataSourceImpl implements ICalFeedRemoteDataSource {
  final DioClient dioClient;

  ICalFeedRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<ICalFeedModel> getICalFeedUrls() async {
    try {
      print(' Fetching iCal feed URLs...');

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

      final icalFeed = ICalFeedModel.fromPrivateSlug(
        baseUrl: NetworkUrl.baseUrl,
        privateSlug: privateSlug,
      );

      print(' iCal feed URLs generated successfully');
      print('   - All Calendar: ${icalFeed.allCalendarUrl}');
      print('   - Homework: ${icalFeed.homeworkUrl}');
      print('   - Events: ${icalFeed.eventsUrl}');

      return icalFeed;
    } catch (e) {
      print(' Exception in getICalFeedUrls: $e');
      if (e is AppException) {
        rethrow;
      }
      throw ServerException(
        message: 'Failed to generate iCal feed URLs: ${e.toString()}',
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

      if (response.statusCode != 200) {
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

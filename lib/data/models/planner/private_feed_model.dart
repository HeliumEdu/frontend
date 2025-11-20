// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class PrivateFeedModel {
  final String classSchedulesUrl;
  final String homeworkUrl;
  final String eventsUrl;

  PrivateFeedModel({
    required this.classSchedulesUrl,
    required this.homeworkUrl,
    required this.eventsUrl,
  });

  // Factory to create feed URLs using private slug (these work with Google Calendar!)
  factory PrivateFeedModel.fromPrivateSlug({
    required String baseUrl,
    required String privateSlug,
  }) {
    return PrivateFeedModel(
      classSchedulesUrl:
          '$baseUrl/feed/private/$privateSlug/courseschedules.ics',
      homeworkUrl: '$baseUrl/feed/private/$privateSlug/homework.ics',
      eventsUrl: '$baseUrl/feed/private/$privateSlug/events.ics',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class_schedules_url': classSchedulesUrl,
      'homework_url': homeworkUrl,
      'events_url': eventsUrl,
    };
  }
}

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
      classSchedulesUrl: '$baseUrl/feed/private/$privateSlug/courseschedules.ics',
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

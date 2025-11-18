class ICalFeedModel {
  final String allCalendarUrl;
  final String homeworkUrl;
  final String eventsUrl;

  ICalFeedModel({
    required this.allCalendarUrl,
    required this.homeworkUrl,
    required this.eventsUrl,
  });

  factory ICalFeedModel.fromUrls({
    required String baseUrl,
    required String authToken,
  }) {
    return ICalFeedModel(
      allCalendarUrl:
          '$baseUrl/feed/ical/calendar/?format=ical&auth=$authToken',
      homeworkUrl: '$baseUrl/feed/ical/homework/?format=ical&auth=$authToken',
      eventsUrl: '$baseUrl/feed/ical/events/?format=ical&auth=$authToken',
    );
  }

  // Factory to create feed URLs using private slug (these work with Google Calendar!)
  factory ICalFeedModel.fromPrivateSlug({
    required String baseUrl,
    required String privateSlug,
  }) {
    return ICalFeedModel(
      allCalendarUrl: '$baseUrl/feed/private/$privateSlug/courseschedules.ics',
      homeworkUrl: '$baseUrl/feed/private/$privateSlug/homework.ics',
      eventsUrl: '$baseUrl/feed/private/$privateSlug/events.ics',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'all_calendar_url': allCalendarUrl,
      'homework_url': homeworkUrl,
      'events_url': eventsUrl,
    };
  }
}

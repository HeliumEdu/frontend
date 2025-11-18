class ExternalCalendarRequestModel {
  final String title;
  final String url;
  final String color;
  final bool shownOnCalendar;

  const ExternalCalendarRequestModel({
    required this.title,
    required this.url,
    required this.color,
    required this.shownOnCalendar,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'color': color,
      'shown_on_calendar': shownOnCalendar,
    };
  }
}


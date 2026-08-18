class ExternalCalendarRequestModel {
  final String? title;
  final String? url;
  final String? color;
  final bool? shownOnCalendar;

  const ExternalCalendarRequestModel({
    this.title,
    this.url,
    this.color,
    this.shownOnCalendar,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (title != null) json['title'] = title;
    if (url != null) json['url'] = url;
    if (color != null) json['color'] = color;
    if (shownOnCalendar != null) json['shown_on_calendar'] = shownOnCalendar;

    return json;
  }
}

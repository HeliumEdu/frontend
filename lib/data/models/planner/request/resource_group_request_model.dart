class ResourceGroupRequestModel {
  final String title;
  final bool shownOnCalendar;

  ResourceGroupRequestModel({
    required this.title,
    required this.shownOnCalendar,
  });

  Map<String, dynamic> toJson() {
    return {'title': title, 'shown_on_calendar': shownOnCalendar};
  }
}

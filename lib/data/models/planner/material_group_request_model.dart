class MaterialGroupRequestModel {
  final String title;
  final bool shownOnCalendar;

  MaterialGroupRequestModel({
    required this.title,
    required this.shownOnCalendar,
  });

  Map<String, dynamic> toJson() {
    return {'title': title, 'shown_on_calendar': shownOnCalendar};
  }
}

class MaterialGroupResponseModel {
  final int id;
  final String title;
  final bool shownOnCalendar;
  final int userId;

  MaterialGroupResponseModel({
    required this.id,
    required this.title,
    required this.shownOnCalendar,
    required this.userId,
  });

  factory MaterialGroupResponseModel.fromJson(Map<String, dynamic> json) {
    return MaterialGroupResponseModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      shownOnCalendar: json['shown_on_calendar'] ?? true,
      userId: json['user'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'shown_on_calendar': shownOnCalendar,
      'user': userId,
    };
  }
}

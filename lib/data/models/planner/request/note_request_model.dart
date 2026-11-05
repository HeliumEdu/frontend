class NoteRequestModel {
  final String? title;
  final Map<String, dynamic>? content;
  final int? homeworkId;
  final int? eventId;
  final int? resourceId;
  final int? courseId;
  final bool clearLinks;

  NoteRequestModel({
    this.title,
    this.content,
    this.homeworkId,
    this.eventId,
    this.resourceId,
    this.courseId,
    this.clearLinks = false,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (title != null) json['title'] = title;
    if (content != null) json['content'] = content;
    if (clearLinks ||
        homeworkId != null ||
        eventId != null ||
        resourceId != null ||
        courseId != null) {
      json['homework'] = homeworkId != null ? [homeworkId] : [];
      json['events'] = eventId != null ? [eventId] : [];
      json['resources'] = resourceId != null ? [resourceId] : [];
      json['courses'] = courseId != null ? [courseId] : [];
    }

    return json;
  }
}

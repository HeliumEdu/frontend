class NoteRequestModel {
  final String? title;
  final Map<String, dynamic>? content;
  final int? homeworkId;
  final int? eventId;
  final int? resourceId;
  final bool clearLinks;

  NoteRequestModel({
    this.title,
    this.content,
    this.homeworkId,
    this.eventId,
    this.resourceId,
    this.clearLinks = false,
  });

  /// This device's text, kept when its save loses a conflict. Standalone
  /// because a linked entity can only have one note.
  factory NoteRequestModel.conflictCopy({
    required String title,
    required Map<String, dynamic> content,
  }) {
    final trimmedTitle = title.trim();
    return NoteRequestModel(
      title: trimmedTitle.isEmpty
          ? 'Copy from this device'
          : '$trimmedTitle (copy from this device)',
      content: content,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (title != null) json['title'] = title;
    if (content != null) json['content'] = content;
    if (clearLinks || homeworkId != null || eventId != null || resourceId != null) {
      json['homework'] = homeworkId != null ? [homeworkId] : [];
      json['events'] = eventId != null ? [eventId] : [];
      json['resources'] = resourceId != null ? [resourceId] : [];
    }

    return json;
  }
}
